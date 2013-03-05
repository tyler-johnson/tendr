_ = require 'underscore'
utils = require './utility'
path = require 'path'
mime = require 'mime'
Manager = require './manager'
uuid = require 'node-uuid'
crypto = require 'crypto'

class Asset
	constructor: (@name, options) ->
		# Render options
		@options = utils.opts(options)
		
		# Base vars
		@type = "text"
		@content = new Buffer(1)
		@uuid = uuid.v4()
		
		# Manager vars
		@_manager = null
		@_storage = null
		@_refs = {}
		
		# Load the mime just in case
		ext = path.extname(@name)
		@mime = mime.lookup(ext) ? null
		
		utils.log "Asset `#{@name}` created."
	
	write: (content, offset, length, encoding) ->
		if _.isString(offset) and !encoding then [encoding, offset] = [offset, 0]
		
		offset ?= 0
		length ?= if _.isString(content) then Buffer.byteLength(content, encoding) else content.length  
		total = length + offset
		
		# new buffer for writing
		nb = new Buffer(total)
		
		# import old stuff first
		@content.copy(nb)
		
		# import new stuff
		if _.isString(content) then nb.write(content, offset, length, encoding)
		else if Buffer.isBuffer(content) then content.copy(nb, offset, 0, length)
		
		@content = nb
		
		utils.log "#{length} bytes written to Asset `#{@name}`."
		
	append: (content) ->
		@write content, @size()
	
	size: () ->
		return @content.length

	toHash: (hash, encoding) ->
		hash ?= "md5"
		encoding ?= "hex"
		return crypto.createHash(hash).update(@toBuffer()).digest(encoding);
	
	toString: () ->
		@content.toString.apply(@content, arguments)
	
	toBuffer: () ->
		nb = new Buffer(@size())
		@content.copy(nb)
		return nb
	
	compile: () ->
		@toString()
		
	clone: () ->
		utils.log "Cloning Asset `#{@name}`..."
		obj = @toObject("content", "name", "options")
		
		asset = new @constructor(@name, @options)
		asset.write(@content)
		
		_.each obj, (v, k) ->
			asset[k] = v
		
		return asset
	
	toObject: () ->	
		omit = _.flatten(["_manager", "uuid", _.functions(@), _.toArray(arguments)])
		_.chain(@).omit(omit).pairs().map((p) ->
			if Buffer.isBuffer(p[1]) then p[1] = p[1].toString('base64')
			return p
		).object().value()
		
	toReference: () ->
		ref = new AssetReference(@_refs, @_storage)
		ref._manager = @_manager
		if @url then ref.url = @url
		
		return ref
		
	# Methods that need a manager
	has_manager: () ->
		return @_manager ? true : false
	
	use_storage: (stor_name) ->
		unless @has_manager() then throw new Error "No manager is associated with this Asset."
		unless @_manager.get_storage(stor_name) then throw new Error "Storage `#{stor_name}` has not been registered."
		@_storage = stor_name
	
	clear_reference: (stor_name) ->
		unless stor_name? then @_refs = {}
		else if _.has(@_refs, stor_name) then delete @_refs[stor_name]
	
	save: (stor_name, cb) ->
		unless @has_manager() then return cb new Error "No manager is associated with this Asset."
		if _.isFunction(stor_name) then [cb, stor_name] = [stor_name, null]
		
		# Get the storage name
		stor_name ?= @_storage
		unless stor_name then return cb new Error "Storage Engine is not specified."
		storage = @_manager.get_storage(stor_name)
		
		# Determine if this is an insert or update
		ref = @_refs[stor_name] ? null
		
		# Update
		if ref then storage.update ref, @, cb
		
		# Insert
		else storage.insert @, (err, ref) =>
			if err then cb err
			else
				@_refs[stor_name] = ref
				cb null

module.exports.Asset = Asset

class AssetReference
	constructor: (@_refs, @_storage) ->
		@_manager = null
		@uuid = uuid.v4()
		@url = null
		
	has_manager: () ->
		return @_manager ? true : false
	
	toObject: () ->
		return {
			_refs: @_refs,
			_storage: @_storage,
			url: @url
		}
	
	toAsset: (stor_name, cb) ->
		unless @has_manager() then throw new Error "No manager is associated with this AssetReference."
		if _.isFunction(stor_name) then [cb, stor_name] = [stor_name, null]
		
		# Get the storage name
		stor_name ?= @_storage
		unless stor_name then return cb new Error "Storage Engine is not specified."
		storage = @_manager.get_storage(stor_name)
		
		# Get the reference
		ref = @_refs[stor_name] ? null
		unless ref then return cb new Error "No internal reference found for an asset in `#{stor_name}` Storage."
		
		# Find it
		storage.find(ref, cb)
		
		
module.exports.AssetReference = AssetReference