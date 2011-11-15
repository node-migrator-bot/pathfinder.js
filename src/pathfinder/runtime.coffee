require = (file, cwd) ->
  resolved = require.resolve(file, cwd or "/")
  mod = require.modules[resolved]
  throw new Error("Failed to resolve module " + file + ", tried " + resolved)  unless mod
  res = (if mod._cached then mod._cached else mod())
  res

require.paths = []
require.modules = {}
require.extensions = $extensions
require._core =
  assert: true
  events: true
  fs:     true
  path:   true
  vm:     true

require.resolve = (->
  (x, cwd) ->
    loadAsFileSync = (x) ->
      return x  if require.modules[x]
      i = 0

      while i < require.extensions.length
        ext = require.extensions[i]
        return x + ext  if require.modules[x + ext]
        i++
    loadAsDirectorySync = (x) ->
      x = x.replace(/\/+$/, "")
      pkgfile = x + "/package.json"
      if require.modules[pkgfile]
        pkg = require.modules[pkgfile]()
        b = pkg.browserify
        if typeof b is "object" and b.main
          m = loadAsFileSync(path.resolve(x, b.main))
          return m  if m
        else if typeof b is "string"
          m = loadAsFileSync(path.resolve(x, b))
          return m  if m
        else if pkg.main
          m = loadAsFileSync(path.resolve(x, pkg.main))
          return m  if m
      loadAsFileSync x + "/index"
    loadNodeModulesSync = (x, start) ->
      dirs = nodeModulesPathsSync(start)
      i = 0

      while i < dirs.length
        dir = dirs[i]
        m = loadAsFileSync(dir + "/" + x)
        return m  if m
        n = loadAsDirectorySync(dir + "/" + x)
        return n  if n
        i++
      m = loadAsFileSync(x)
      m  if m
    nodeModulesPathsSync = (start) ->
      parts = undefined
      if start is "/"
        parts = [ "" ]
      else
        parts = path.normalize(start).split("/")
      dirs = []
      i = parts.length - 1

      while i >= 0
        continue  if parts[i] is "node_modules"
        dir = parts.slice(0, i + 1).join("/") + "/node_modules"
        dirs.push dir
        i--
      dirs
    cwd = "/"  unless cwd
    return x  if require._core[x]
    path = require.modules.path()
    y = cwd or "."
    if x.match(/^(?:\.\.?\/|\/)/)
      m = loadAsFileSync(path.resolve(y, x)) or loadAsDirectorySync(path.resolve(y, x))
      return m  if m
    n = loadNodeModulesSync(x, y)
    return n  if n
    throw new Error("Cannot find module '" + x + "'")
)()

require.alias = (from, to) ->
  path = require.modules.path()
  res = null
  try
    res = require.resolve(from + "/package.json", "/")
  catch err
    res = require.resolve(from, "/")
  basedir = path.dirname(res)
  keys = Object_keys(require.modules)
  i = 0

  while i < keys.length
    key = keys[i]
    if key.slice(0, basedir.length + 1) is basedir + "/"
      f = key.slice(basedir.length)
      require.modules[to + f] = require.modules[basedir + f]
    else require.modules[to] = require.modules[basedir]  if key is basedir
    i++

require.define = (filename, fn) ->
  dirname = (if require._core[filename] then "" else require.modules.path().dirname(filename))
  require_ = (file) ->
    require file, dirname

  require_.resolve = (name) ->
    require.resolve name, dirname

  require_.modules = require.modules
  require_.define = require.define
  module_ = exports: {}
  require.modules[filename] = ->
    require.modules[filename]._cached = module_.exports
    fn.call module_.exports, require_, module_, module_.exports, dirname, filename
    require.modules[filename]._cached = module_.exports
    module_.exports

Object_keys = Object.keys or (obj) ->
  res = []
  for key of obj
    res.push key
  res