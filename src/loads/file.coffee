path = require 'path'
fs = require 'fs'
_ = require 'underscore'

module.exports = () ->
	return [ "file", 10, (args..., next) ->
		[file, base] = args
		
		# Validate or pass
		unless _.isString(file) or _.isObject(file) then return next()
		if _.isObject(file)
			if !file.file then return next()
			else [fobj, file] = [file, file.file]
		else fobj = { file: file }
	
		# Default the base
		unless base then base = fobj.base or "" 
		
		# Construct the file path and test it
		full = path.resolve(base, file)
		fs.stat full, (err, stat) =>
			try
				# Get out if it doesn't exist
				return next() if err or !stat or !stat.isFile()
				
				# Set some arbitrary items
				fobj.base = base
				_.defaults fobj, {
					name: path.basename(file)
				}
				
				fs.readFile full, (err, data) =>
					try
						# Get out if err
						return next() if err or !data
						
						# set content to the new buffer
						fobj.content = data
						
						# Pass directly to compile strategy
						@exec_load "compile", fobj, next
					catch e then next(e)
			catch e then next(e)
	]