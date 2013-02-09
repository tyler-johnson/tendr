

class Manager
	constructor: (options) ->
	
	# Asset types, extensions and classes
	register_type: (type, exts, asset_class) ->
	
	unregister_type: (type) ->
	
	define_exts: (type, exts, override) ->
	
	ext_to_type: (ext) ->
	
	mime_to_type: (mime) ->
	
	asset_class: (type) ->
	
	# Asset load strategy
	register_load: (name, fnc) ->
	
	unregister_load: (name) ->
	
	load: () ->
	
	exec_load: (name, args...) ->
	
	# Asset Storage Strategy
	register_storage: (name, storage_class) ->
	use_storage: (name) ->
	unregister_storage: (name) ->
	
	save: (stor, asset) ->
	upsert: (stor, asset) ->
	
	create: (stor, asset) ->
	
	read: (ref) ->
	
	update: (ref, asset) ->
	
	delete: (ref) ->
	
	exists: (stor, asset) ->
	
module.exports = Manager