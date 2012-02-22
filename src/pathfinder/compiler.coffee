async     = require 'async'
detective = require 'detective'
File      = require './file'
Lookup    = require './lookup'
Shift     = require 'shift'

class Compiler
  @body: (body, filename) ->
    """
require.define({"#{filename}": function (require, module, exports, __dirname, __filename) {
  #{body}
}});
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
  @DIRECTIVE_PATTERN: /(\ *)(?:\/\/|#) @(include|import) *['"]([^'"]+)['"][\ ]*?\n?/g
  
  requirements: (string) ->
    detective.find(string)
  
  directives: (string, callback) ->
    result = []
    string.replace @constructor.DIRECTIVE_PATTERN, (_, tabs, directive, source) ->
      result.push type: directive, source: source
      _
    result
  
  wrap: (body, file) ->
    path = file.relativePath()
    
    @constructor.body(body, path)
    
  compile: ->
    {file, options, callback} = @_args(arguments...)
    self        = @
    lookup      = @lookup
    pattern     = @constructor.DIRECTIVE_PATTERN
    wrap        = options.wrap == true
    recursive   = if options.hasOwnProperty("recursive") then options.recursive else true
    _require    = if options.hasOwnProperty("require") then options.require else false
    preprocess  = options.preprocess
    postprocess = options.postprocess
    iterator    = options.iterator
    terminator  = "\n"
    result      = null
    template    = options.template != false
    renderOptions = options.renderOptions || {}      
    
    try
      string        = file.read()
      string        = preprocess.call(self, file, string) if preprocess
      absolutePath  = file.absolutePath()
      relativeRoot  = File.absolutePath(file.dirname())
      directives    = self.directives(string)
      
      lookup.addPath(absolutePath)
    
      iterateDirectives  = (directive, nextDirective) ->
        nestedFile = lookup.find(directive.source, relativeRoot)
        
        unless nestedFile
          return callback.call(self, new Error("Cannot find #{directive.type} ed file: ##{directive.source} in #{file.path}"), string, file)
        
        lookup.addDependency(absolutePath, nestedFile.absolutePath(), directive.type)
        
        options.template = directive.type == "include"
        
        self.compile nestedFile, options, (error, nestedString) ->
          return callback.call(self, error, null, file) if error
          directive.content = nestedString
          iterator.call(self, nestedString, nestedFile) if iterator
          nextDirective()
          
        options.template = template
      
      async.forEachSeries directives, iterateDirectives, ->
        string = string.replace pattern, (_, tabs, directive, source) ->
          lines       = directives.shift().content.split("\n")
          for line, i in lines
            lines[i]  = tabs + line
          lines.join("\n") + terminator
        
        process = (output) ->
          string        = output
          string        = postprocess.call(self, string, file) if postprocess
          if _require && template
            requirements  = self.requirements(string).strings
          else
            requirements  = []
          
          iterateRequirements = (requirement, nextRequirement) ->
            if requirement.match(/^(\.+\/)/) # "./" or "../"
              nestedFile = lookup.find(requirement, relativeRoot)
              
              lookup.addDependency(absolutePath, nestedFile.absolutePath(), 'require')
              
              self.compile nestedFile, options, (error, nestedString) ->
                iterator.call(self, nestedString, nestedFile) if iterator
                nextRequirement()
            else
              lookup.addDependency(absolutePath, requirement, 'require')
              nextRequirement()
          
          async.forEachSeries requirements, iterateRequirements, ->
            string  = self.wrap(string, file) if wrap
            result  = string
            callback.call(self, null, string, file) if callback
        
        if template
          _renderOptions = {path: file.path, string: string}
          for key, value of renderOptions
            _renderOptions[key] = value
          Shift.render _renderOptions, (error, output) ->
            return callback.call(self, error, null, file) if error
            process(output)
        else
          process(string)
            
    catch error
      if callback
        callback.call(self, error, null, file)
      else
        throw error
      
    result
      
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
    
    file = args.shift()
    file = new File(file) if typeof file == "string"
    
    file: file, options: options, callback: callback
    
  _extend: (to, from) ->
    for key, value of from
      to[key] = value
    to

module.exports = Compiler
