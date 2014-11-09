/* jshint esnext:true */
// Sodor
// =====
var getParameterNames = require('get-parameter-names');
var respond = require('livewire/lib/respond');
var {flatMap, guard, arrayIf, id, join, props, assignAll} = require('./prelude');
var annotations = require('./annotations');
var methods = require('./methods');
var {default: Path} = require('./path');
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
// Add methods to the controller class
Object.assign(Controller, {
	//#### `routes :: [Request → Maybe Promise Response]`
	// Collect the actions together into an array of routes
	routes() {
		return flatMap(this.actionNames(), (action) => {
			var params = getParameterNames(this.prototype[action]);
			var handler = this.handle(action, params);

			return flatMap(this.makePaths(action, params), (path) => {
				var method = annotations.method.has(this.prototype[action]);
				return respond(
					method ? method.method : 'get',
					path,
					handler
				);
			});
		});
	},
	//#### `action-names :: [String]`
	// Get a list of the class' method names
	actionNames() {
		var superclass = this.superclass || Object.getPrototypeOf(this);
		return this === Controller? []
		     : superclass.actionNames().concat(props(this.prototype));
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
			arrayIf([new Path(base, action)], !annotations.special.has(method)),
			arrayIf([new Path(base)], (annotations.root.has(method) || annotations.root.has(this) || action === 'index')),
			arrayIf(annotations.alias.has(method) && annotations.alias.has(method).alias.map((p) => Path.parse(p)), annotations.alias.has(method))
		], !annotations.private.has(method))).map((p) => {
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

Object.assign(Controller, annotations);
Object.assign(Controller, methods);