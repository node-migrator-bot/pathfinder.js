(function() {
  var require;

  require = function(p) {
    var mod, path;
    path = require.resolve(p);
    mod = require.modules[path];
    if (!mod) throw new Error("failed to require \"" + p + "\"");
    if (!mod.exports) {
      mod.exports = {};
      mod.call(mod.exports, mod, mod.exports, require.relative(path));
    }
    return mod.exports;
  };

  require.modules = {};

  require.resolve = function(path) {
    var index, orig, reg;
    orig = path;
    reg = path + ".js";
    index = path + "/index.js";
    return require.modules[reg] && reg || require.modules[index] && index || orig;
  };

  require.register = function(path, fn) {
    return require.modules[path] = fn;
  };

  require.relative = function(parent) {
    return function(p) {
      var i, path, seg, segs;
      if ("." !== p[0]) return require(p);
      path = parent.split("/");
      segs = p.split("/");
      path.pop();
      i = 0;
      while (i < segs.length) {
        seg = segs[i];
        if (".." === seg) {
          path.pop();
        } else {
          if ("." !== seg) path.push(seg);
        }
        i++;
      }
      return require(path.join("/"));
    };
  };

}).call(this);
