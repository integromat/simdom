# simDOM

JavaScript library for CoffeeScript developers.

[![NPM Version][npm-image]][npm-url] [![Travis CI][travis-image]][travis-url]

## Installation

```html
<script src="sim.js"></script>
```

## Usage

```coffee
sim(body).do ->
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

## Server-side Usage

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

## Notes

```coffee
sim('body') is sim('body') # true
```

<a name="license" />
## License

Copyright (c) 2015 Integromat LLC

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[npm-image]: https://img.shields.io/npm/v/simdom.svg?style=flat-square
[npm-url]: https://www.npmjs.com/package/simdom
[travis-image]: https://img.shields.io/travis/integromat/simdom/master.svg?style=flat-square&label=unit
[travis-url]: https://travis-ci.org/integromat/simdom