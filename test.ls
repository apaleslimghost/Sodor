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
		"should pass url parameters to the right function parameters": ->
			class Foo extends Controller
				bar: (a)->
					expect a .to.be \hello
					return \world

			o = Foo.make-handler \bar Foo::bar
			expect o.handler params:a:\hello .to.be \world
