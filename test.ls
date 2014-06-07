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
