/* jshint esnext:true */
// Sodor
// =====
//### Import our dependencies
var getParameterNames = require('get-parameter-names');
var respond = require('livewire/lib/respond');
var path = require('path');
var curry = require('curry');
//var Symbol = require('es6-symbol');
//### Some functional helpers
//#### `flatMap :: Array a → (a → (Array b | b)) → Array b`
// Yay for Javascript's type system. `.concat` is `Array a → (Array a | a) → Array a`
var flatMap = curry((xs, f) => xs.reduce(((a, x) => a.concat(f(x))), []));
//#### `guard :: Boolean → Array ()`
var guard = (cond) => cond ? [null] : [];
//#### `array-if :: Array a → Boolean → Array a`
var arrayIf = curry((xs, cond) => flatMap(guard(cond), () => xs));
//#### `id :: ∀ a. a → a`
var id = (a) => a;
//#### `join :: Array Array a → Array a`
var join = (a) => flatMap(a, id);
//#### `props :: Object → [String]`
var props = (obj) => [for(name of Object.getOwnPropertyNames(obj)) if(name !== 'constructor') name];
//#### `assignAll :: Object → Object → Object`
var assignAll = (d,s) => {
	for(var p in s) {
		d[p] = s[p];
	}
	return d;
};
//### Symbols
// Create some symbols so we don't overwrite things or get things overwritten
export var root    = Symbol('root');
export var alias   = Symbol('alias');
export var method  = Symbol('method');
export var pirate  = Symbol('private');
export var special = Symbol('special');
// `Path`
// ---
//
// Utility class for constructing and parsing paths, so as we don't accidentally munge arrays together.
export class Path {
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
// `Controller`
// ---
//
// The main class we export. Consumers should extend this.
//
export class Controller {
	//#### `constructor`
	// We save the request to the instance (as we see later, it's one instance ⇔ one request).
	constructor(request) { this.request = request; }
}

Object.assign(Controller, {
	//#### `method :: HTTPMethod → Action → Action`
	method: curry((val, action) => Object.assign(action, {[method]: val})),
	//#### `alias :: Path → Action → Action`
	alias(...aka) {
		var action = aka.pop();
		action[alias] = (action[alias] || []).concat(aka);
		return action;
	},
	//#### `root :: Action → Action`
	// Sets `root` to true for the action. Root actions operate on the root of the controller path.
	root(obj = this) {
		return Object.assign(obj, {[root]: true});
	},
	//#### `private :: Action → Action`
	// Sets `private` to true for the action. Private actions don't generate any routes, but are available to call by other actions.
	private(obj = this) {
		return Object.assign(obj, {[pirate]: true});
	},
	//#### `special :: Action → Action`
	// Sets `special` to true for the action. Special actions don't generate the default `/controller/action` route, but any root or alias routes are still generated.
	special(obj = this) {
		return Object.assign(obj, {[special]: true});
	},
	//#### `routes :: [Request → Maybe Promise Response]`
	// Collect the actions together into an array of routes
	routes() {
		return flatMap(this.actionNames(), (action) => {
			var params = getParameterNames(this.prototype[action]);
			var handler = this.handle(action, params);

			return flatMap(this.makePaths(action, params), (path) => {
				return respond(
					this.prototype[action][method] || 'get',
					path,
					handler
				);
			});
		});
	},
	//#### `action-names :: [String]`
	// Get a list of the class' method names
	actionNames() {
		return this === Controller? []
		     : /* otherwise */      this.superclass.actionNames().concat(props(this.prototype));
	},
	//#### `base-path :: → Path`
	// Gets the base path for this controller. If Controller.base is specified, use that, otherwise use the class name in lower case.
	basePath() {
		return this.base || this.name.toLowerCase();
	},
	//#### `make-paths :: String → [String] → Path`
	// Turn an action name and some parameter names into a path, potentially in 3 different ways:
	//   1. /class-name/action-name/params unless the action is `special`
	//   2. /class-name/params if the action has `root` set or is called index
	//   3. /alias/params if the action has an `alias`
	// If the action is `private`, no routes are generated. It can, however, be called internally from other routes.
	makePaths(action, params) {
		var paramsParts = params.map((a) => ':' + a);
		var base = this.basePath();
		var method = this.prototype[action];

		return join(arrayIf([
			arrayIf([new Path(base, action)], !method[special]),
			arrayIf([new Path(base)], (method[root] || this[root] || action === 'index')),
			arrayIf(method[alias] && method[alias].map((p) => Path.parse(p)), method[alias])
		], !method[pirate])).map((p) => {
			return p.concat(paramsParts).toString();
		});
	},
	//#### `handle :: String → [String] → (Request → Promise Response)`
	// Wrap an action in a Livewire-compatible route handler that assigns parameters and instantiates the controller before calling the correct action.
	//
	// If the class has a `context` method, it's called with the action name, and together with the controller itself provides the context for the action.
	handle(action, params) {
		return (req) => {
			var values = [for(k of params) req.params[k]];
			var controller = new this(req);
			var context = this.context? assignAll(this.context(action), controller)
			            : controller;
			return controller[action].apply(context, values);
		};
	}
});

//#### Method decorators
// These are `method` partially applied with the usual HTTP methods
for(var m of ['get', 'post', 'put', 'delete', 'patch', 'options', 'head', 'trace', 'connect']) {
	Controller[m] = Controller.method(m);
}