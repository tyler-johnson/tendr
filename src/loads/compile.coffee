mime = require 'mime'
_ = require 'underscore'
path = require 'path'

module.exports = () ->
	return [ "compile", 100, (args..., next) ->
		aobj = args[0]
		
		# Validate or pass
		unless _.isObject(aobj) then return next()
		unless _.isString(aobj.name) and aobj.name and Buffer.isBuffer(aobj.content) then return next()
		
		# Intro stuff we need
		name = aobj.name
		content = aobj.content
		type = if aobj.type then aobj.type else @ext_to_type(path.extname(name).substr(1)) ? "text"
		options = if _.isObject(aobj.options) then aobj.options else {}
		
		# new asset
		asset = @new_asset(type, name, options)
		
		# copy content
		asset.write(content)
		
		# copy additional stuff
		_.defaults(asset, aobj)
		
		# get out
		next(asset)
	]