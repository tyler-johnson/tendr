_ = require 'underscore'
utils = require './utility'
alib = require './asset'
uuid = require 'node-uuid'

Asset = alib.Asset
AssetReference = alib.AssetReference

# The cache
class SimpleCache
	constructor: (options) -> 
		@options = utils.opts options, {
			unique: false
		}
	
		@cache = {}
	
	set: (key, value) ->
		if @options.unique or !_.has(@cache, key) then @cache[key] = []
		@cache[key].push(value)
	
	get: (key, index) ->
		index ?= 0
		if _.isArray(@cache[key]) then return @cache[key][index]
	
	all: (key) ->
		if _.isArray(@cache[key]) then return @cache[key]
	
	has: (key) ->
		return _.has(@cache, key)
		
	remove: (key, index) ->
		if _.isArray(@cache[key])
			if index? then delete @cache[key][index]
			else delete @cache[key]
	
	find: (value) ->
		k = null
		_.find @cache, (vals, key) ->
			if _.find(vals, (val) ->
				if val is value then return true
			)
				k = key
				return true
		return k
				
assets = new SimpleCache({ unique: true })
md5_cache = new SimpleCache()

class Storage
	constructor: (options) ->
		# Render options
		@options = utils.opts(options)
		
		# base vars
		@name = 'memory'
		@manager = null
	
	insert: (asset, cb) ->
		cb = @default_cb(cb)
		unless asset instanceof Asset then return cb new Error "Expecting an asset."
		
		asset = asset.clone()
		md5 = utils.md5(asset.toBuffer())
		uuid = uuid.v4()
		
		assets.set(uuid, asset)
		md5_cache.set(md5, uuid)
		
		utils.log "Storage `#{@name}` inserted new Asset `#{asset.name}` with ref `#{uuid}`."
		cb(null, uuid)
	
	find: (ref, cb) ->
		cb = @default_cb(cb)
		
		unless assets.has(ref) then cb(null, null)
		else 
			asset = assets.get(ref)
			asset._manager = @manager
			asset._storage = @name
			asset._refs[@name] = ref
			
			cb(null, asset)
	
	update: (ref, asset, cb) ->
		cb = @default_cb(cb)
		unless asset instanceof Asset then return cb new Error "Expecting an asset."
		unless assets.has(ref) then return cb new Error "`#{ref}` couldn't be found."
		
		asset = asset.clone()
		md5 = utils.md5(asset.toBuffer())
		
		# find old md5 and remove it
		k = md5_cache.find(ref)
		i = _.indexOf(md5_cache.all(k), ref)
		if i > -1 then md5_cache.remove(k, i)
		
		assets.set(ref, asset)
		md5_cache.set(md5, ref)
		
		utils.log "Storage `#{@name}` updated Asset `#{asset.name}` with ref `#{uuid}`."
		cb()
	
	remove: (ref, cb) ->
		cb = @default_cb(cb)
		unless assets.has(ref) then return cb new Error "`#{ref}` couldn't be found."
		
		# Remove it
		assets.remove(ref)
		
		# find old md5 and remove it
		k = md5_cache.find(ref)
		i = _.indexOf(md5_cache.all(k), ref)
		if i > -1 then md5_cache.remove(k, i)
		
		utils.log "Storage `#{@name}` removed Asset with ref `#{uuid}`."
		cb()
	
	exists: (ref, cb) ->
		cb(assets.has(ref))
		
	has: (asset, cb) ->
		cb = @default_cb(cb)
		md5 = utils.md5(asset.toBuffer())
		
		if md5_cache.has(md5) then return cb(null, md5_cache.get(md5))
		else return cb(null, null)
	
	default_cb: (cb) ->
		if _.isFunction(cb) then return cb
		else return (err) ->
			if err then throw err

module.exports = Storage