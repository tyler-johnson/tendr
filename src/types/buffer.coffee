Asset = require('../asset').Asset
_ = require 'underscore'

class BufferAsset extends Asset
	constructor: () ->
		super
	
	compile: () ->
		@toBuffer()

types = {
	"image": [ "png", "gif", "jpg", "jpeg" ]
}

module.exports = (manager) ->
	_.each types, (exts, type) ->
		manager.register_type(type, exts, BufferAsset)