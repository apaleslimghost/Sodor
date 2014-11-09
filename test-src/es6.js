/* jshint esnext:true */
var expect = require('karma-sinon-expect').expect;
var rewire = require('rewire');
var sodor = rewire('../lib/index.js');
var {Controller} = sodor;
var {root, alias} = require('../lib/annotations.js');

module.exports = {
	"Sodor controller": {
		"makePaths": {
			"should return a path based on classname and action name"() {
				class Foo extends Controller {
					bar() {}
				}
				var o = Foo.makePaths('bar', []);
				expect(o).to.contain("/foo/bar");
			},

			"should use base path instead of class name"() {
				class Foo extends Controller {
					bar() {}
				}
				Foo.base = "/baz/quux";
				var o = Foo.makePaths('bar', []);
				expect(o).to.contain("/baz/quux/bar");
				expect(o).not.to.contain("/foo/bar");
			},

			"should add path parts based on function params": {
				"with a single parameter"() {
					class Foo extends Controller {
						bar() {}
					}
					var o = Foo.makePaths('bar', ['a']);
					expect(o).to.contain("/foo/bar/:a");
				},
				"with multiple parameters"() {
					class Foo extends Controller {
						bar() {}
					}
					var o = Foo.makePaths('bar', ['a', 'b', 'c', 'd']);
					expect(o).to.contain("/foo/bar/:a/:b/:c/:d");
				}
			},

			"should create root paths for a root-annotated action"() {
				class Foo extends Controller {
					@root
					bar() {}
				}

				expect(Foo.makePaths('bar',[])).to.contain('/foo');
			},

			"should create root paths for index action"() {
				class Foo extends Controller {
					index() {}
				}

				expect(Foo.makePaths('index', [])).to.contain('/foo');
			},

			"should create root paths for a root-annotated controller"() {
				@root
				class Foo extends Controller {
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.contain('/foo');
			},

			"should add alias paths"() {
				class Foo extends Controller {
					@alias('/another/path')
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.contain('/another/path');
			},

			"should add multiple alias paths"() {
				class Foo extends Controller {
					@alias('/another/path', '/another/other/path')
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.contain('/another/path');
				expect(Foo.makePaths('bar', [])).to.contain('/another/other/path');
			},

			"should skip private actions entirely"() {
				class Foo extends Controller {
					@Controller.private
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.be.empty();
			},

			"should skip default route of special actions"() {
				class Foo extends Controller {
					@Controller.special
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.be.empty();
			},

			"should allow alias of special actions"() {
				class Foo extends Controller {
					@Controller.special @alias('/quux')
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.contain('/quux');
				expect(Foo.makePaths('bar', [])).not.to.contain('/foo/bar');
			},
				
			"should allow root route of special actions"() {
				class Foo extends Controller {
					@Controller.special @root
					bar() {}
				}

				expect(Foo.makePaths('bar', [])).to.contain('/foo');
				expect(Foo.makePaths('bar', [])).not.to.contain('/foo/bar');
			}
		},

		"handle": {
			"should instantiate the controller"(done) {
				class Foo extends Controller {
					bar() {
						expect(this).to.be.a(Foo);
						done();
					}
				}

				Foo.handle('bar', [])();
			},

			"should pass through return values"() {
				class Foo extends Controller {
					bar() { return 'world'; }
				}

				var o = Foo.handle('bar', []);
				expect(o()).to.be('world');
			},

			"should send url parameters to the right places"(done) {
				class Foo extends Controller {
					bar(a,b) {
						expect(a).to.be('hello');
						expect(b).to.be('world');
						done();
					}
				}

				var o = Foo.handle('bar', ['a', 'b']);
				o({params: {
					a: 'hello',
					b: 'world'
				}});
			}
		},

		"routes": {
			before() {
				var respond = this.respond = expect.sinon.stub();
				sodor.__set__({respond});
				expect.sinon.stub(Controller, 'handle');
				expect.sinon.stub(Controller, 'makePaths');
			},

			after() {
				Controller.handle.restore();
				Controller.makePaths.restore();
			},

			beforeEach() {
				Controller.makePaths.returns(['/']);
				Controller.handle.returns(() => {});
			},

			"should make handlers for each action"() {
				class Foo extends Controller {
					a() {}
					b() {}
					c() {}
				}

				Foo.routes();
				expect(Controller.handle).to.be.calledWith('a');
				expect(Controller.handle).to.be.calledWith('b');
				expect(Controller.handle).to.be.calledWith('c');
			},

			"should make routes for each handler"() {
				var handler = () => {};
				Controller.handle.returns(handler);
				class Foo extends Controller {
					a() {}
				}

				Foo.routes();
				expect(this.respond).to.be.calledWith('get', '/', handler);
			},
				
			"should pass through the method"() {
				class Foo extends Controller {
					@Controller.post
					a() {}
				}

				Foo.routes();
				expect(this.respond).to.be.calledWith('post');
			},

			"should create multiple routes for multiple paths"() {
				Controller.makePaths.returns(['a', 'b']);
				class Foo extends Controller {
					a() {}
				}

				Foo.routes();
				expect(this.respond).to.be.calledWith('get', 'a');
				expect(this.respond).to.be.calledWith('get', 'b');
			},

			"should return the list of routes"() {
				this.respond.returns('a');
				class Foo extends Controller {
					a() {}
				}

				expect(Foo.routes()).to.contain('a');
			},

			"should get parameter names from function params"() {
				class Foo extends Controller {
					bar(a, b, c) {}
				}

				Foo.routes();
				expect(Foo.handle).to.be.calledWith('bar', ['a', 'b', 'c']);
			}
		},

		"actionNames": {
			"should get a list of methods"() {
				class Foo extends Controller {
					bar() {}
					baz() {}
				}

				expect(Foo.actionNames()).to.contain('bar');
				expect(Foo.actionNames()).to.contain('baz');
			},

			"shouldn't include internal prototype stuff"() {
				class Foo extends Controller {}
				expect(Foo.actionNames()).not.to.contain('constructor');
				expect(Foo.actionNames()).not.to.contain('__proto__');
			},

			"should see inherited things"() {
				class Foo extends Controller {
					bar() {}
				}

				class Baz extends Foo {}

				expect(Baz.actionNames()).to.contain('bar');
			}
		},

		"context": {
			"should provide a supplimentary context to the thing"(done) {
				var req = {};
				class Foo extends Controller {
					bar() {
						expect(this).to.have.property('action', 'bar');
						expect(this).to.have.property('request', req);
						done();
					}
				}

				Foo.context = (action) => ({action});
				Foo.handle('bar', [])(req);
			},

			"should work with inherited methods"(done) {
				var req = {};
				class Foo extends Controller {
					baz() {}
				}
				class Bar extends Foo {
					quux() {
						expect(this.baz).to.be.a(Function);
						done();
					}
				}
				Foo.context = (action) => ({action});

				Bar.handle('quux', [])(req);
			}
		}
	}
};