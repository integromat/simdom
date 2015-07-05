{EventEmitter} = require 'events'

###

Node

###

CONTAINERS = ['a', 'body', 'div', 'html', 'i', 'li', 'p', 'path', 'ul', 'svg']
isContainer = (elm) ->
	elm.nodeName.toLowerCase() in CONTAINERS

# --------

class EventTarget
	constructor: ->
		EventEmitter.call @
		
	addEventListener: (event, handler) ->
		EventEmitter::addListener.call @, event, handler
	
	dispatchEvent: (event) ->
		if event not instanceof Event
			throw new TypeError "Invalid arguments."
		
		stopped = false
		stoppedImmediately = false
		event.stopPropagation = -> stopped = true
		event.stopImmediatePropagation = -> stoppedImmediately = true
		event.target = @
		
		if event.bubbles
			level = @
			while level
				handlers = level._events[event.type]
				if handlers
					if 'function' is typeof handlers then handlers = [handlers]
					for handler in handlers
						event.currentTarget = level
						res = handler.call level, event
						if res is false
							event.stopPropagation()
							event.preventDefault()
						
						if stoppedImmediately
							break
					
					if stopped
						break
				
				level = level.parentNode
		
		else
			handlers = @_events[event.type]
			if handlers
				if 'function' is typeof handlers then handlers = [handlers]
				for handler in handlers
					event.currentTarget = @
					handler.call level, event

		@
	
	removeEventListener: (event, handler) ->
		EventEmitter::removeListener.call @, event, handler

# --------

class Event
	defaultPrevented: false
	
	constructor: (@type, options = {}) ->
		@bubbles = options.bubbles ? false
		@cancelable = options.cancelable ? false
		@detail = options.detail
	
	preventDefault: ->
		@defaultPrevented = true
	
	stopPropagation: ->
	
	stopImmediatePropagation: ->

class CustomEvent extends Event

# --------

class Node extends EventTarget
	childNodes: null
	parentNode: null
	namespaceURI: 'http://www.w3.org/1999/xhtml'
	nodeType: 1
	nodeValue: null
	
	constructor: (name) ->
		super()
		
		@nodeName = @tagName = name.toUpperCase()
		@attributes = {}
		@style = {}
		@childNodes = []
	
	contains: (elm) ->
		if elm is @ then return true
		
		for child in @childNodes
			if child is elm then return true
			if child.contains elm then return true
		
		false
	
	appendChild: (child) ->
		if child not instanceof Node
			throw new TypeError "Invalid child element."
		
		if not isContainer @
			throw new TypeError "Element can't contain child elements."
		
		if child.parentNode?
			child.parentNode.removeChild child

		@childNodes.push child
		child.parentNode = @
		child
	
	cloneNode: (deep) ->
		elm = new @constructor @nodeName
		elm.namespaceURI = @namespaceURI
		
		if deep is true
			elm.appendChild child.cloneNode true for child in @childNodes
		
		elm
	
	getAttribute: (key) ->
		@attributes[key]
	
	hasAttribute: (key) ->
		@attributes[key]?

	hasChildNodes: ->
		@childNodes.length > 0
	
	insertBefore: (child, elm) ->
		if child not instanceof Node
			throw new TypeError "Invalid child element."

		if not isContainer @
			throw new TypeError "Element can't contain child elements."
			
		if not elm?
			@appendChild child
			return child
		
		if elm not instanceof Node
			throw new TypeError "Invalid container element."
		
		index = @childNodes.indexOf elm
		if index is -1 then return child
		
		if child.parentNode?
			child.parentNode.removeChild child
		
		@childNodes.splice index, 0, child
		child.parentNode = @
		child
	
	inspect: ->
		"[#{@constructor.name}]"
	
	removeAttribute: (key) ->
		delete @attributes[key]
	
	removeChild: (child) ->
		index = @childNodes.indexOf child
		if index is -1 then return child
		
		@childNodes.splice index, 1
		child.parentNode = null
		child
	
	setAttribute: (key, value) ->
		@attributes[key] = value

Object.defineProperties Node.prototype,
	firstChild:
		get: -> @childNodes[0]
	
	lastChild:
		get: -> @childNodes[@childNodes.length - 1]
	
	nextSibling:
		get: ->
			if not @parentNode? then return null
			index = @parentNode.childNodes.indexOf @
			if index is -1 then return null
			@parentNode.childNodes[index + 1]
	
	ownerDocument:
		get: -> @parentNode?.ownerDocument ? null
	
	previousSibling:
		get: ->
			if not @parentNode? then return null
			index = @parentNode.childNodes.indexOf @
			if index <= 0 then return null
			@parentNode.childNodes[index - 1]
		
	textContent:
		get: -> (child.textContent for child in @childNodes).join ''
		set: (value) ->
			@removeChild @childNodes[0] while @childNodes.length
			@appendChild new Text value

# --------

