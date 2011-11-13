Pathfinder = require '../lib/pathfinder'

describe "path", ->
  beforeEach ->
    @path        = "spec/fixtures/app/javascripts/application.js"
    @file        = new Pathfinder.File(@path)
  
  it "should stat file", ->
    expect(@file.stat()).toBeTruthy()
  
  it "should digest file names", ->
    expect(typeof(@file.digest())).toEqual("string")
  
  it "should get the content type", ->
    expect(@file.contentType()).toEqual("application/javascript")
  
  it "should get the mtime", ->
    expect(@file.mtime()).toBeTruthy()
  
  it "should get the file size", ->
    expect(@file.size()).toEqual 54
    
  it "should find entries in a directory", ->
    expect(Pathfinder.File.entries("spec/fixtures/app/javascripts")[1]).toEqual 'application.js'
    
  it "should generate absolute path", ->
    expected = "#{process.cwd()}/spec/fixtures/app/javascripts"
    expect(Pathfinder.File.absolutePath("spec/fixtures/app/javascripts")).toEqual expected
    
  it "should generate relative path", ->
    expected = "spec/fixtures/app/javascripts"
    expect(Pathfinder.File.relativePath("spec/fixtures/app/javascripts")).toEqual expected
