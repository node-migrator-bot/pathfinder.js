Pathfinder = require '../lib/pathfinder'
assert = require("chai").assert

describe 'compiler', ->
  compiler = null
  
  beforeEach ->
    compiler   = new Pathfinder.Compiler
    
  it 'should extract directives', ->
    string = '''
// @import 'an/import'
// @include 'some/include'

var klass = "CompilerSpec";

var find = function() {
  // @include 'finder/implementation'
}
'''
    assert.deepEqual compiler.directives(string), [
      { type : 'import',   source : 'an/import' }, 
      { type : 'include',  source : 'some/include' }, 
      { type : 'include',  source : 'finder/implementation' }
    ]
    
  it 'should extract requirements', ->
    string = '''
// @import 'an/import'
// @include 'some/include'

var klass = "CompilerSpec";

var relativeRequirement = require('./relative/requirement');
var libraryRequirement = require('library-requirement');
var expressionRequirement = require('expression' + '-' + 'requirement');
'''
    assert.deepEqual compiler.requirements(string),
      strings:      [ './relative/requirement', 'library-requirement' ]
      expressions:  [ '"expression"+"-"+"requirement"' ]
  
  it 'should compile file with no directives or requirements', (done) ->
    file = new Pathfinder.File("test/fixtures/app/javascripts/application.js")
    path = file.absolutePath()
    
    compiler.compile file, ->
      assert.deepEqual compiler.lookup.mapToFiles, {}
      assert.deepEqual compiler.lookup.mapFromFiles[path], { include : [] }
      done()
  
  it 'should compile file with directives and no requirements', (done) ->
    file = new Pathfinder.File("test/fixtures/app/javascripts/directives.js")
    path = file.absolutePath()
    
    compiler.compile file, (error, result) ->
      mapToFiles = {}
      mapToFiles["#{process.cwd()}/test/fixtures/app/javascripts/directive_child_a.js"] =
        include:  ["#{process.cwd()}/test/fixtures/app/javascripts/directives.js"]
      mapToFiles["#{process.cwd()}/test/fixtures/app/javascripts/directive_child_b.js"] =
        include:  ["#{process.cwd()}/test/fixtures/app/javascripts/directives.js"]
      
      assert.deepEqual compiler.lookup.mapToFiles, mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/directives.js"] =
        include:  [
          "#{process.cwd()}/test/fixtures/app/javascripts/directive_child_a.js",
          "#{process.cwd()}/test/fixtures/app/javascripts/directive_child_b.js"
        ]
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/directive_child_a.js"] =
        include:  []
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/directive_child_b.js"] =
        include:  []
      
      assert.deepEqual compiler.lookup.mapFromFiles, mapFromFiles
      
      done()
   
  it 'should compile file with relative requirements and no directives', (done) ->
    file = new Pathfinder.File("test/fixtures/app/javascripts/requirements.js")
    path = file.absolutePath()

    compiler.compile file, (result) ->
      mapToFiles = {}
      mapToFiles["#{process.cwd()}/test/fixtures/app/javascripts/requirementChildA.js"] =
        require:  ["#{process.cwd()}/test/fixtures/app/javascripts/requirements.js"]
      mapToFiles["#{process.cwd()}/test/fixtures/app/javascripts/requirementChildB.js"] =
        require:  ["#{process.cwd()}/test/fixtures/app/javascripts/requirements.js"]
      
      assert.deepEqual compiler.lookup.mapToFiles, mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/requirements.js"] =
        require:  [
          "#{process.cwd()}/test/fixtures/app/javascripts/requirementChildA.js",
          "#{process.cwd()}/test/fixtures/app/javascripts/requirementChildB.js"
        ]
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/requirementChildA.js"] =
        include:  []
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/requirementChildB.js"] =
        include:  []
      
      assert.deepEqual compiler.lookup.mapFromFiles, mapFromFiles
      
      done()
   
  it 'should compile file with library requirements', (done) ->
    file = new Pathfinder.File("test/fixtures/app/javascripts/vendor.js")
    path = file.absolutePath()

    compiler.compile file, (result) ->
      mapToFiles = {}
      mapToFiles["underscore"] = 
        require:  ["#{process.cwd()}/test/fixtures/app/javascripts/vendor.js"]
        
      assert.deepEqual compiler.lookup.mapToFiles, mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/test/fixtures/app/javascripts/vendor.js"] =
        require:  ["underscore"]
        
      assert.deepEqual compiler.lookup.mapFromFiles, mapFromFiles
      
      assert.deepEqual compiler.lookup.requirements, [ 'underscore' ]
      
      done()
    
  it 'should compile javascript', ->  
    path    = "test/fixtures/app/javascripts/directives.js"
    file    = new Pathfinder.File(path)
    result  = compiler.compile file
    
    assert.equal result, '''
console.log("child a");
console.log("child b");

console.log("directives");

  '''
  
  it 'should compile coffeescript', ->
    path    = "test/fixtures/app/javascripts/application.coffee"
    file    = new Pathfinder.File(path)
    result  = compiler.compile file
    
    assert.equal result, '''

require('underscore.string');

$(document).ready(function() {
  return console.log("ready!");
});

'''
    
  it 'should throw helpful errors', ->
    path = "test/fixtures/errors/javascripts/error.coffee"
    file = new Pathfinder.File(path)
    
    #assert.equal -> compiler.compile(file)).toThrow('missing ", starting on line 2, test/fixtures/errors/javascripts/error.coffee')
    
  it 'should compile in on frame, not async', ->
    path = "test/fixtures/app/javascripts/application.coffee"
    file = new Pathfinder.File(path)
    
    result = compiler.compile file
    
    assert.equal result, '''

require('underscore.string');

$(document).ready(function() {
  return console.log("ready!");
});

'''

  it 'should add a global extension to `require`', ->
    require("./fixtures/app/javascripts/directives.js")
    
  it 'should list dependencies', ->
    compiler.compile "test/fixtures/app/javascripts/directives.js"
    result  = compiler.lookup.dependsOn("#{process.cwd()}/test/fixtures/app/javascripts/directive_child_a.js")
    
    assert.equal result, ['/Users/viatropos/Documents/git/personal/plugins/pathfinder.js/test/fixtures/app/javascripts/directives.js']
  
  it 'should touch file', (done) ->
    file    = new Pathfinder.File("test/fixtures/app/javascripts/directives.js")

    file.touch()
    before  = file.mtime()
    
    finish = ->
      file.touch()
      after   = file.mtime()
      assert.ok before.getTime() < after.getTime()
      
      done()
    
    setTimeout finish, 500