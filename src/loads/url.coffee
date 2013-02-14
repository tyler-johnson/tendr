url = require 'url'
request = require 'request'
_ = require 'underscore'
path = require 'path'

module.exports = () ->
	return [ "url", 10, (args..., next) ->
		href = args[0]
		
		# Validate or pass
		unless _.isString(href) or _.isObject(href) then return next()
		if _.isObject(href)
			if !href.url then return next()
			else [fobj, href] = [href, href.url]
		else fobj = { url: href }
		
		# parse and make sure its remote
		up = url.parse href
		unless up.protocol and up.host then return next()
		
		# get it
		request.get { url: up }, (err, res, body) =>
			try
				# Get out if it doesn't exist
				return next() if err or !body
				
				name = fobj.name ? path.basename(up.pathname)
				unless name then return next(new Error("#{href} was loaded successfully but a name couldn't be rendered. Try using an object with a name key."))
				
				# Set some arbitrary items
				_.defaults fobj, {
					name: name,
					content: new Buffer(body)
				}
					
				# Pass directly to compile strategy
				@exec_load "compile", fobj, next
			catch e then next(e)
	]