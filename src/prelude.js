/* jshint esnext: true */
var curry = require('curry');
//### Some functional helpers
//#### `flatMap :: Array a → (a → (Array b | b)) → Array b`
// Yay for Javascript's type system. `.concat` is `Array a → (Array a | a) → Array a`
export var flatMap = curry((xs, f) => xs.reduce(((a, x) => a.concat(f(x))), []));
//#### `guard :: Boolean → Array ()`
export var guard = (cond) => cond ? [null] : [];
//#### `array-if :: Array a → Boolean → Array a`
export var arrayIf = curry((xs, cond) => flatMap(guard(cond), () => xs));
//#### `id :: ∀ a. a → a`
export var id = (a) => a;
//#### `join :: Array Array a → Array a`
export var join = (a) => flatMap(a, id);
//#### `props :: Object → [String]`
export var props = (obj) => [for(name of Object.getOwnPropertyNames(obj)) if(name !== 'constructor') name];
//#### `assignAll :: Object → Object → Object`
export var assignAll = (d,s) => {
	for(var p in s) {
		d[p] = s[p];
	}
	return d;
};