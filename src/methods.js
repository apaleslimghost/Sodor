/* jshint esnext: true */
var {method} = require('./annotations');
//#### Method decorators
function subMethod(m) {
	return method.extend({
		init() {
			method.prototype.init.call(this,m);
		}
	});
}


exports.get = subMethod('get');
exports.post = subMethod('post');
exports.put = subMethod('put');
exports.delete = subMethod('delete');
exports.patch = subMethod('patch');
exports.options = subMethod('options');
exports.head = subMethod('head');
exports.trace = subMethod('trace');
exports.connect = subMethod('connect');
