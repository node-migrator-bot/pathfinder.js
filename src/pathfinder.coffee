require('coffee-script')

class Pathfinder
  @Compiler: require './pathfinder/compiler'
  @File:     require './pathfinder/file'
  @Lookup:   require './pathfinder/lookup'
  
  constructor: (root = process.cwd()) ->
    @root       = root
    @lookup     = new Pathfinder.Lookup(root: root)
    @compiler   = new Pathfinder.Compiler(@lookup)
  
  compile: ->
    @compiler.compile(arguments...)
    
  requirements: ->
    @lookup.requirements
    
  directories: ->
    []
    
  dependsOn: (path) ->
    @lookup.dependsOn(path)
    
  find: (source, relativeRoot) ->
    @lookup.find(source, relativeRoot)
    
  paths: ->
  
  bootstrap: ->
    
  @instance: ->
    @_instance ||= new Pathfinder

module.exports = Pathfinder

# MUST be added after coffeescript
#if require.extensions
#  require.extensions['.coffee'] = (module, filename) ->
#    content = Pathfinder.instance().compile(filename, require: false)
#    module._compile content, filename
#  require.extensions['.js'] = (module, filename) ->
#    content = Pathfinder.instance().compile(filename, require: false)
#    module._compile content, filename
#else if require.registerExtension
#  console.log "pathfinder doesn't support this version of node.js, try >= 0.4.0"