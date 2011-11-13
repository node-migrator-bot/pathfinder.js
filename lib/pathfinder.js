(function() {
  var Pathfinder;

  Pathfinder = (function() {

    Pathfinder.Compiler = require('./pathfinder/compiler');

    Pathfinder.File = require('./pathfinder/file');

    Pathfinder.Lookup = require('./pathfinder/lookup');

    function Pathfinder(root) {
      if (root == null) root = process.cwd();
      this.root = root;
      this.lookup = new Pathfinder.Lookup({
        root: root
      });
      this.compiler = new Pathfinder.Compiler(this.lookup);
    }

    Pathfinder.prototype.compile = function() {
      var _ref;
      return (_ref = this.compiler).compile.apply(_ref, arguments);
    };

    Pathfinder.prototype.write = function() {
      var _ref;
      return (_ref = this.compiler).write.apply(_ref, arguments);
    };

    Pathfinder.prototype.requirements = function() {
      return this.lookup.requirements;
    };

    Pathfinder.prototype.find = function(source, relativeRoot) {
      return this.lookup.find(source, relativeRoot);
    };

    return Pathfinder;

  })();

  module.exports = Pathfinder;

}).call(this);
