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

	"make-handler":
		"should return a path based on classname and action name": ->
			class Foo extends Controller
			o = Foo.make-handler \bar ->
			expect o.path .to.be "/foo/bar/"

		"should add path parts based on function params":
			"with a single parameter": ->
				class Foo extends Controller
				o = Foo.make-handler \bar (a)->
				expect o.path .to.be "/foo/bar/:a"

			"with multiple parameters": ->
				class Foo extends Controller
				o = Foo.make-handler \bar (a,b,c,d)->
				expect o.path .to.be "/foo/bar/:a/:b/:c/:d"

			"even with a method decorator": ->
				class Foo extends Controller
				o = Foo.make-handler \bar Foo.post (a)->
				expect o.path .to.be "/foo/bar/:a"

		"should wrap actions in handlers":
			"that instantiate the controller": (done)->
				c = expect.sinon.spy!
				class Foo extends Controller
					constructor$$: c
					bar: ->
						expect this .to.be.a Foo
						expect c .to.be.called!
						done!

				o = Foo.make-handler \bar Foo::bar
				o.handler!

			"that pass through return values": ->
				class Foo extends Controller
					bar: -> \world

				o = Foo.make-handler \bar Foo::bar
				expect o.handler! .to.be \world

			"that send url parameters to the right places": (done)->
				class Foo extends Controller
					bar: (a,b)->
						expect a .to.be \hello
						expect b .to.be \world
						done!

				o = Foo.make-handler \bar Foo::bar
				o.handler params:
					a: \hello
					b: \world

	"routes":
		before: ->
			@respond = expect.sinon.stub!
			sodor.__set__ {@respond}

		before-each: ->
			expect.sinon.stub Controller, \makeHandler

		after-each: ->
			Controller.make-handler.restore!

		"should make handlers for each action": ->
			Controller.make-handler.returns path:'' handler:->

			class Foo extends Controller
				a: ->
				b: ->
				c: ->

			Foo.routes!
			expect Controller.make-handler .to.be.called-with \a Foo::a
			expect Controller.make-handler .to.be.called-with \b Foo::b
			expect Controller.make-handler .to.be.called-with \c Foo::c

		"should make routes for each handler": ->
			path = '/'
			handler = ->
			Controller.make-handler.returns {path, handler}

			class Foo extends Controller
				a: ->

			Foo.routes!
			expect @respond .to.be.called-with \get path, handler
			
		"should pass through the method": ->
			Controller.make-handler.returns path: '' handler: ->

			class Foo extends Controller
				a: @post ->

			Foo.routes!
			expect @respond .to.be.called-with \post

