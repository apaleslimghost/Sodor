/* jshint esnext: true */
var Annotation = require('traceur-annotations');
//#### `method :: () → Annotation`
exports.method = Annotation.extend({
	init(method) { this.method = method; }
});
//#### `alias :: Path → Annotation`
exports.alias = Annotation.extend({
	init(...aka) { this.alias = aka; }
});
//#### `root :: () → Annotation`
// Root actions operate on the root of the controller path.
exports.root = Annotation.extend();
//#### `private :: () → Annotation`
// Private actions don't generate any routes, but are available to call by other actions.
exports.private = Annotation.extend();
//#### `special :: Action → Action`
// Special actions don't generate the default `/controller/action` route, but any root or alias routes are still generated.
exports.special = Annotation.extend();

