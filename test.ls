require! {
	'karma-sinon-expect'.expect
	rewire
}

{Controller}:sodor = rewire './index.js'

export "Sodor Controller":
	"method":
		"should add a method property": ->
			o = {}
			Controller.method \a o
			expect o .to.have.property \method \a

		"should have shorthands for http methods": {[
			m, ->
				o = {}
				Controller[m] o
				expect o .to.have.property \method m
		] for m in <[get post put delete patch options head trace connect]>}

	"root":
		"should set root to be true": ->
			o = {}
			Controller.root o
			expect o .to.have.property \root true
	
	

	"make-paths":
		"should return a path based on classname and action name": ->
			class Foo extends Controller
			o = Foo.make-paths \bar []
			expect o .to.contain "/foo/bar/"

		"should add path parts based on function params":
			"with a single parameter": ->
				class Foo extends Controller
				o = Foo.make-paths \bar [\a]
				expect o .to.contain "/foo/bar/:a"

			"with multiple parameters": ->
				class Foo extends Controller
				o = Foo.make-paths \bar <[a b c d]>
				expect o .to.contain "/foo/bar/:a/:b/:c/:d"

	"handle":
		"should instantiate the controller": (done)->
			c = expect.sinon.spy!
			class Foo extends Controller
				constructor$$: c
				bar: ->
					expect this .to.be.a Foo
					expect c .to.be.called!
					done!

			(Foo.handle \bar Foo::bar, [])!

		"should pass through return values": ->
			class Foo extends Controller
				bar: -> \world

			o = Foo.handle \bar Foo::bar, []
			expect o! .to.be \world

		"should send url parameters to the right places": (done)->
			class Foo extends Controller
				bar: (a,b)->
					expect a .to.be \hello
					expect b .to.be \world
					done!

			o = Foo.handle \bar Foo::bar, [\a \b]
			o params:
				a: \hello
				b: \world

	"routes":
		before: ->
			@respond = expect.sinon.stub!
			sodor.__set__ {@respond}
			expect.sinon.stub Controller, \handle
			expect.sinon.stub Controller, \makePaths

		before-each: ->
			Controller.make-paths.returns ['/']
			Controller.handle.returns ->

		"should make handlers for each action": ->
			class Foo extends Controller
				a: ->
				b: ->
				c: ->

			Foo.routes!
			expect Controller.handle .to.be.called-with \a Foo::a
			expect Controller.handle .to.be.called-with \b Foo::b
			expect Controller.handle .to.be.called-with \c Foo::c

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

