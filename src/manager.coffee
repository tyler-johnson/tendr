_ = require 'underscore'
mime = require 'mime'
utils = require './utility'
alib = require './asset'
Storage = require './storage'
EventEmitter = require('events').EventEmitter

Asset = alib.Asset
AssetReference = alib.AssetReference

# Reset mime's default type
mime.default_type = null

# Manager class
class Manager extends EventEmitter
	constructor: (options) ->
		# Render options
		@options = utils.opts(options, {
			default_store: null
		})
		
		# Base vars
		@types = {}
		@loads = []
		@sorting_facility = {}
		
		utils.log "Asset Manager object initialized."
	
	# Asset types, extensions and classes
	register_type: (type, exts, asset_class) ->
		# Validate args
		unless _.isString(type) then throw new Error("Expecting a string for the first argument.")
		[exts, asset_class] = [null, exts] if _.isFunction(exts) and (new exts) instanceof Asset
		unless _.isFunction(asset_class) and (new asset_class) instanceof Asset then asset_class = Asset
		
		# Check for existing and register
		if _.has(@types, type) then throw new Error("Type `#{type}` has already been registered. Call `unregister_type()` before calling this method to prevent this error.")
		@types[type] = { exts: [], asset: asset_class }
		
		@emit("register_type", type, asset_class)
		utils.log "Asset type `#{type}` registered."
		
		# Register extensions
		@define_exts type, exts
	
	unregister_type: (type) ->
		# Check for existing and delete
		if _.has(@types, type)
			@emit("unregister_type", type)
			delete @types[type]
			utils.log "Asset type `#{type}` removed."
	
	define_exts: (t, exts, override) ->
		type = @_get_type(t)
		
		# do override and get ready
		if override then type.exts = []
		ext_arr = type.exts
		
		# object but not array? run through node-mime
		if _.isObject(exts) and !_.isArray(exts)
			mime.define(exts)
			exts = _.flatten _.values exts
		
		# string? push it and avoid dupos
		if _.isString(exts) and _.indexOf(ext_arr, exts) is -1
			ext_arr.push(exts)
		
		# array? push each and avoid dupos
		else if _.isArray(exts)
			_.each exts, (ext) ->
				if _.isString(ext) and _.indexOf(ext_arr, ext) is -1 then ext_arr.push(ext)
				
		# otherwise gtfo and don't do anything
		else return
		
		@emit("define_exts", t, exts, override)
		utils.log "Extensions `.#{type.exts.join("`, `.")}` now pointing to Asset type `#{t}`."
	
	ext_to_type: (ext) ->
		type = null
		
		# loop through till the type is found
		_.find @types, (obj, t) ->
			if _.indexOf(obj.exts, ext) > -1 then return type = t
		
		return type
	
	extensions: (type) ->
		return @_get_type(type).exts
	
	new_asset: (type, args...) ->
		Asset = @_get_type(type).asset
		
		create = () ->
			F = (args) ->
		        return Asset.apply this, args
		    F.prototype = Asset.prototype
		    return new F arguments
		
		# Load up a fresh asset with built in internals
		asset = create.apply(null, args)
		asset.type = type
		asset._manager = @
		asset._storage = @options.default_store
		
		@emit("new_asset", asset)
		return asset
	
	# Internal function for getting a specific type object
	_get_type: (type) ->
		unless _.has(@types, type) then throw new Error("Type `#{type}` has not been registered.")
		return @types[type]
	
	# Asset load strategy
	register_load: (name, priority, fnc) ->
		# Validate args
		unless _.isString(name) then throw new Error("Expecting a string for the first argument.")
		if _.isFunction(priority) and !fnc then [fnc, priority] = [priority, null]			# (name, fnc)
		unless _.isNumber(priority) then priority = 0
		unless _.isFunction(fnc) then throw new Error("Expecting a function for the last argument.")
		if @_get_load(name, false, true) then throw new Error("Load Strategy `#{name}` has already been registered. Call `unregister_load()` before calling this method to prevent this error.")
		
		# Get sort order
		nl = { name: name, priority: priority, callback: fnc }
		i = _.sortedIndex @loads, nl, (load) ->
			return load.priority
		
		# Splice
		@loads.splice i, 0, nl
		
		@emit("register_load", name, priority, fnc)
		utils.log "Load Strategy `#{name}` registered."
	
	unregister_load: (name) ->
		# Check for existing and delete
		i = @_get_load(name, true, true)
		if i?
			@emit("unregister_load", name)
			@loads.splice(i, 1)
	
	load: (args..., cb) ->
		loads = _.pluck @loads, "callback"
		current = -1
		
		@emit.apply @, _.flatten(["on_load", _.toArray(arguments)])
		
		run_cb = _.once () =>
			try
				@emit.apply @, _.flatten(["loaded", _.toArray(arguments)])
				cb.apply(null, arguments)
			catch e then utils.log("error", e.message)
		
		next = (asset) =>
			if asset instanceof Error then run_cb(asset)
			else if asset instanceof Asset then run_cb(null, asset)
			else
				current++
				args.push(next)
				
				unless _.isFunction(loads[current]) then return run_cb(null, null)
				
				try loads[current].apply this, args
				catch e then next(e)
			
		next()		
	
	exec_load: (name, args..., cb) ->
		unless _.isFunction(cb) then throw new Error("Expecting a function for the last argument.")
		load = @_get_load(name)
		args.push cb
		
		load.callback.apply @, args
	
	# Internal function for getting a specific load object
	_get_load: (name, index, silence) ->
		i = null
		load = _.find @loads, (load, _i) ->
			if load.name is name
				i = _i
				return true
		
		unless load or silence then throw new Error("Load Strategy `#{name}` has not been registered.")
		else if index then return i
		else return load
	
	# Asset Storage Strategy
	register_storage: (name, storage) ->
		# Validate args
		unless _.isString(name) and name then throw new Error "Expecting a string for the first argument."
		if @get_storage(name) then throw new Error("Storage `#{name}` has already been registered. Call `unregister_storage()` before calling this method to prevent this error.")
		unless storage instanceof Storage then storage = new Storage()
		
		# Load and save
		storage.name = name
		storage.manager = @
		@sorting_facility[name] = storage
		
		@emit("register_storage", name, storage)
		utils.log "Storage Engine `#{name}` registered."
		
		# Set the default if it hasn't been yet
		unless @options.default_store then @use_storage(name)
		
	
	use_storage: (name) ->
		unless @get_storage(name) then throw new Error("Storage `#{name}` has not been registered.")
		@options.default_store = name
		utils.log "Default Storage Engine set to `#{name}`."
	
	get_storage: (name) ->
		unless _.isString(name) then name = @options.default_store
		unless name then return null
		
		return @sorting_facility[name] ? null
	
	unregister_storage: (name) ->
		if @get_storage(name)
			@emit("unregister_storage", name)
			delete @sorting_facility[name]
			utils.log "Storage Engine `#{name}` removed."
	
module.exports = Manager