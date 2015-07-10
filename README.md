# simDOM

JavaScript library for CoffeeScript developers. This library is work in progress.

[![NPM Version][npm-image]][npm-url] [![Travis CI][travis-image]][travis-url]

Notes
- ie 9+
- less than 10kB minified and gzipped
- uses native events
- understands jQuery
- `sim('body') is sim('body')`

## Installation

```html
<script src="sim.js"></script>
```

## Usage

```coffee
sim(document.body).do ->
	@header ->
		@h1().text "Welcome to my Blog"
	
	@section ->
		for aricle in articles
			@article ->
				@h1().text article.title
				@p().text article.content
	
	@footer ->
		@p().text "Thanks for visiting."
```

### Server-side Usage

```coffeescript
sim = require 'simdom'

sim.div '.hello', ->
	@span '.world', ->
		@text "Sample"
	
	console.log @toString()
```

Results in:

```html
<div class="hello"><span class="world">Sample</span></div>
```

## Documentation

### Selectors

```coffeescript
# string
sim 'div' # returns SIMArray of all divs on the page
sim '#id' # returns SIMElement of that id or null

# html element
sim document.body # return SIMElement of body
sim document.getElementById 'id' # return SIMElement of that id or null
sim document.getElementsByClassName 'class' # return SIMArray of all elements with that class

# special
sim.one <selector> # alway return result as SIMElement or null
sim.array <selector> # always return result as SIMArray
```

### DOM Creation

```coffeescript
sim.div() # <div></div>
sim.div '.style' # <div class="style"></div>
sim.div '#uid' # <div id="uid"></div>
sim.div '[data-attr="value"]' # <div data-attr="value"></div>
sim.div ':disabled' # <div disabled></div>
sim.div '.style.foo#uid[data-attr="value"]:disabled' # <div class="style foo" id="uid" data-attr="value" disabled></div>
```

#### Nesting

```coffeescript
sim.div ->
	@div '.style', ->
		@div '#uid', ->
			@div '[data-attr="value"]', ->
				@div ':disabled', ->
					@text 'Hello
```

Results in:

```html
<div><div class="style"><div id="uid"><div data-attr="value"><div disabled>Hello</div></div></div></div></div>
```

<a name="license" />
## License

Copyright (c) 2015 Integromat

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[npm-image]: https://img.shields.io/npm/v/simdom.svg?style=flat-square
[npm-url]: https://www.npmjs.com/package/simdom
[travis-image]: https://img.shields.io/travis/integromat/simdom/master.svg?style=flat-square&label=unit
[travis-url]: https://travis-ci.org/integromat/simdom