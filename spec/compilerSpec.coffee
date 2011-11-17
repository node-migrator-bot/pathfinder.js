Pathfinder = require '../lib/pathfinder'

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
  @include 'finder/implementation'
}
'''
    expect(compiler.directives(string)).toEqual [
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
    expect(compiler.requirements(string)).toEqual
      strings:      [ './relative/requirement', 'library-requirement' ]
      expressions:  [ '"expression"+"-"+"requirement"' ]
  
  it 'should compile file with no directives or requirements', ->
    file = new Pathfinder.File("spec/fixtures/app/javascripts/application.js")
    path = file.absolutePath()
    
    compiler.compile file, ->
      expect(compiler.lookup.mapToFiles).toEqual {}
      expect(compiler.lookup.mapFromFiles[path]).toEqual { include : [  ], import : [  ], require : [  ] }
    
    waits 500
  
  it 'should compile file with directives and no requirements', ->
    file = new Pathfinder.File("spec/fixtures/app/javascripts/directives.js")
    path = file.absolutePath()
    
    compiler.compile file, (error, result) ->
      mapToFiles = {}
      mapToFiles["#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_a.js"] =
        include:  ["#{process.cwd()}/spec/fixtures/app/javascripts/directives.js"]
        import:   [] 
        require:  []
      mapToFiles["#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_b.js"] =
        include:  ["#{process.cwd()}/spec/fixtures/app/javascripts/directives.js"]
        import:   [] 
        require:  []
      
      expect(compiler.lookup.mapToFiles).toEqual mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/directives.js"] =
        include:  [
          "#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_a.js",
          "#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_b.js"
        ]
        import:   []
        require:  []
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_a.js"] =
        include:  []
        import:   [] 
        require:  []
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_b.js"] =
        include:  []
        import:   [] 
        require:  []
      
      expect(compiler.lookup.mapFromFiles).toEqual mapFromFiles

    waits 500
   
  it 'should compile file with relative requirements and no directives', ->
    file = new Pathfinder.File("spec/fixtures/app/javascripts/requirements.js")
    path = file.absolutePath()

    compiler.compile file, (result) ->
      mapToFiles = {}
      mapToFiles["#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildA.js"] =
        include:  []
        import:   [] 
        require:  ["#{process.cwd()}/spec/fixtures/app/javascripts/requirements.js"]
      mapToFiles["#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildB.js"] =
        include:  []
        import:   [] 
        require:  ["#{process.cwd()}/spec/fixtures/app/javascripts/requirements.js"]
      
      expect(compiler.lookup.mapToFiles).toEqual mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/requirements.js"] =
        include:  []
        import:   []
        require:  [
          "#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildA.js",
          "#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildB.js"
        ]
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildA.js"] =
        include:  []
        import:   [] 
        require:  []
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildB.js"] =
        include:  []
        import:   [] 
        require:  []
      
      expect(compiler.lookup.mapFromFiles).toEqual mapFromFiles
      
    waits 500
   
  it 'should compile file with library requirements', ->
    file = new Pathfinder.File("spec/fixtures/app/javascripts/vendor.js")
    path = file.absolutePath()

    compiler.compile file, (result) ->
      mapToFiles = {}
      mapToFiles["underscore"] = 
        include:  []
        import:   [] 
        require:  ["#{process.cwd()}/spec/fixtures/app/javascripts/vendor.js"]
        
      expect(compiler.lookup.mapToFiles).toEqual mapToFiles
      
      mapFromFiles = {}
      mapFromFiles["#{process.cwd()}/spec/fixtures/app/javascripts/vendor.js"] =
        include:  []
        import:   []
        require:  ["underscore"]
        
      expect(compiler.lookup.mapFromFiles).toEqual mapFromFiles
      
      expect(compiler.lookup.requirements).toEqual [ 'underscore' ]
      
    waits 500
    
  it 'should compile javascript', ->  
    path    = "spec/fixtures/app/javascripts/directives.js"
    file    = new Pathfinder.File(path)
    result  = compiler.compile file
    
    expect(result).toEqual '''
console.log("child a");
console.log("child b");

console.log("directives");

  '''
    
    waits 500
  
  it 'should compile coffeescript', ->
    path    = "spec/fixtures/app/javascripts/application.coffee"
    file    = new Pathfinder.File(path)
    result  = compiler.compile file
    
    expect(result).toEqual '''

require('underscore.string');

$(document).ready(function() {
  return console.log("ready!");
});

'''
    
    waits 500
    
  it 'should throw helpful errors', ->
    path = "spec/fixtures/errors/javascripts/error.coffee"
    file = new Pathfinder.File(path)
    
    expect(-> compiler.compile(file)).toThrow('missing ", starting on line 2, spec/fixtures/errors/javascripts/error.coffee')
    
  it 'should compile in on frame, not async', ->
    path = "spec/fixtures/app/javascripts/application.coffee"
    file = new Pathfinder.File(path)
    
    result = compiler.compile file
    
    expect(result).toEqual '''

require('underscore.string');

$(document).ready(function() {
  return console.log("ready!");
});

'''

  it 'should add a global extension to `require`', ->
    require("./fixtures/app/javascripts/directives.js")
    
  it 'should list dependencies', ->
    compiler.compile "spec/fixtures/app/javascripts/directives.js"
    
    result  = compiler.lookup.dependsOn("#{process.cwd()}/spec/fixtures/app/javascripts/directive_child_a.js")
    
    expect(result).toEqual ['/Users/viatropos/Documents/git/personal/plugins/pathfinder.js/spec/fixtures/app/javascripts/directives.js']
    
    file    = new Pathfinder.File("spec/fixtures/app/javascripts/directives.js")
    
    file.touch()
    before  = file.mtime()
    
    waits 100
    
    file.touch()
    after   = file.mtime()
    
    expect(before.getTime() < after.getTime()).toBeTruthy()