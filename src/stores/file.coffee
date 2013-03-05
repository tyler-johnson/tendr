_ = require 'underscore'
utils = require '../utility'
alib = require '../asset'
uuid = require 'node-uuid'
fs = require 'fs'
path = require 'path'
Storage = require '../storage'

Asset = alib.Asset
AssetReference = alib.AssetReference
SimpleCache = utils.SimpleCache

# MD5 cache
md5_cache = new SimpleCache()

class FileStorage extends Storage
	constructor: (options) ->
		# Render options
		@options = utils.opts(options, {
			dest: null,
			use_names: false
		});

		unless fs.existsSync(@options.dest) and fs.statSync(@options.dest).isDirectory()
			throw new Error("Need a save destination for this FileStorage.")
		
		# base vars
		@name = 'filesystem'
		@manager = null
	
	insert: (asset, cb) ->
		uuid = uuid.v4()

		@write_asset uuid, asset, (err) =>
			if err then cb(err)
			else
				utils.log "Storage `#{@name}` inserted new Asset `#{asset.name}` with ref `#{uuid}`."
				cb(null, uuid)
	
	find: (ref, cb) ->
		@file_to_asset ref, (err, asset) =>
			if err then cb(err)
			else
				asset._manager = @manager
				asset._storage = @name
				asset._refs[@name] = ref

				cb(null, asset)
	
	update: (ref, asset, cb) ->
		@exists ref, (exists) =>
			unless exists then return cb new Error "`#{ref}` couldn't be found."
			
			@write_asset ref, asset, (err) =>
				if err then cb(err)
				else
					utils.log "Storage `#{@name}` updated Asset `#{asset.name}` with ref `#{uuid}`."
					cb(null)
	
	remove: (ref, cb) ->
		cb = _.once(@default_cb(cb)) # only call the cb once!
		
		@exists ref, (exists) =>
			unless exists then return cb new Error "`#{ref}` couldn't be found."
		
			# Remove it
			fs.unlink @path_composer(ref), (err) =>
				if err then cb(err)
		
				# remove from md5 cache
				@find_kill_md5(ref)
		
				utils.log "Storage `#{@name}` removed Asset with ref `#{uuid}`."
				cb()
	
	exists: (ref, cb) ->
		cb = @default_cb(cb)
		file = @path_composer(ref)

		fs.exists file, (exists) ->
			unless exists then cb(false)
			else fs.stat file, (err, stats) ->
				cb(stats.isFile())
		
	has: (asset, cb) ->
		cb = @default_cb(cb)
		md5 = asset.toHash("md5", "hex")
		
		if md5_cache.has(md5) then return cb(null, md5_cache.get(md5))
		else return cb(null, null)
	
	path_composer: (p) ->
		return path.resolve(@options.dest, p)

	file_to_asset: (p, cb) ->
		cb = _.once(@default_cb(cb)) # only call the cb once!
		file = @path_composer(p)
		stream = fs.createReadStream(file, { flags: 'r', encoding: "utf8" });
		data = ""
		
		stream.on "data", (d) ->
			data += d

		stream.on "error", (err) ->
			cb(err)

		stream.on "end", () ->
			try
				data = JSON.parse(data)
				asset = new Asset(data.name)

				_.each data, (item, key) ->
					if key is "content" then asset.write(item, "base64")
					else asset[key] = item

				cb(null, asset)
			catch e then cb(e)

	write_asset: (ref, asset, cb) ->
		cb = _.once(@default_cb(cb)) # only call the cb once!
		unless asset instanceof Asset then return cb new Error "Expecting an asset."

		data = asset.toObject()
		md5 = asset.toHash("md5", "hex")
		
		stream = fs.createWriteStream(@path_composer(ref), { flags: 'w' });
		stream.on "error", (err) ->
			cb(err)

		stream.on "close", () =>
			cb(null)

		stream.on "open", () =>
			# Write data
			stream.write JSON.stringify(data), "utf8"
			
			# deal with md5
			@find_kill_md5(ref)
			md5_cache.set(md5, ref)

			stream.end()

	# find old md5 and remove it
	find_kill_md5: (ref) ->
		if k = md5_cache.find(ref)
			i = _.indexOf(md5_cache.all(k), ref)
			if i > -1
				md5_cache.remove(k, i)
				return true
		return false

	default_cb: (cb) ->
		if _.isFunction(cb) then return cb
		else return (err) ->
			if err then throw err

module.exports = FileStorage