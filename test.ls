require! {
	'./index.js'.Controller
	'karma-sinon-expect'.expect
}

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

