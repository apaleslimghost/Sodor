# Sodor
# =====
#### Import our dependencies
require! {
	'get-parameter-names'
	'livewire/lib/respond'
	path.normalize
}
#### Some functional helpers
##### `flat-map :: Array a → (a → (Array b | b)) → Array b`
# Yay for Javascript's type system. `.concat` is `Array a → (Array a | a) → Array a`
flat-map = (xs, f)-->
	xs.reduce ((a, x)-> a ++ f x), []
##### `guard :: Boolean → Array ()`
guard = (cond)-> if cond then [null] else []
# `Controller`
# ---
#
# The main class we export. Consumers should extend this.
export class Controller
	##### `constructor`
	# We save the request to the instance (as we see later, it's one instance ⇔ one request).
	(@request)->
	##### `private property-decorator`
	# Shorthand for creating decorators which save properties of the same name
	property-decorator = (prop)~>
		@[prop] = (val, action)--> action import (prop):val
	##### `method :: HTTPMethod → Action → Action`
	property-decorator \method
	##### `alias :: Path → Action → Action`
	property-decorator \alias
	##### `root :: Action → Action`
	# Sets `root` to true for the action
	@root = (import {+root})
	##### Method decorators
	# These are `method` partially applied with the usual HTTP methods
	for m in <[get post put delete patch options head trace connect]>
		@[m] = @method m
	##### `routes :: [Request → Maybe Promise Response]`
	# Collect the actions together into an array of routes
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
	##### `make-paths :: String → [String] → Path`
	# Turn an action name and some parameter names into a path, potentially in 3 different ways:
	#   1. /class-name/action-name/params
	#   2. /class-name/params if the action has `root` set
	#   3. /alias/params if the action has an `alias`
	@make-paths = (action, params)->
		params-parts = params.map (':' +)
		make-path = normalize . ('/' +) . (.join '/')
		classname = @display-name.to-lower-case!

		[
			[classname, action]
			[classname] if @::[action].root
			[that] if @::[action].alias?
		].filter (?) .map make-path . (++ params-parts)
	##### `handle :: String → [String] → (Request → Promise Response`
	# Wrap an action in a Livewire-compatible route handler that assigns parameters and instantiates the controller before calling the correct action.
	@handle = (action, params)-> (req)~>
		values = [req.params[k] for k in params]
		controller = new this req
		controller[action] ...values
