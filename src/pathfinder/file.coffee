fs      = require('fs')
crypto  = require('crypto')
mime    = require('mime')
_path   = require('path')
util    = require('util')
mkdirp  = require('mkdirp')

class File
  @stat: (path) ->
    fs.statSync(path)
  
  # see http://nodejs.org/docs/v0.3.1/api/crypto.html#crypto
  @digestHash: ->
    crypto.createHash('md5')
    
  @digest: (path, data) ->
    stat = @stat(path)
    return unless stat?
    data ||= @read(path)
    return unless data?
    @digestHash().update(data).digest("hex")
    
  @read: (path) ->
    fs.readFileSync(path, "utf-8")
    
  @readAsync: (path, callback) ->
    fs.readFile(path, "utf-8", callback)
    
  @slug: (path) ->
    @basename(path).replace(new RegExp(@extname(path) + "$"), "")
    
  @contentType: (path) ->
    mime.lookup(path)
    
  @mtime: (path) ->
    @stat(path).mtime
  
  @size: (path) ->
    @stat(path).size
    
  @expandFile: (path) ->
    _path.normalize(path)
    
  @absolutePath: (path, root = @pwd()) ->
    path = root + "/" + path unless path.charAt(0) == "/"
    _path.normalize(path)
    
  @relativePath: (path, root = @pwd()) ->
    path = @join(root, path) if path[0] == "."
    _path.normalize(path.replace(new RegExp("^" + root.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&") + "/"), ""))
    
  @pwd: ->
    process.cwd()
  
  @basename: ->
    _path.basename(arguments...)
    
  @extname: (path) ->
    _path.extname(path)
    
  @exists: (path) ->
    _path.existsSync(path)
  
  @existsAsync: (path, callback) ->
    _path.exists(path, callback)
    
  @extensions: (path) ->
    @basename(path).match(/(\.\w+)/g)
    
  @join: ->
    Array.prototype.slice.call(arguments, 0, arguments.length).join("/").replace(/\/+/, "/")
    
  @isUrl: (path) ->
    !!path.match(/^[-a-z]+:\/\/|^cid:|^\/\//)
    
  @isAbsolute: (path) ->
    path.charAt(0) == "/"
    
  @glob: ->
    paths   = Array.prototype.slice.call(arguments, 0, arguments.length)
    result  = []
    for path in paths
      if @exists(path)
        result = result.concat require('findit').sync(path)
    result
    
  @files: ->
    paths   = @glob(arguments...)
    result  = []
    self    = @
    for path in paths
      result.push(path) if self.isFile(path)
    result
    
  @directories: ->
    paths   = @glob(arguments...)
    result  = []
    self    = @
    for path in paths
      result.push(path) if self.isDirectory(path)
    result
    
  @entries: (path) ->
    fs.readdirSync(path)
    
  @dirname: (path) ->
    _path.dirname(path)
    
  @isDirectory: (path) ->
    @stat(path).isDirectory()
    
  @isFile: (path) ->
    !@isDirectory(path)
    
  @write: (path, data, callback) ->
    dirname = @dirname(path)
    
    mkdirp dirname, 0755, (error) ->
      console.error(error) if error
      fs.writeFileSync(path, data)
      callback() if callback
  
  # http://stackoverflow.com/questions/4568689/how-do-i-move-file-a-to-a-different-partition-in-node-js  
  # https://gist.github.com/992478
  @copy: (from, to) ->
    oldFile = fs.createReadStream(from)
    newFile = fs.createWriteStream(to)
    newFile.once 'open', (data) ->
      util.pump(oldFile, newFile)
  
  @digestFile: (path) ->
    @pathWithFingerprint(path, @digest(path))
    
  @pathFingerprint: (path) ->
    result = @basename(path).match(/-([0-9a-f]{32})\.?/)
    if result? then result[1] else null
    
  @pathWithFingerprint: (path, digest) ->
    if oldDigest = @pathFingerprint(path)
      path.replace(oldDigest, digest)
    else
      path.replace(/\.(\w+)$/, "-#{digest}.\$1")
  
  constructor: (path) ->
    @path           = path
    @previousMtime  = @mtime()
    
  stale: ->
    oldMtime   = @previousMtime
    newMtime   = @mtime()
    result     = oldMtime.getTime() != newMtime.getTime()
    
    # console.log "stale? #{result.toString()}, oldMtime: #{oldMtime}, newMtime: #{newMtime}"
    
    # update
    @previousMtime = newMtime
    
    result
    
  stat: ->
    @constructor.stat(@path)

  # Returns `Content-Type` from path.
  contentType: ->
    @constructor.contentType(@path)

  # Get mtime at the time the `Asset` is built.
  mtime: ->
    @constructor.mtime(@path)

  # Get size at the time the `Asset` is built.
  size: ->
    @constructor.size(@path)

  # Get content digest at the time the `Asset` is built.
  digest: ->
    @constructor.digest(@path)
  
  # Returns `Array` of extension `String`s.
  # 
  #     "foo.js.coffee"
  #     # => [".js", ".coffee"]
  # 
  extensions: ->
    @constructor.extensions(@path)
    
  extension: ->
    @constructor.extname(@path)
    
  read: ->
    @constructor.read(@path)
    
  readAsync: (callback) ->
    @constructor.readAsync(@path, callback)
    
  absolutePath: ->
    @constructor.absolutePath(@path)
    
  relativePath: ->
    @constructor.relativePath(@path)
    
  dirname: ->
    @constructor.dirname(@path)
  
  # Return logical path with digest spliced in.
  # 
  #   "foo/bar-37b51d194a7513e45b56f6524f2d51f2.js"
  # 
  digestFile: ->
    @constructor.digestFile(@path)
  
  # Gets digest fingerprint.
  # 
  #     "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
  #     # => "0aa2105d29558f3eb790d411d7d8fb66"
  # 
  pathFingerprint: ->
    @constructor.pathFingerprint(@path)
  
  # Injects digest fingerprint into path.
  # 
  # ``` coffeescript
  # "foo.js" #=> "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
  # ```
  # 
  pathWithFingerprint: (digest) ->
    @constructor.pathWithFingerprint(@path, digest)

module.exports = File
