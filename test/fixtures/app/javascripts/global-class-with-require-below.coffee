class GlobalClassWithGlobalRequireBelow
  
module.exports = global.GlobalClassWithGlobalRequireBelow = GlobalClassWithGlobalRequireBelow

require './requirements/require-below'
