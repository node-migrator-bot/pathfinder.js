Pathfinder = require '../lib/pathfinder'
assert = require("chai").assert

describe "path", ->
  beforeEach ->
    @path        = "test/fixtures/app/javascripts/application.js"
    @file        = new Pathfinder.File(@path)
  
  it "should stat file", ->
    assert.ok @file.stat()
  
  it "should digest file names", ->
    assert.equal typeof(@file.digest()), "string"
  
  it "should get the content type", ->
    assert.equal @file.contentType(), "application/javascript"
  
  it "should get the mtime", ->
    assert.ok @file.mtime()
  
  it "should get the file size", ->
    assert.equal @file.size(), 60
    
  it "should find entries in a directory", ->
    assert.equal Pathfinder.File.entries("test/fixtures/app/javascripts")[1], 'application.js'
    
  it "should generate absolute path", ->
    expected = "#{process.cwd()}/test/fixtures/app/javascripts"
    assert.equal Pathfinder.File.absolutePath("test/fixtures/app/javascripts"), expected
    
  it "should generate relative path", ->
    expected = "test/fixtures/app/javascripts"
    assert.equal Pathfinder.File.relativePath("test/fixtures/app/javascripts"), expected
