var _ = require('underscore'),
	nconf = require('nconf'),
	fs = require('fs'),
	path = require('path'),
	utils = require('./lib/utility');
	
// Default nconf
nconf.use('memory');
_.each({
	debug: false
}, function(v, k) {
	nconf.set(k, v);
});

// New stuff!
var Manager = require('./lib/manager'),
	main = new Manager();

/**
 * Load up main
 */

// Find and register Types
var type_folder = path.join(__dirname, "lib/types");
_.each(fs.readdirSync(type_folder), function(file) {
	if (path.extname(file) === ".js") {
		require(path.join(type_folder, file))(main);
	}
});

// Find and register Load functions
var load_folder = path.join(__dirname, "lib/loads");
_.each(fs.readdirSync(load_folder), function(file) {
	if (path.extname(file) === ".js") {
		var res = require(path.join(load_folder, file))();
		if (_.isArray(res)) main.register_load.apply(main, res)
	}
});

// Default storage engine
main.register_storage("memory");

module.exports = function(options) {
	// Set up app-wide options
	if (_.isObject(options))
		_.each(options, function(v, k) { nconf.set(k, v); });
	
	// Return manager object
	return main;
}