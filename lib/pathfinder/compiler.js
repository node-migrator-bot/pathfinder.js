(function() {
  var Compiler, File, Lookup, Shift, async, detective;

  async = require('async');

  detective = require('detective');

  File = require('./file');

  Lookup = require('./lookup');

  Shift = require('shift');

  Compiler = (function() {

    Compiler.body = function(body, filename) {
      return "require.define(" + filename + ", function (require, module, exports, __dirname, __filename) {\n  " + body + "\n});";
    };

    Compiler.package = function(body, filename) {
      return "require.modules[" + filename + "] = function () {\n  return " + body + ";\n};";
    };

    Compiler.entry = function(body, filename) {
      return "require.define(" + filename + ", function (require, module, exports, __dirname, __filename) {\n  " + body + "\n});\nrequire(" + filename + ");";
    };

    Compiler.client = function(body, filename) {
      return "require.define(" + filename + ", function (require, module, exports, __dirname, __filename) {\n  module.exports = (function() {\n    " + body + "\n  }).call(this);\n});";
    };

    function Compiler(lookup) {
      this.lookup = lookup || new Lookup;
    }

    Compiler.DIRECTIVE_PATTERN = /(?:\/\/|#| *)\s*@(include|import)\s*['"]?([^'"]+)['"]?[\s]*?\n?/g;

    Compiler.prototype.requirements = function(string) {
      return detective.find(string);
    };

    Compiler.prototype.directives = function(string, callback) {
      var result;
      result = [];
      string.replace(this.constructor.DIRECTIVE_PATTERN, function(_, directive, source) {
        result.push({
          type: directive,
          source: source
        });
        return _;
      });
      return result;
    };

    Compiler.prototype.wrap = function(body, file) {
      var path;
      path = file.relativePath();
      return this.constructor.body(body, path);
    };

    Compiler.prototype.enginesFor = function(path) {
      var engine, engines, extension, extensions, _i, _len;
      engines = [];
      extensions = path.split(".").slice(1);
      for (_i = 0, _len = extensions.length; _i < _len; _i++) {
        extension = extensions[_i];
        engine = Shift.engine(extension);
        if (engine) engines.push(engine);
      }
      return engines;
    };

    Compiler.prototype.render = function(options, callback) {
      var engines, iterate, path, self, string;
      self = this;
      path = options.path;
      string = options.string || File.read(path);
      engines = options.engines || this.enginesFor(path);
      iterate = function(engine, next) {
        return engine.render(string, function(error, output) {
          string = output;
          if (error) throw new Error(error.toString() + (" (" + path + ")"));
          return next();
        });
      };
      return require('async').forEachSeries(engines, iterate, function() {
        return callback.call(self, string);
      });
    };

    Compiler.prototype.compile = function() {
      var callback, files, iterateFiles, iterator, lookup, options, pattern, postprocess, preprocess, recursive, self, terminator, wrap, _ref;
      _ref = this._args.apply(this, arguments), files = _ref.files, options = _ref.options, callback = _ref.callback;
      self = this;
      lookup = this.lookup;
      pattern = this.constructor.DIRECTIVE_PATTERN;
      wrap = options.wrap === true;
      recursive = options.hasOwnProperty("recursive") ? options.recursive : true;
      preprocess = options.preprocess;
      postprocess = options.postprocess;
      iterator = options.iterator;
      terminator = "\n";
      iterateFiles = function(file, nextFile) {
        var absolutePath, directives, iterateDirectives, relativeRoot, string;
        string = file.read();
        if (preprocess) string = preprocess.call(self, file, string);
        absolutePath = file.absolutePath();
        relativeRoot = File.absolutePath(file.dirname());
        directives = self.directives(string);
        lookup.addPath(absolutePath);
        lookup.files[absolutePath] = file;
        iterateDirectives = function(directive, nextDirective) {
          var nestedFile;
          nestedFile = lookup.find(directive.source, relativeRoot);
          lookup.addDependency(absolutePath, nestedFile.absolutePath(), directive.type);
          options.iterator = function(nestedString, nestedFile) {
            directive.content = nestedString;
            if (iterator) return iterator.call(self, nestedString, nestedFile);
          };
          return self.compile(nestedFile, options, function() {
            return nextDirective();
          });
        };
        return async.forEachSeries(directives, iterateDirectives, function() {
          string = string.replace(pattern, function(_, directive, source) {
            return directives.shift().content + terminator;
          });
          return self.render({
            path: file.path,
            string: string
          }, function(output) {
            var iterateRequirements, requirements;
            string = output;
            if (postprocess) string = postprocess.call(self, string, file);
            requirements = self.requirements(string).strings;
            iterateRequirements = function(requirement, nextRequirement) {
              var nestedFile;
              if (requirement.match(/(^\.+\/)/)) {
                nestedFile = lookup.find(requirement, relativeRoot);
                lookup.addDependency(absolutePath, nestedFile.absolutePath(), 'require');
                options.iterator = function(nestedString, nestedFile) {
                  if (iterator) {
                    return iterator.call(self, nestedString, nestedFile);
                  }
                };
                return self.compile(nestedFile, options, function() {
                  return nextRequirement();
                });
              } else {
                lookup.addDependency(absolutePath, requirement, 'require');
                return nextRequirement();
              }
            };
            return async.forEachSeries(requirements, iterateRequirements, function() {
              if (wrap) string = self.wrap(string, file);
              if (iterator) iterator.call(self, string, file);
              return nextFile();
            });
          });
        });
      };
      return async.forEachSeries(files, iterateFiles, function() {
        if (callback) return callback.call(self);
      });
    };

    Compiler.prototype.write = function() {
      var callback, files, options, outputPath, self, _ref;
      _ref = this._args.apply(this, arguments), files = _ref.files, options = _ref.options, callback = _ref.callback;
      self = this;
      outputPath = options.outputPath;
      if (!outputPath) {
        throw new Error("You must define an 'outputPath(file)' callback");
      }
      options.iterator = function(string, file) {
        return File.write(outputPath.call(self, file), string);
      };
      return this.compile(files, options, function() {
        if (callback) return callback.call(self);
      });
    };

    Compiler.prototype._args = function() {
      var args, callback, file, files, i, last, options, _len;
      args = Array.prototype.slice.call(arguments, 0, arguments.length);
      last = args[args.length - 1];
      if (typeof last === "function") callback = args.pop();
      last = args[args.length - 1];
      if (typeof last === "object" && last.constructor === Object) {
        options = args.pop();
      } else {
        options = {};
      }
      files = options.files || args.shift() || File.files(this.lookup.root);
      if (!(files instanceof Array)) files = [files];
      delete options.files;
      for (i = 0, _len = files.length; i < _len; i++) {
        file = files[i];
        if (typeof file === "string") {
          files[i] = this.lookup[File.absolutePath(file)] || new File(file);
        }
      }
      return {
        files: files,
        options: options,
        callback: callback
      };
    };

    Compiler.prototype._extend = function(to, from) {
      var key, value;
      for (key in from) {
        value = from[key];
        to[key] = value;
      }
      return to;
    };

    return Compiler;

  })();

  module.exports = Compiler;

}).call(this);
