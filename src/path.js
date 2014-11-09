/* jshint esnext: true */
var path = require('path');
// `Path`
// ---
//
// Utility class for constructing and parsing paths, so as we don't accidentally munge arrays together.
export default class Path {
//#### `constructor`
	constructor(...parts) {
		this.parts = parts;
	}
//#### `#to-string :: → String`
	toString() {
		return path.normalize('/' + this.parts.join('/'));
	}
//#### `#concat :: (Path | Array String) → Path
	concat(o) {
		var parts = this.parts.concat(o.parts || o);
		return new Path(...parts);
	}
}
//#### `parse :: String → Path`
Path.parse = function(path) {
	var parts = path.split('/');
	return new Path(...parts);
};