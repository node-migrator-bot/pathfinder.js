# MUST be added after coffeescript
# if require.extensions
#   require.extensions['.coffee'] = (module, filename) ->
#     content = compile fs.readFileSync(filename, 'utf8'), {filename}
#     module._compile content, filename
# else if require.registerExtension
#   require.registerExtension '.coffee', (content) -> compile content

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
    
  write: ->
    @compiler.write(arguments...)
    
  requirements: ->
    @lookup.requirements
    
  find: (source, relativeRoot) ->
    @lookup.find(source, relativeRoot)
  
module.exports = Pathfinder
