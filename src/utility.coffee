_ = require 'underscore'


### opts() ###

# requirements
# logic
module.exports.opts = (options, defaults) ->
	options = {} unless _.isObject options
	defaults = {} unless _.isObject defaults
	
	return _.extend({}, defaults, options)


### log() ###

# requirements
nconf = require 'nconf'
caterpillar = require 'caterpillar'
color = caterpillar.cliColor
logger = new caterpillar.Logger()
logger.setLevel(6)
# logic	
module.exports.log = (lvl, msg) ->
	[lvl, msg] = ["info", lvl] if typeof msg is 'undefined'
	
	# parse for `text` to highlight
	msg = _.chain(msg.split("\\`")).map((part) ->
		part.replace /`(.*?)`/gi, ($..., o, s) ->
			color.bgYellowBright($[1])
	).value().join('`')
	
	# get date
	d = new Date()
	months = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]
	min = (if d.getMinutes() < 10 then "0" else "") + d.getMinutes()
	sec = (if d.getSeconds() < 10 then "0" else "") + d.getSeconds()
	date = "#{d.getDate()} #{months[d.getMonth()]} #{d.getHours()}:#{min}:#{sec}"
		
	if nconf.get("debug") then logger.log(lvl, "#{color.magenta(date)} #{color.blue('[tendr]')} #{msg}")


### md5() ###

# requirements
crypto = require 'crypto'
# logic	
module.exports.md5 = (data) ->
	return crypto.createHash('md5').update(data).digest('hex')