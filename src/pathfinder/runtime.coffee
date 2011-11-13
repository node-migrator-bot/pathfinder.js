require = (p) ->
  path = require.resolve(p)
  mod = require.modules[path]
  throw new Error("failed to require \"" + p + "\"")  unless mod
  unless mod.exports
    mod.exports = {}
    mod.call mod.exports, mod, mod.exports, require.relative(path)
  mod.exports
  
require.modules = {}

require.resolve = (path) ->
  orig = path
  reg = path + ".js"
  index = path + "/index.js"
  require.modules[reg] and reg or require.modules[index] and index or orig

require.register = (path, fn) ->
  require.modules[path] = fn

require.relative = (parent) ->
  (p) ->
    return require(p)  unless "." is p[0]
    path = parent.split("/")
    segs = p.split("/")
    path.pop()
    i = 0

    while i < segs.length
      seg = segs[i]
      if ".." is seg
        path.pop()
      else path.push seg  unless "." is seg
      i++
    require path.join("/")