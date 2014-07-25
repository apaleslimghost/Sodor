# Sodor
# =====
#### Import our dependencies
require! {
	'get-parameter-names'
	'livewire/lib/respond'
	path.normalize
	Symbol: 'es6-symbol'
	Base: estira
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
#### Symbols
# Create some symbols so we don't overwrite things or get things overwritten
export root  = Symbol \root
export alias = Symbol \alias
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
	to-string: -> '/' + @parts.join '/'
##### `#concat :: (Path | Array String) → Path
	concat: (o)->
		Path ...(this.parts ++ (o.parts ? o))
# `Controller`
# ---
#
# The main class we export. Consumers should extend this.
#
# Since we extend `Base` (i.e. [Estira](/quarterto/Estira)), Javascript consumers can write `Controller.extend('Foo', {bar: function() {...}})`. 
export class Controller extends Base
	##### `constructor`
	# We save the request to the instance (as we see later, it's one instance ⇔ one request).
	(@request)->
	##### `method :: HTTPMethod → Action → Action`
	@method = (val, action)--> action import method:val
	##### `alias :: Path → Action → Action`
	@alias = (...aka, action)->
		action[alias] = action.[][alias].concat aka
		action
	##### `root :: Action → Action`
	# Sets `root` to true for the action
	@root = (obj ? this) -> obj import {+(root)}
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
	##### `base-path :: → Path`
	# Gets the base path for this controller. If Controller.base is specified, use that, otherwise use the class name in lower case.
	@base-path = ->
		@base ? @display-name.to-lower-case!
	##### `make-paths :: String → [String] → Path`
	# Turn an action name and some parameter names into a path, potentially in 3 different ways:
	#   1. /class-name/action-name/params
	#   2. /class-name/params if the action has `root` set
	#   3. /alias/params if the action has an `alias`
	@make-paths = (action, params)->
		params-parts = params.map (':' +)
		make-path = normalize . (.to-string!)
		base = @base-path!

		join [
			[Path base, action]
			[Path base] `array-if` (@::[action][root] or @[root])
			(@::[action][alias]?map Path.parse) `array-if` @::[action][alias]?
		] .map make-path . (++ params-parts)
	##### `handle :: String → [String] → (Request → Promise Response`
	# Wrap an action in a Livewire-compatible route handler that assigns parameters and instantiates the controller before calling the correct action.
	@handle = (action, params)-> (req)~>
		values = [req.params[k] for k in params]
		controller = new this req
		controller[action] ...values
