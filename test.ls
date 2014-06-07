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
		"shoud have shorthands for http methods": {[
			m, ->
				o = {}
				Controller[m] o
				expect o .to.have.property \method m
		] for m in <[get post put delete patch options head trace connect]>}
