_ = require 'underscore'

types = {
	"text": [ "txt", "text" ],
	"css": [ "css" ],
	"javascript": [ "js" ]
}

module.exports = (manager) ->
	_.each types, (exts, type) ->
		manager.register_type(type, exts)