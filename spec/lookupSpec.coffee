Pathfinder = require '../lib/pathfinder'

# describe "lookup", ->
#   beforeEach ->
#     # Pathfinder.Path.glob("spec/fixtures/app/javascripts")
#     @lookup = new Pathfinder.Lookup
#       paths:      ["spec/fixtures/app/javascripts"]
#       extensions: ["js", "coffee"]
#       aliases:
#         js:       ["coffee", "coffeescript"]
#         coffee:   ["coffeescript"]
#     
#   it "should normalize extensions and aliases", ->
#     expect(@lookup.extensions).toEqual ['.js', '.coffee']
#     expect(@lookup.aliases).toEqual
#       ".js":      ['.coffee', '.coffeescript']
#       ".coffee":  [".coffeescript"]
#   
#   it "should build a pattern for a basename", ->
#     pattern = @lookup.buildPattern("application.js")
#     expect(pattern.toString()).toEqual /^application(?:\.js|\.coffee|\.coffeescript).*/.toString()
#     
#     pattern = @lookup.buildPattern("application.coffee")
#     expect(pattern.toString()).toEqual /^application(?:\.coffee|\.coffeescript).*/.toString()
#     
#     pattern = @lookup.buildPattern("application.js.coffee")
#     expect(pattern.toString()).toEqual /^application\.js(?:\.coffee|\.coffeescript).*/.toString()
#     
#   it "should find", ->
#     result = @lookup.find("application.js")
#     expect(result.length).toEqual 3
#     
#     result = @lookup.find("application.coffee")
#     expect(result.length).toEqual 1
