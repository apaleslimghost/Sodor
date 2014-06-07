require! {
	\get-parameter-names
	livewire.respond
}

export class Controller
	(@request)->

	@method = (method, action)-->
		action import {method}

	for m in <[get post put delete patch options head trace connect]>
		@[m] = @method m

	@routes = ->
		for action, fn of @:: when action not of Controller::
			{path, handler} = @make-handler action, fn
			
			respond do
				fn.method ? \get
				path
				handler

	@make-handler = (action, fn)->
		params = get-parameter-names fn
		params-path = params.map (':' ++) .join '/'

		path: "/#{@display-name.to-lower-case!}/#action/#params-path"
		handler: (req)~>
			values = [req.params[k] for k in params]
			controller = new this req
			controller[action] ...values
