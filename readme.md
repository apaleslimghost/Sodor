# Sodor

Controller dispatching for Livewire. Which lets you write routes like

```livescript
class Post extends Controller
  read: (id)-> ...
	update: @put  (id)-> ...
	delete: @post (id)-> ...
```

where the function arguments become URL parameters and http method decorators do what you think.

## Installation

`npm install sodor`

## Usage

Declare a few controller classes, then call e.g. `Post.routes()` and pass it to `livewire.route`.

## Licence

MIT. &copy; 2014 Matt Brennan