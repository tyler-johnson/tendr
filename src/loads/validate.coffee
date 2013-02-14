_ = require 'underscore'
alib = require '../asset'

Asset = alib.Asset
AssetReference = alib.AssetReference

module.exports = () ->
	return [ "validate", 1, (args..., next) ->
		obj = args[0]
		
		# Validate
		if obj instanceof Asset then return next(obj)
		unless _.isObject(obj) then return next()
		
		# Check if it is's a reference first
		if obj instanceof AssetReference then ref = obj
		
		# Check if it can be a reference
		else if _.isObject(obj._refs)
			storage = obj._storage ? @options.default_store
			
			# New reference
			ref = new AssetReference(obj._refs, storage)
			ref._manager = @
			ref.url = obj.url ? null
		
		# check if it already has content and a name
		else if obj.content and obj.name
			
			# Go straight for compile
			return @exec_load("compile", obj, next)
		
		# If we haven't left yet, we have a reference
		if ref
			# Convert to an asset
			ref.toAsset (err, asset) ->
				if err then next(err)
				else if !asset then next new Error "Load assumed reference and an Asset could not be found."
				else next(asset)
		
	]