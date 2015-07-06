###!
 * simDOM SVG
 * http://simdom.org/

 * Released under the MIT license
 * http://simdom.org/license
###

install = (sim) ->
	SVG_TAGS = ['a', 'altGlyph', 'altGlyphDef', 'altGlyphItem', 'animate', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'color-profile', 'cursor', 'defs', 'desc', 'ellipse', 'g', 'linearGradient', 'path', 'radialGradient', 'stop']
	
	class SIMSVGElement extends sim.SIMElement
		@NS: 'http://www.w3.org/2000/svg'
		
		addClass: (name) ->
			if not @hasClass name
				@attr 'class', [name].concat (@attr('class') ? '').split ' '
				
			@
		
		hasClass: (name) ->
			(@attr('class') ? '').split(' ').indexOf(name) isnt -1
		
		toString: ->
			str = @__dom.outerHTML
			if not str? # polyfill
				outerHTML = (elm) ->
					attrs = ("#{attr.name}=\"#{attr.value.replace(/&/g, '&amp;').replace(/"/g, '&quot;')}\"" for attr in elm.attributes)
					if attrs.length then attrs.unshift '' # to create indent
					str = "<#{elm.nodeName.toLowerCase()}#{attrs.join ' '}>#{outerHTML(child) for child in elm.childNodes}</#{elm.nodeName.toLowerCase()}>"
				
				str = outerHTML @__dom
			
			str

	sim.SIMSVGElement = SIMSVGElement
	
	sim.registerNamespace SIMSVGElement.NS, SIMSVGElement

	do ->
		sim.svg = sim.create.bind SIMSVGElement, 'svg', null

		Object.defineProperty sim.SIMElement.prototype, 'svg',
			enumerable: false
			configurable: true
			writable: true
			value: -> sim.create.call SIMSVGElement, tag, @, arguments...
		
		for tag in SVG_TAGS
			if not sim.hasOwnProperty tag.svg
				sim.svg[tag] = sim.create.bind SIMSVGElement, tag, null
			
			do (tag) ->
				if not SIMSVGElement::hasOwnProperty tag
					Object.defineProperty SIMSVGElement.prototype, tag,
						enumerable: false
						configurable: true
						writable: true
						value: -> sim.create.call SIMSVGElement, tag, @, arguments...

do (window = window ? null) ->
	if not window?
		# node
		module.exports = install
	
	else
		install window.sim