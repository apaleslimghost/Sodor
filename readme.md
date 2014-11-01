# Sodor

Controller dispatching for Livewire. Which lets you write routes like

```javascript
class Post extends Controller {
  read(id) { ... }
  @put update(id) { ... }
  @post delete(id) { ... }
}
/* ES6 with Traceur annotations */
```

where the function arguments become URL parameters and http method decorators do what you think.

## Installation

`npm install sodor`

## Usage

Declare a few controller classes, then call e.g. `Post.routes()` and pass it to `livewire.route`.

For more information see the [API docs](https://github.com/quarterto/Sodor/wiki/index)

## Licence

MIT. &copy; 2014 Matt Brennan
