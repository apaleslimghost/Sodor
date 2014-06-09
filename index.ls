require! {
	'get-parameter-names'
	'livewire/lib/respond'
	path.normalize
}

flat-map = (xs, f)-->
	xs.reduce ((a, x)-> a ++ f x), []
guard = (cond)-> if cond then [null] else []

export class Controller
	(@request)->

	property-decorator = (prop)~>
		@[prop] = (val, action)--> action import (prop):val

	property-decorator \method
	property-decorator \alias

	@root = (import {+root})

	for m in <[get post put delete patch options head trace connect]>
		@[m] = @method m

	@routes = ->
		action <~ flat-map Object.keys @::
		<~ flat-map guard action not of Controller::

		params = get-parameter-names @::[action]
		handler = @handle action, params

		path <~ flat-map @make-paths action, params
		respond do
			@::[action].method ? \get
			path
			handler

	@make-paths = (action, params)->
		params-parts = params.map (':' +)
		make-path = normalize . ('/' +) . (.join '/')
		classname = @display-name.to-lower-case!

		[
			[classname, action]
			[classname] if @::[action].root
			[that] if @::[action].alias?
		].filter (?) .map make-path . (++ params-parts)

	@handle = (action, params)-> (req)~>
		values = [req.params[k] for k in params]
		controller = new this req
		controller[action] ...values
