async     = require 'async'
detective = require 'detective'
File      = require './file'
Lookup    = require './lookup'
Shift     = require 'shift'

class Compiler
  @body: (body, filename) ->
    """
require.define(#{filename}, function (require, module, exports, __dirname, __filename) {
  #{body}
});
    """
  
  @package: (body, filename) ->
    """
require.modules[#{filename}] = function () {
  return #{body};
};
    """
    
  @entry: (body, filename) ->
    """
require.define(#{filename}, function (require, module, exports, __dirname, __filename) {
  #{body}
});
require(#{filename});
    """
    
  @client: (body, filename) ->
    """
require.define(#{filename}, function (require, module, exports, __dirname, __filename) {
  module.exports = (function() {
    #{body}
  }).call(this);
});
    """
    
  constructor: (lookup) ->
    @lookup = lookup || new Lookup
  
  # Directives are denoted by a `@` followed by the name, then
  # argument list.
  # 
  # The `@require` directive copy/pastes the rendered content in there.
  # This makes it so you can include coffeescript and javascript files in the same file.
  # 
  # The `@import` directive copy/pastes the unrendered content in there.
  # The `@import` files must be the same extension of the containing file.
  #
  # A few different styles are allowed:
  #
  #     // @include foo
  #     // @include 'foo'
  #     // @include "foo"
  #     // @import foo
  #     // @import 'foo'
  #     // @import "foo"
  # 
  # Any file that is included can be optionally left in an external file.  Useful for production vs. development renderings.
  #
  @DIRECTIVE_PATTERN: /(?:\/\/|#| *)\s*@(include|import)\s*['"]?([^'"]+)['"]?[\s]*?\n?/g
    
  requirements: (string) ->
    detective.find(string)
  
  directives: (string, callback) ->
    result = []
    string.replace @constructor.DIRECTIVE_PATTERN, (_, directive, source) ->
      result.push type: directive, source: source
      _
    result
  
  wrap: (body, file) ->
    path = file.relativePath()
    
    @constructor.body(body, path)
  
  # Pass in path, it computes the extensions and what engine you'll want
  enginesFor: (path) ->
    engines     = []
    extensions  = path.split(".")[1..-1]
    
    for extension in extensions
      engine    = Shift.engine(extension)
      engines.push engine if engine
    
    engines
  
  render: (options, callback) ->
    self        = @
    path        = options.path
    string      = options.string  || File.read(path)
    engines     = options.engines || @enginesFor(path)
    
    iterate = (engine, next) ->
      engine.render string, (error, output) ->
        string = output
        if error
          console.log "lineNumber: #{error.lineNumber}"
          console.log "fileName: #{error.fileName}"
        throw new Error(error.toString() + " (#{path})") if error
        next()
    
    require('async').forEachSeries engines, iterate, ->
      callback.call(self, string)
    
  compile: ->
    {files, options, callback} = @_args(arguments...)
    self        = @
    lookup      = @lookup
    pattern     = @constructor.DIRECTIVE_PATTERN
    wrap        = options.wrap == true
    recursive   = if options.hasOwnProperty("recursive") then options.recursive else true
    preprocess  = options.preprocess
    postprocess = options.postprocess
    iterator    = options.iterator
    terminator  = "\n"
    
    iterateFiles = (file, nextFile) ->
      string        = file.read()
      string        = preprocess.call(self, file, string) if preprocess
      absolutePath  = file.absolutePath()
      relativeRoot  = File.absolutePath(file.dirname())
      directives    = self.directives(string)
      
      lookup.addPath(absolutePath)
      lookup.files[absolutePath] = file
      
      iterateDirectives  = (directive, nextDirective) ->
        nestedFile = lookup.find(directive.source, relativeRoot)
        
        lookup.addDependency(absolutePath, nestedFile.absolutePath(), directive.type)
        
        options.iterator = (nestedString, nestedFile) ->
          directive.content = nestedString
          iterator.call(self, nestedString, nestedFile) if iterator
        
        self.compile nestedFile, options, ->
          nextDirective()
      
      async.forEachSeries directives, iterateDirectives, ->
        string = string.replace pattern, (_, directive, source) ->
          directives.shift().content + terminator
          
        self.render path: file.path, string: string, (output) ->
          string        = output
          string        = postprocess.call(self, string, file) if postprocess
          requirements  = self.requirements(string).strings
          
          iterateRequirements = (requirement, nextRequirement) ->
            if requirement.match(/(^\.+\/)/) # "./" or "../"
              nestedFile = lookup.find(requirement, relativeRoot)
              
              lookup.addDependency(absolutePath, nestedFile.absolutePath(), 'require')
              
              options.iterator = (nestedString, nestedFile) ->
                iterator.call(self, nestedString, nestedFile) if iterator
              
              self.compile nestedFile, options, ->
                nextRequirement()
            else
              lookup.addDependency(absolutePath, requirement, 'require')
              nextRequirement()
          
          async.forEachSeries requirements, iterateRequirements, ->
            string  = self.wrap(string, file) if wrap
            iterator.call(self, string, file) if iterator
            nextFile()
        
    async.forEachSeries files, iterateFiles, ->
      callback.call(self) if callback
      
  write: ->
    {files, options, callback} = @_args(arguments...)
    
    self        = @
    outputPath  = options.outputPath
  
    throw new Error("You must define an 'outputPath(file)' callback") unless outputPath
    
    options.iterator = (string, file) ->
      File.write outputPath.call(self, file), string
    
    @compile files, options, ->
      callback.call(self) if callback
      
  _args: ->
    args      = Array.prototype.slice.call(arguments, 0, arguments.length)
    last      = args[args.length - 1]
    callback  = args.pop() if typeof last == "function"
    #throw new Error("The last argument must be a callback") unless callback && typeof(callback) == "function"
    last = args[args.length - 1]
    if typeof(last) == "object" && last.constructor == Object
      options = args.pop()
    else
      options = {}
    
    files = options.files || args.shift() || File.files(@lookup.root)
    files = [files] unless files instanceof Array
    delete options.files
    
    for file, i in files
      if typeof file == "string"
        files[i] = @lookup[File.absolutePath(file)] || new File(file)
    
    files: files, options: options, callback: callback
    
  _extend: (to, from) ->
    for key, value of from
      to[key] = value
    to

module.exports = Compiler
