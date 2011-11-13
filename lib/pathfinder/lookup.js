(function() {
  var File, Lookup;

  File = require('./file');

  Lookup = (function() {

    function Lookup(options) {
      if (options == null) options = {};
      this.root = options.root || process.cwd();
      this.exclude = options.exclude || [];
      this.mapToFiles = {};
      this.mapFromFiles = {};
      this.requirements = [];
      this.files = {};
    }

    Lookup.prototype.find = function(source, relativeRoot) {
      var basename, directory, path;
      if (relativeRoot == null) relativeRoot = this.root;
      source = File.absolutePath(source, relativeRoot);
      directory = File.dirname(source);
      basename = File.basename(source);
      path = this.matches(directory, basename)[0];
      if (path) {
        return new File(path);
      } else {
        return null;
      }
    };

    Lookup.prototype.matches = function(directory, basename) {
      var entries, entry, i, match, matches, pattern, _i, _len, _len2;
      entries = this.entries(directory);
      pattern = new RegExp("^" + this.escape(basename));
      matches = [];
      for (_i = 0, _len = entries.length; _i < _len; _i++) {
        entry = entries[_i];
        if (File.isFile(File.join(directory, entry)) && !!entry.match(pattern)) {
          matches.push(entry);
        }
      }
      matches = this.sort(matches, basename);
      for (i = 0, _len2 = matches.length; i < _len2; i++) {
        match = matches[i];
        matches[i] = File.join(directory, match);
      }
      return matches;
    };

    Lookup.prototype.sort = function(matches, basename) {
      return matches;
    };

    Lookup.prototype.addPath = function(path) {
      var _base;
      (_base = this.mapFromFiles)[path] || (_base[path] = {
        include: [],
        "import": [],
        require: []
      });
      return this;
    };

    Lookup.prototype.addDependency = function(path, dependency, type) {
      var _base;
      this.addPath(path);
      (_base = this.mapToFiles)[dependency] || (_base[dependency] = {
        include: [],
        "import": [],
        require: []
      });
      if (type === 'require' && this.requirements.indexOf(dependency) === -1) {
        this.requirements.push(dependency);
      }
      if (!(this.mapToFiles[dependency][type].indexOf(path) > -1)) {
        this.mapToFiles[dependency][type].push(path);
      }
      if (!(this.mapFromFiles[path][type].indexOf(dependency) > -1)) {
        this.mapFromFiles[path][type].push(dependency);
      }
      return this;
    };

    Lookup.prototype.escape = function(string) {
      return string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
    };

    Lookup.prototype.entries = function(path) {
      var entries, entry, result, _i, _len;
      result = [];
      if (File.exists(path)) {
        entries = File.entries(path);
      } else {
        entries = [];
      }
      for (_i = 0, _len = entries.length; _i < _len; _i++) {
        entry = entries[_i];
        if (!entry.match(/^\.|~$|^\#.*\#$/)) result.push(entry);
      }
      return result.sort();
    };

    return Lookup;

  })();

  module.exports = Lookup;

}).call(this);