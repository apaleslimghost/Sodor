var boulevard = require('boulevard');
var {Param, Branch} = require('param-trie').ParamBranch;
var getParamNames = require('get-parameter-names');

var generatorMap = new WeakMap();

function defaultRoute(routes, base, action) {
	routes.set('default', [Param(base), Param(action)]);
}

var props = (obj) => Object.getOwnPropertyNames(obj).filter(name => name !== 'constructor');
var flatMap = (xs, f) => xs.reduce((ys, x) => ys.concat(f(x)), []);

class Controller {
	static routes() {
		return boulevard(flatMap(this.actionNames(), action => {
			return this.makePaths(action).map(path => {
				return [path, this.handle(action)];
			});
		}));
	}

	static actionNames() {
		var superclass = this.superclass || Object.getPrototypeOf(this);
		return this === Controller? []
		     : superclass.actionNames().concat(props(this.prototype));
	}

	static basePath() {
		return this.base || this.name.toLowerCase();
	}

	static makePaths(action) {
		var method = this.prototype[action];
		var base = this.basePath();

		return [...[defaultRoute]
			.concat(this.generators(method, action))
			.reduce(
				(routes, generator) => generator(routes, base, action) || routes,
				new Map()
			).values()
		];
	}

	static generators(method, action) {
		return generatorMap.get(method) || [];
	}

	static handle(action, params) {
		return (req) => {
			console.log(req);
			var values;
		};
	}
}

module.exports = Controller;
