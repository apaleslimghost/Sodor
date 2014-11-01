require! {
	'karma-sinon-expect'.expect
	rewire
}

{Controller}:sodor = rewire '../lib/index.js'

export "Sodor Controller":
	"method":
		"should add a method annotation": ->
			o = {}
			Controller.method \a o
			expect o.annotations.0 .to.be.a Controller.method
			expect o.annotations.0 .to.have.property \method \a


		"should have shorthands for http methods": {[
			m, ->
				o = {}
				Controller[m] o
				expect o.annotations.0 .to.have.property \method m
		] for m in <[get post put delete patch options head trace connect]>}

	"root":
		"should add a root annotation": ->
			o = {}
			Controller.root o
			expect o.annotations.0 .to.be.a Controller.root

	"private":
		"should add a private annotation": ->
			o = {}
			Controller.private o
			expect o.annotations.0 .to.be.a Controller.private

	"special":
		"should add a special annotation": ->
			o = {}
			Controller.special o
			expect o.annotations.0 .to.be.a Controller.special

	"alias":
		"should add an alias annotation": ->
			o = {}
			Controller.alias \a o
			expect o.annotations.0 .to.be.a Controller.alias
			expect o.annotations.0.alias .to.eql [\a]

	"make-paths":
		"should return a path based on classname and action name": ->
			class Foo extends Controller
				bar: ->
			o = Foo.make-paths \bar []
			expect o .to.contain "/foo/bar"

		"should use base path instead of class name": ->
			class Foo extends Controller
				@base = "/baz/quux"
				bar: ->
			o = Foo.make-paths \bar []
			expect o .to.contain "/baz/quux/bar"
			expect o .not.to.contain "/foo/bar"

		"should add path parts based on function params":
			"with a single parameter": ->
				class Foo extends Controller
					bar: ->
				o = Foo.make-paths \bar [\a]
				expect o .to.contain "/foo/bar/:a"

			"with multiple parameters": ->
				class Foo extends Controller
					bar: ->
				o = Foo.make-paths \bar <[a b c d]>
				expect o .to.contain "/foo/bar/:a/:b/:c/:d"

		"should create root paths for a root-annotated action": ->
			class Foo extends Controller
				bar: @root ->

			expect Foo.make-paths \bar [] .to.contain '/foo'

		"should create root paths for index action": ->
			class Foo extends Controller
				index: ->

			expect Foo.make-paths \index [] .to.contain '/foo'

		"should create root paths for a root-annotated controller": ->
			class Foo extends Controller
				@root!
				bar: ->

			expect Foo.make-paths \bar [] .to.contain '/foo'

		"should add alias paths": ->
			class Foo extends Controller
				bar: @alias '/another/path' ->

			expect Foo.make-paths \bar [] .to.contain '/another/path'

		"should add multiple alias paths": ->
			class Foo extends Controller
				bar: @alias '/another/path' '/another/other/path' ->

			expect Foo.make-paths \bar [] .to.contain '/another/path'
			expect Foo.make-paths \bar [] .to.contain '/another/other/path'

		"should skip private actions entirely": ->
			class Foo extends Controller
				bar: @private ->

			expect Foo.make-paths \bar [] .to.be.empty!

		"should skip default route of special actions": ->
			class Foo extends Controller
				bar: @special ->

			expect Foo.make-paths \bar [] .to.be.empty!
			
		"should allow alias of special actions": ->
			class Foo extends Controller
				bar: @special @alias '/quux' ->

			expect Foo.make-paths \bar [] .to.contain '/quux'
			expect Foo.make-paths \bar [] .not.to.contain '/foo/bar'
			
		"should allow root route of special actions": ->
			class Foo extends Controller
				bar: @special @root ->

			expect Foo.make-paths \bar [] .to.contain '/foo'
			expect Foo.make-paths \bar [] .not.to.contain '/foo/bar'

	"handle":
		"should instantiate the controller": (done)->
			c = expect.sinon.spy!
			class Foo extends Controller
				constructor$$: c
				bar: ->
					expect this .to.be.a Foo
					expect c .to.be.called!
					done!

			(Foo.handle \bar [])!

		"should pass through return values": ->
			class Foo extends Controller
				bar: -> \world

			o = Foo.handle \bar []
			expect o! .to.be \world

		"should send url parameters to the right places": (done)->
			class Foo extends Controller
				bar: (a,b)->
					expect a .to.be \hello
					expect b .to.be \world
					done!

			o = Foo.handle \bar [\a \b]
			o params:
				a: \hello
				b: \world

	"routes":
		before: ->
			@respond = expect.sinon.stub!
			sodor.__set__ {@respond}
			expect.sinon.stub Controller, \handle
			expect.sinon.stub Controller, \makePaths

		after: ->
			Controller.handle.restore!
			Controller.make-paths.restore!

		before-each: ->
			Controller.make-paths.returns ['/']
			Controller.handle.returns ->

		"should make handlers for each action": ->
			class Foo extends Controller
				a: ->
				b: ->
				c: ->

			Foo.routes!
			expect Controller.handle .to.be.called-with \a
			expect Controller.handle .to.be.called-with \b
			expect Controller.handle .to.be.called-with \c

		"should make routes for each handler": ->
			Controller.handle.returns handler = ->
			class Foo extends Controller
				a: ->

			Foo.routes!
			expect @respond .to.be.called-with \get '/' handler
			
		"should pass through the method": ->
			class Foo extends Controller
				a: @post ->

			Foo.routes!
			expect @respond .to.be.called-with \post

		"should create multiple routes for multiple paths": ->
			Controller.make-paths.returns [\a \b]
			class Foo extends Controller
				a: ->

			Foo.routes!
			expect @respond .to.be.called-with \get 'a'
			expect @respond .to.be.called-with \get 'b'

		"should return the list of routes": ->
			@respond.returns \a
			class Foo extends Controller
				a: ->

			expect Foo.routes! .to.contain \a

		"should get parameter names from function params": ->
			class Foo extends Controller
				a: (a, b, c)->

			Foo.routes!
			expect Foo.handle .to.be.called-with \a [\a \b \c]

	"action-names":
		"should get a list of methods": ->
			class Foo extends Controller
				bar: ->
				baz: ->

			expect Foo.action-names! .to.contain 'bar'
			expect Foo.action-names! .to.contain 'baz'

		"shouldn't include internal prototype stuff": ->
			class Foo extends Controller
			expect Foo.action-names! .not.to.contain 'constructor'
			expect Foo.action-names! .not.to.contain '__proto__'

		"should see inherited things": ->
			class Foo extends Controller
				bar: ->

			class Baz extends Foo

			expect Baz.action-names! .to.contain 'bar'

	"context":
		"should provide a supplimentary context to the thing": (done)->
			req = {}
			class Foo extends Controller
				@context = (action)-> {action}
				bar: ->
					expect this .to.have.property \action \bar
					expect this .to.have.property \request req
					done!

			(Foo.handle \bar []) req

		"should work with inherited methods": (done)->
			req = {}
			class Foo extends Controller
				baz: ->
			class Bar extends Foo
				@context = (action)-> {action}
				quux: ->
					expect @baz .to.be.a Function
					done!

			(Bar.handle \quux []) req

