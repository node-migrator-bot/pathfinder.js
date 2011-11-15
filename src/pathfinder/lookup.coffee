File = require('./file')

class Lookup
  constructor: (options = {}) ->
    @root                 = options.root    || process.cwd()
    @exclude              = options.exclude || []
    # if a file changes, plug it in here to get all the files you need to re-render
    @mapToFiles           = {}
    @mapFromFiles         = {}
    @requirements         = []
    
  # find "application", ["./app/assets"]
  # 
  # use this method to find the string for a helper method, not to find the actual file
  find: (source, relativeRoot = @root) ->
    source    = File.absolutePath(source, relativeRoot)
    directory = File.dirname(source)
    basename  = File.basename(source)
    path = @matches(directory, basename)[0]
    if path then new File(path) else null
    
  matches: (directory, basename) ->
    entries = @entries(directory)
    pattern = new RegExp "^" + @escape(basename)#@pattern(basename)
    matches = []
    
    for entry in entries
      if File.isFile(File.join(directory, entry)) && !!entry.match(pattern)
        matches.push(entry)
      
    matches = @sort(matches, basename)
    for match, i in matches
      matches[i] = File.join(directory, match)
    
    matches
    
  sort: (matches, basename) ->
    matches
    
  addPath: (path) ->
    @mapFromFiles[path] ||= 
      include:            []
      import:             []
      require:            []
    @
    
  addDependency: (path, dependency, type) ->
    @addPath(path)
    @mapToFiles[dependency] ||= 
      include:            []
      import:             []
      require:            []
      
    if type == 'require' && @requirements.indexOf(dependency) == -1
      @requirements.push(dependency)
    
    unless @mapToFiles[dependency][type].indexOf(path) > -1
      @mapToFiles[dependency][type].push(path)
      
    unless @mapFromFiles[path][type].indexOf(dependency) > -1
      @mapFromFiles[path][type].push(dependency)
    
    @
    
  # RegExp.escape
  escape: (string) ->
    string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
  
  # A cached version of `Dir.entries` that filters out `.` files and
  # `~` swap files. Returns an empty `Array` if the directory does
  # not exist.
  entries: (path) ->
    result  = []
    
    if File.exists(path)
      entries = File.entries(path)
    else
      entries = []
    
    for entry in entries
      result.push(entry) unless entry.match(/^\.|~$|^\#.*\#$/)
    
    result.sort()
  
module.exports = Lookup
