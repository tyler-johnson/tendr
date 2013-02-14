# Tendr

Tendr is a simple, flexible asset manager for Node.js. Tendr is able to load files from anywhere and can store files anywhere. It works with the file system, urls, and even databases. Tendr is compatible with any file type and supports additional precompilation and compilation (like minification and template rendering). Tendr was built for [Turbo](), our content management platform, but will work in almost any environment.

While Tendr has been seriously bug tested, we consider it to be beta software. This means that there are still probably more bugs and the API *might* change (although not dramatically).

## Usage

Tendr is still in beta and isn't in the npm registry yet. To install, you'll need to get it right from the source.

	npm install <git>

To use Turbo in a Node.js app:
	
	var tendr = require('tendr')();

You can debug Tendr (output everything to the console) with:

	var tendr = require('tendr')({ debug: true });

## Example

Unfortuantely, this doesn't show the true power of Tendr, but just so you can get a feel.

	// Load in an image from somewhere
	tendr.load("image.jpg", __dirname, function(err, asset) {
		if (err) console.error(err);
		
		// Now save it somewhere. Uses the default here which is 'memory'
		asset.save(function(err) {
			if (err) console.error(err);
			
			// asset.toReference() shouldn't be called until after the asset is saved
			var ref = asset.toReference();
			console.log(ref.toObject());
		});
	});

One thing to point out is the difference between an `Asset` and an `AssetReference`. Since assets contain buffers of content, they can consume a lot of memory. To solve this, an `Asset` can be converted to an `AssetReference` which is a "light-weight" way to retrieve an asset after it's been saved. What's more is you can convert it to an simple Object and use it as a quick restart point for your asset.

## Documentation

Documentation is coming soon.

## Who is maintaining this?

This repo is maintained by me (…obviously), Tyler Johnson ([@appleifreak](http://github.com/appleifreak), <tyler@vintyge.com>). I am the lead developer and co-owner of [Vintyge, Inc.](http://vintyge.com), a small creative web firm. If you have any questions, concerns, thoughts, dilemmas or really anything, please contact me: <tyler@vintyge.com>.