# Sodor
# =====
#### Import our dependencies
require! {
	'get-parameter-names'
	'livewire/lib/respond'
	path.normalize
	Symbol: 'es6-symbol'
}
#### Some functional helpers
##### `flat-map :: Array a → (a → (Array b | b)) → Array b`
# Yay for Javascript's type system. `.concat` is `Array a → (Array a | a) → Array a`
flat-map = (xs, f)-->
	xs.reduce ((a, x)-> a ++ f x), []
##### `guard :: Boolean → Array ()`
guard = (cond)-> if cond then [null] else []
##### `array-if :: Array a → Boolean → Array a`
array-if = (xs, cond)-->
	flat-map (guard cond), -> xs
##### `id :: ∀ a. a → a`
id = (a)-> a
##### `join :: Array Array a → Array a`
join = (`flat-map` id)
##### `props :: Object → [String]`
props = -> [.. for Object.get-own-property-names it | .. isnt \constructor]
#### Symbols
# Create some symbols so we don't overwrite things or get things overwritten
export root    = Symbol \root
export alias   = Symbol \alias
export method  = Symbol \method
export pirate  = Symbol \private
export special = Symbol \special
# `Path`
# ---
#
# Utility class for constructing and parsing paths, so as we don't accidentally munge arrays together.
export class Path
##### `parse :: String → Path`
	@parse = (path)->
		Path ...(path.split '/')
##### `constructor`
	(...@parts)~>
##### `#to-string :: → String`
	to-string: -> normalize '/' + @parts.join '/'
##### `#concat :: (Path | Array String) → Path
	concat: (o)->
		Path ...(this.parts ++ (o.parts ? o))
# `Controller`
# ---
#
# The main class we export. Consumers should extend this.
#
export class Controller
	##### `constructor`
	# We save the request to the instance (as we see later, it's one instance ⇔ one request).
	(@request)->
	##### `method :: HTTPMethod → Action → Action`
	@method = (val, action)--> action import (method):val
	##### `alias :: Path → Action → Action`
	@alias = (...aka, action)->
		action[alias] = action.[][alias].concat aka
		action
	##### `root :: Action → Action`
	# Sets `root` to true for the action
	@root = (obj ? this) -> obj import {+(root)}
	##### `root :: Action → Action`
	# Sets `root` to true for the action
	@private = (obj ? this) -> obj import {+(pirate)}
	##### `root :: Action → Action`
	# Sets `root` to true for the action
	@special = (obj ? this) -> obj import {+(special)}
	##### Method decorators
	# These are `method` partially applied with the usual HTTP methods
	for m in <[get post put delete patch options head trace connect]>
		@[m] = @method m
	##### `routes :: [Request → Maybe Promise Response]`
	# Collect the actions together into an array of routes
	@routes = ->
		action <~ flat-map @action-names!

		params = get-parameter-names @::[action]
		handler = @handle action, params

		path <~ flat-map @make-paths action, params
		respond do
			@::[action][method] ? \get
			path
			handler
	##### `action-names :: [String]`
	# Get a list of the class' method names
	@action-names = ->
		| this is Controller => []
		| otherwise => @superclass.action-names! ++ props @::
	##### `base-path :: → Path`
	# Gets the base path for this controller. If Controller.base is specified, use that, otherwise use the class name in lower case.
	@base-path = ->
		@base ? @display-name.to-lower-case!
	##### `make-paths :: String → [String] → Path`
	# Turn an action name and some parameter names into a path, potentially in 3 different ways:
	#   1. /class-name/action-name/params unless the action is `special`
	#   2. /class-name/params if the action has `root` set
	#   3. /alias/params if the action has an `alias`
	# If the action is `private`, no routes are generated. It can, however, be called internally from other routes.
	@make-paths = (action, params)->
		params-parts = params.map (':' +)
		base = @base-path!
		method = @::[action]

		join [
			[Path base, action] `array-if` not method[special]
			[Path base] `array-if` (method[root] or @[root])
			(method[alias]?map Path.parse) `array-if` method[alias]?
		] `array-if` not method[pirate]
		.map (.to-string!) . (++ params-parts)
	##### `handle :: String → [String] → (Request → Promise Response)`
	# Wrap an action in a Livewire-compatible route handler that assigns parameters and instantiates the controller before calling the correct action.
	@handle = (action, params)-> (req)~>
		values = [req.params[k] for k in params]
		controller = new this req
		context = if @context?
			(@context action) import controller
		else controller
		controller[action].apply context, values
