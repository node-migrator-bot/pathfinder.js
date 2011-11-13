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
    
    compiler.compile file, (directives, requirements) ->
      expect(compiler.lookup.mapToFiles).toEqual {}
      expect(compiler.lookup.mapFromFiles[path]).toEqual { include : [  ], import : [  ], require : [  ] }
    
    waits 500
  
  it 'should compile file with directives and no requirements', ->
    file = new Pathfinder.File("spec/fixtures/app/javascripts/directives.js")
    path = file.absolutePath()

    compiler.compile file, (result) ->
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
    
  it 'should compile entire directories', ->
    pathfinder = new Pathfinder("#{process.cwd()}/spec/fixtures/app/javascripts")
    
    pathfinder.compile ->
      requirements = [ "underscore.string",
        "#{process.cwd()}/spec/fixtures/app/javascripts/requirements/require-below.coffee",
        "#{process.cwd()}/spec/fixtures/app/javascripts/requirements/require-inline.coffee",
        "#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildA.js",
        "#{process.cwd()}/spec/fixtures/app/javascripts/requirementChildB.js",
        "underscore"
      ]
      
      expect(pathfinder.lookup.requirements).toEqual requirements
      
    waits 500
    
  it 'should compile javascript', ->  
    path = "spec/fixtures/app/javascripts/directives.js"
    file = new Pathfinder.File(path)
    
    compiler.compile file, iterator: (result, file) ->
      if file.relativePath() == path
        expect(result).toEqual '''
alert("child a");
alert("child b");

alert("directives");

  '''
    
    waits 500
  
  it 'should compile coffeescript', ->
    path = "spec/fixtures/app/javascripts/application.coffee"
    file = new Pathfinder.File(path)
    
    compiler.compile file, iterator: (result, file) ->
      if file.relativePath() == path
        expect(result).toEqual '''

require('underscore.string');

$(document).ready(function() {
  return alert("ready!");
});

'''
    
    waits 500
    
  it 'should compile all', ->
    pathfinder = new Pathfinder("#{process.cwd()}/spec/fixtures/app/javascripts")
    
    iterator = (file, result) ->
    
    pathfinder.compile iterator: iterator, wrap: true, ->
    
    waits 500
    
  it 'should write files', ->
    pathfinder = new Pathfinder("#{process.cwd()}/spec/fixtures/app/javascripts")
    
    outputPath = (file) ->
      path = file.relativePath().replace(/^spec/, "spec/tmp")
      path.replace(/(\.(?:js|coffee)+)/g, "") + ".js"
    
    pathfinder.write outputPath: outputPath
      # for requirement in pathfinder.lookup.requirements
      #   pathfinder.compile 
      
    waits 500