class Element extends Node
	attributes: null
	
	constructor: (name) ->
		super name
		
		@attributes = {}
	
	cloneNode: (deep) ->
		elm = super deep
		elm.attributes = __clone @attributes
		elm
	
	inspect: ->
		"[#{@constructor.name}#{if @id then " ##{@id}" else ""}]"
	
	querySelector: (selector) ->
		__querySelector @, selector
	
	querySelectorAll: (selector) ->
		__querySelectorAll @, selector

Object.defineProperties Element.prototype,
	className:
		get: -> @attributes['class'] ? ''
		set: (value) -> @attributes['class'] = value
	
	id:
		get: -> @attributes['id'] ? ''
		set: (value) -> @attributes['id'] = value

	innerHTML:
		get: -> (child.outerHTML for child in @childNodes).join ''
		set: (value) -> throw new Error "TODO"
			
	outerHTML:
		get: ->
			if isContainer @
				if @childNodes.length
					"<#{@tagName.toLowerCase()}#{__printAttributes @}>#{@innerHTML}</#{@tagName.toLowerCase()}>"
				else
					"<#{@tagName.toLowerCase()}#{__printAttributes @}></#{@tagName.toLowerCase()}>"
					
			else
				"<#{@tagName.toLowerCase()}#{__printAttributes @}>"
				
		set: (value) -> throw new Error "TODO"

# --------

class HTMLElement extends Element
	style: null
	
	constructor: (name) ->
		super name

		@style = {}
	
	cloneNode: (deep) ->
		elm = super deep
		elm.style = __clone @style
		elm

Object.defineProperties HTMLElement.prototype,
	offsetHeight:
		get: ->
			if 'none' is @ownerDocument.defaultView.getComputedStyle(@, null).getPropertyValue 'display' then return 0
			
			parseFloat @ownerDocument.defaultView.getComputedStyle(@, null).getPropertyValue 'height'
	
	offsetWidth:
		get: ->
			if 'none' is @ownerDocument.defaultView.getComputedStyle(@, null).getPropertyValue 'display' then return 0
			
			parseFloat @ownerDocument.defaultView.getComputedStyle(@, null).getPropertyValue 'width'

# --------

class HTMLBodyElement extends HTMLElement
	constructor: ->
		super 'body'

class HTMLHtmlElement extends HTMLElement
	constructor: ->
		super 'html'

Object.defineProperties HTMLHtmlElement.prototype,
	clientWidth:
		get: -> @ownerDocument.defaultView.innerWidth
	
	clientHeight:
		get: -> @ownerDocument.defaultView.innerHeight

# --------

class Text extends Node
	nodeType: 3
	
	constructor: (@nodeValue) ->
	
	cloneNode: ->
		new Text @nodeValue

Object.defineProperties Text.prototype,
	textContent:
		get: -> @nodeValue
		set: (value) -> @nodeValue = value
	
	outerHTML:
		get: -> @textContent
		set: (value) -> @textContent = value

# --------

class Document extends Node
	constructor: ->
		@documentElement = new HTMLHtmlElement
		Object.defineProperty @documentElement, 'ownerDocument', value: @
		
		@body = new HTMLBodyElement
		@documentElement.appendChild @body
	
	createElement: (name) ->
		new HTMLElement name
	
	createElementNS: (ns, name) ->
		elm = new HTMLElement name
		elm.namespaceURI = ns
		elm
	
	createTextNode: (text) ->
		new Text text
	
	querySelector: (selector) ->
		__querySelector @, selector
	
	querySelectorAll: (selector) ->
		__querySelectorAll @, selector

class Window
	innerWidth: 0
	innerHeight: 0
	
	constructor: ->
		@document = new Document
		
		Object.defineProperty @document, 'defaultView',
			value: @

	getComputedStyle: (elm) ->
		getPropertyValue: (key) ->
			elm.style[key]
	
	Event: Event
	CustomEvent: CustomEvent
	Document: Document
	Window: Window
	Node: Node
	Element: Element
	HTMLElement: HTMLElement
	
	setImmediate: setImmediate
	clearImmediate: clearImmediate

module.exports = Window
		
# Helpers

__normalizeCssKey = (key) ->
	key.replace /[A-Z]/g, (a) -> "-#{a.toLowerCase()}"

__printAttributes = (elm) ->
	attrs = ("#{key}=\"#{value.replace(/&/g, '&amp;').replace(/"/g, '&quot;')}\"" for key, value of elm.attributes)
	styles = ("#{__normalizeCssKey key}: #{value};" for key, value of elm.style)
	if styles.length then attrs.push "style=\"#{styles.join ' '}\""
	if attrs.length then attrs.unshift '' # to create indent
	attrs.join ' '

__clone = (obj) ->
	cloned = null
	
	if 'object' is typeof obj
		if Array.isArray obj
			cloned = (__clone item for item in obj)
			
		else
			cloned = {}
			cloned[key] = value for key, value of obj

	cloned

__querySelector = (elm, selector) ->
	__querySelectorAll(elm, selector)[0] ? null

__querySelectorAll = (elm, selector) ->
	document = if elm instanceof Document then elm else elm.ownerDocument

	if selector is 'body' then return [document?.body]
	if selector is 'html' then return [document?.documentElement]
	
	[]