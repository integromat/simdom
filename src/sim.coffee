###!
 * simDOM
 * http://simdom.org/

 * Released under the MIT license
 * http://simdom.org/license
###

do (window = window ? null) ->
	if window?.sim? then return # sim is already initialized
	
	NODE = not window?
	JQUERY = window?.jQuery?
	FF = navigator?.userAgent.toLowerCase().indexOf('firefox') > -1
	WHEEL_EVENT = `window ? "onwheel" in window.document.createElement("div") ? "wheel" : window.document.onmousewheel !== undefined ? "mousewheel" : "DOMMouseScroll" : "wheel"`
	TEMP_ID = 0
	TAGS = ['a', 'abbr', 'address', 'area', 'article', 'aside', 'audio', 'b', 'base', 'bdi', 'bdo', 'blockquote', 'body', 'br', 'button', 'canvas', 'caption', 'cite', 'code', 'col', 'colgroup', 'datalist', 'dd', 'del', 'details', 'dfn', 'dialog', 'div', 'dl', 'dt', 'em', 'embed', 'fieldset', 'figcaption', 'figure', 'footer', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header', 'hr', 'i', 'iframe', 'img', 'input', 'ins', 'kbd', 'keygen', 'label', 'legend', 'li', 'link', 'main', 'map', 'mark', 'menu', 'menuitem', 'meta', 'meter', 'nav', 'noscript', 'object', 'ol', 'optgroup', 'option', 'output', 'p', 'param', 'pre', 'progress', 'q', 'rp', 'rt', 'ruby', 's', 'samp', 'script', 'section', 'select', 'small', 'source', 'span', 'strong', 'style', 'sub', 'summary', 'sup', 'table', 'tbody', 'td', 'textarea',  'tfoot', 'th', 'thead', 'time', 'title', 'tr', 'track', 'u', 'ul', 'var', 'video', 'wbr']
	JQUERY_POLYFILLS = ['animate', 'stop', 'slideDown', 'slideUp', 'slideToggle', 'fadeIn', 'fadeOut', 'fadeToggle']
	READY_LISTENERS = []
	CSS_SHEET = null
	CSS_NUMBER = 'columnCount': true, 'fillOpacity': true, 'flexGrow': true, 'flexShrink': true, 'fontWeight': true, 'lineHeight': true, 'opacity': true, 'order': true, 'orphans': true, 'widows': true, 'zIndex': true, 'zoom': true
	COMPONENT = Object.create null
	HAS_COMPONENTS = false
	NAMESPACE = Object.create null
	EVENT_CONSTRUCTOR = resize: 'UIEvent', scroll: 'UIEvent'
	BOOTSTRAP_EVENT = /^[^\.]+\.bs\.[^\.]+$/
	ALTERNATIVE_EVENT_CONSTRUCTORS =
		'CustomEvent': (name, options) ->
			@initCustomEvent name, options.bubbles ? true, options.cancelable ? false, options.detail ? {}
		'UIEvent': (name, options) ->
			@initUIEvent name, options.bubbles ? true, options.cancelable ? false, window, 0
	
	# major methods
	
	sim = (selector) ->
		if not selector? then return null
		if selector instanceof SIMBase or selector instanceof SIMArray then return selector
		if selector.__sim__ instanceof SIMBase then return selector.__sim__
		if 'function' is typeof selector then return sim.ready selector
		if 'string' is typeof selector
			# only one possilbe result when #<id> is used as selector
			if selector in ['html', 'body'] or (/^#([a-z]+[_a-z0-9-]*)$/i).test selector
				return sim query window.document, selector
			
			else
				return simArray queryAll window.document, selector
		
		if Array.isArray selector then return new SIMArray selector
		if selector.nodeType is 3 then return new SIMText selector
		if selector.nodeType is 9 then return new SIMDocument selector
		if selector.nodeType is 1
			defaultKlass = NAMESPACE[selector.namespaceURI] ? SIMElement

			if HAS_COMPONENTS
				if selector.hasAttribute 'sim-component'
					return new (COMPONENT[selector.getAttribute 'sim-component'] ? defaultKlass) selector
				
				else if selector.hasAttribute 'data-sim-component'
					return new (COMPONENT[selector.getAttribute 'data-sim-component'] ? defaultKlass) selector
			
			return new defaultKlass selector
		
		if JQUERY and selector instanceof window.jQuery then return new SIMArray selector.toArray()
		if window.Window? and selector.constructor is window.Window then return new SIMWindow selector
		
		null
	
	###
	Ensures argument is SIMArray and if it isn't, it will create it.
	
	@param {*} array Array.
	@returns {SIMArray}
	###
	
	simArray = (array) ->
		if array instanceof SIMArray then return array

		new SIMArray array
	
	# browser or node?
	
	if NODE
		module.exports = sim
		window = require './dom'
		sim.window = window
		sim.require = (files, done) ->
			if 'string' is typeof files
				files = [files]
			
			next = ->
				file = require('path').resolve process.cwd(), files.shift()
				sim(window.document.body).script "[src=\"#{file}\"]", ->
					_error = (err) =>
						@off 'load', _load
						
						done? err
						
					_load = ->
						@off 'error', _error
						
						JQUERY = window?.jQuery?
						
						if files.length
							next()
						
						else
							done? null
						
					@once 'error', _error
					@once 'load', _load
				
			next()

	window.sim = sim
	window.document.addEventListener 'DOMContentLoaded', -> sim.ready()

	document = window.document
	setImmediate = window.setImmediate or (fn) -> setTimeout fn, 0
	clearImmediate = window.clearImmediate or (fn) -> clearTimeout fn
	
	# helpers
	
	query = (dom, selector) ->
		queryDo 'querySelector', dom, selector
	
	queryAll = (dom, selector) ->
		Array::slice.call queryDo 'querySelectorAll', dom, selector
	
	queryDo = (method, dom, selector) ->
		tempId = false
		
		selector = selector.replace (/@([a-z]+[_a-z0-9-]*)/gi), (a, b) ->
			"[sim-component=\"#{b}\"]"
		
		if ':scope ' is selector.substr 0, 7
			if not dom.hasAttribute 'id'
				tempId = true
				dom.setAttribute 'id', "sim-temp-id-#{TEMP_ID++}"
	
			selector = "##{dom.getAttribute 'id'} #{selector.substr 7}"
		
		res = dom[method] selector
		
		if tempId
			dom.removeAttribute 'id'
		
		res
	
	check = (value, types...) ->
		for type in types
			valid = switch type
				when String then 'string' is typeof value
				when Number then 'number' is typeof value
				when Boolean then 'boolean' is typeof value
				when Function then 'function' is typeof value
				else value instanceof type
			
			if valid then return true
		
		throw new Error "Type '#{type.name}' expeceted."
	
	parse = (selectors) ->
		conditions = []
		
		if 'string' is typeof selectors and selectors.length
			condition = null
			parsing = null
			buffer = ''
			cursor = -1
			length = selectors.length
			instr = false
			inarg = false
			
			next = (type) ->
				buffer = buffer.trim()
				if buffer.length
					switch parsing
						when 'tag' then condition.tag = buffer
						when 'id' then condition.id = buffer
						when 'class' then condition.class.push buffer
						when 'component' then condition.attribute.push name: 'sim-component', operator: '=', value: buffer
						when 'attr'
							match = buffer.match(/^([_a-z0-9-]+)(?:=(.*))?\]$/i)
							if match then condition.attribute.push name: match[1], operator: '=', value: match[2]
							
						when 'pseudo'
							match = buffer.match(/^([-a-z]+)(?:\((.*))?$/i)
							if match then condition.pseudo.push name: match[1], conditions: parse match[2]

				buffer = ''
				parsing = type
			
			cond = ->
				next 'tag'
				condition =
					id: null
					tag: null
					'class': []
					attribute: []
					pseudo: []
				
				conditions.push condition
			
			cond()
			
			while ++cursor < length
				chr = selectors.charAt cursor
				if instr
					if chr is '"'
						instr = false
					else
						buffer += chr
					
					continue
				
				else if inarg
					if chr is ')'
						inarg = false
					
					else
						buffer += chr
					
					continue
				
				switch chr
					when '.' then next 'class'
					when '#' then next 'id'
					when '[' then next 'attr'
					when ':' then next 'pseudo'
					when '@' then next 'component'
					when '('
						if parsing is 'pseudo'
							buffer += chr
							inarg = true
						
						else
							parsing = null # invalid character, skip
						
					when '"'
						if parsing is 'attr'
							instr = true

						else
							parsing = null # invalid character, skip
					
					when ','
						cond()
					
					else
						buffer += chr
					
			next null

		#console.log require('util').inspect conditions[0], depth: null
		
		conditions
	
	matches = (elm, conditions, index = 0) ->
		if conditions.length is 0
			return true
		
		# text cant match any of following
		if elm instanceof SIMText
			return false
		
		for condition in conditions
			if condition.tag?
				if condition.tag is '*'
					if elm not instanceof SIMElement then continue
				
				else
					if elm.prop('tagName').toLowerCase() isnt condition.tag then continue
			
			if condition.id? and elm.attr('id') isnt condition.id then continue
				
			if condition['class'].length
				fulfilled = true
				for name in condition['class'] when not elm.hasClass name
					fulfilled = false
					break
				
				if not fulfilled then continue
			
			if condition.attribute.length
				fulfilled = true
				for attr in condition.attribute
					if attr.value?
						if attr.value isnt elm.attr attr.name
							fulfilled = false
							break
					
					else
						# only check attribute existence
						if not elm.__dom.hasAttribute attr.name
							fulfilled = false
							break
				
				if not fulfilled then continue
			
			if condition.pseudo.length
				fulfilled = true
				for ps in condition.pseudo
					switch ps.name
						when 'visible'
							if elm.__dom.offsetWidth is 0 or elm.__dom.offsetHeight is 0
								fulfilled = false
								break
								
						when 'disabled'
							if elm.__dom.disabled isnt true
								fulfilled = false
								break
								
						when 'focus'
							if elm.__dom.ownerDocument.activeElement isnt elm.__dom
								fulfilled = false
								break
								
						when 'first-child', 'first'
							if elm.__dom.parentNode?.firstChild isnt elm.__dom
								fulfilled = false
								break
								
						when 'last-child', 'last'
							if elm.__dom.parentNode?.lastChild isnt elm.__dom
								fulfilled = false
								break
								
						when 'checked'
							if elm.__dom.checked isnt true
								fulfilled = false
								break
							
						when 'odd'
							if index % 2 is 1
								fulfilled = false
								break
								
						when 'even'
							if index % 2 is 0
								fulfilled = false
								break
								
						when 'not'
							if matches elm, ps.conditions
								fulfilled = false
								break
								
				if not fulfilled then continue
			
			return true
		
		false
	
	normalizeCssKey = (key) ->
		key.replace /\-(.)/g, (a, b) -> b.toUpperCase()
	
	normalizeCssValue = (key, value) ->
		if 'number' is typeof value and not CSS_NUMBER[key]
			"#{value}px"
		
		else
			value
	
	sanitize = (text) ->
		text.replace(/>/g, '&gt;').replace(/</g, '&lt;').replace(/"/g, '&quot;')
	
	filter = (array, selectors) ->
		arr = new SIMArray
		if not selectors?
			arr.push item for item in array when item not instanceof SIMText
			return arr
		
		if 'function' is typeof selectors
			for item, index in array when item not instanceof SIMText
				if selectors.call item, item, index, array
					arr.push item
				
			return arr
		
		conditions = parse selectors
		arr.push item for item, index in array when item not instanceof SIMText and matches item, conditions, index
		arr
	
	# classes
	
	class SIMArray
		length: 0
		
		constructor: (elms) ->
			if elms instanceof SIMElement or elms instanceof SIMText
				@push elms
			
			else if elms instanceof SIMArray or Array.isArray elms
				for elm in elms
					e = sim elm
					if e then @push e
			
			else
				e = sim elms
				if e then @push e
		
		addClass: ->
			elm.addClass arguments... for elm in @
			@
		
		appendTo: ->
			elm.appendTo arguments... for elm in @
			@
		
		attr: (key, value) ->
			if arguments.length is 1
				@first()?.attr key
	
			else
				elm.attr key, value for elm in @
				@
		
		after: ->
			elm.after arguments... for elm in @
			@
		
		append: ->
			elm.append arguments... for elm in @
			@
		
		blur: ->
			@first()?.blur()
			@
		
		css: (key, value) ->
			if 'object' is typeof key
				elm.css key for elm in @
				@
			
			else if arguments.length is 1
				@first()?.css key
	
			else
				elm.css key, value for elm in @
				@
		
		children: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.children arguments...
			
			arr
		
		clone: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.clone arguments...
			
			arr
		
		data: (key, value) ->
			if arguments.length < 2
				@first()?.data key
	
			else
				elm.data key, value for elm in @
				@
		
		detach: ->
			elm.detach() for elm in @
			@
		
		do: (method) ->
			method.call elm for elm in @
			@
		
		each: (method) ->
			method.call item, index, item for item, index in @
			@
		
		emit: ->
			elm.emit arguments... for elm in @
			@
		
		empty: ->
			elm.empty() for elm in @
			@
		
		filter: (selectors) ->
			if not selectors? then return new SIMArray
			
			filter @, selectors
		
		find: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.find arguments...
			
			arr
		
		first: ->
			@[0]
		
		focus: ->
			@first()?.focus()
			@
		
		hasClass: (name) ->
			for elm in @
				if elm.hasClass name then return true
			
			false
		
		height: (value) ->
			if arguments.length
				elm.height value for elm in @
				@
				
			else
				@first()?.height() ? 0
		
		hide: ->
			elm.hide arguments... for elm in @
			@
		
		html: (value) ->
			if arguments.length
				elm.html value for elm in @
				@
				
			else
				@first()?.html() ? ''
		
		indexOf: Array::indexOf
		
		insertAfter: ->
			elm.insertAfter arguments... for elm in @
			@
		
		insertBefore: ->
			elm.insertBefore arguments... for elm in @
			@
		
		inspect: ->
			"[SIMArray #{(elm.inspect() for elm in @).join ', '}]"
		
		last: ->
			@[@length - 1]
		
		map: (method) ->
			method item for item in @
		
		next: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.next arguments...
			
			arr
		
		nextAll: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.nextAll arguments...
			
			arr
		
		not: (selectors) ->
			arr = new SIMArray
			if not selectors?
				arr.push item for item in @
				return arr
			
			conditions = parse selectors
			arr.push item for item, index in @ when not matches item, conditions, index
			arr
		
		off: ->
			elm.off arguments... for elm in @
			@
		
		on: ->
			elm.on arguments... for elm in @
			@
		
		once: ->
			elm.once arguments... for elm in @
			@
		
		outerHeight: (margin) ->
			@first()?.outerHeight(margin) ? 0
		
		outerWidth: (margin) ->
			@first()?.outerWidth(margin) ? 0
		
		parent: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.parent arguments...
			
			arr
		
		push: (elm) ->
			if not elm? then return @
			check elm, SIMElement, SIMText, SIMArray
			
			if elm instanceof SIMArray
				@push e for e in elm
				return @
				
			Array::push.call @, elm
			
			@
		
		prependTo: ->
			elm.prependTo arguments... for elm in @
			@
		
		prev: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.prev arguments...
			
			arr
		
		prevAll: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.prevAll arguments...
			
			arr
		
		prop: (key, value) ->
			if arguments.length is 1
				@first()?.prop key
	
			else
				elm.prop key, value for elm in @
				@
		
		remove: ->
			elm.remove() for elm in @
			@
		
		removeClass: ->
			elm.removeClass arguments... for elm in @
			@
		
		reverse: Array::reverse
		shift: Array::shift
		
		show: ->
			elm.show arguments... for elm in @
			@
		
		slice: (begin, end) ->
			arr = new SIMArray
			len = @length
			
			start = begin or 0
			start = if start >= 0 then start else Math.max 0, len + start
			
			upto = if 'number' is typeof end then Math.min(end, len) else len
			if end < 0 then upto = len + end
			
			size = upto - start
			if size > 0
				for i in [0...size]
					arr.push @[start + i]
			
			arr
		
		sort: ->
			new SIMArray Array::sort.apply @, arguments
		
		splice: ->
			@
		
		text: (value) ->
			if arguments.length
				elm.text value for elm in @
				@
				
			else
				@first()?.text() ? ''
		
		toArray: ->
			(elm for elm in @)
		
		toggleClass: ->
			elm.toggleClass arguments... for elm in @
			@
		
		toString: ->
			(elm.toString() for elm in @).join ''
		
		trigger: ->
			elm.trigger arguments... for elm in @
			@
		
		val: (value) ->
			if arguments.length
				elm.val value for elm in @
				@
				
			else
				@first()?.val() ? null
		
		width: (value) ->
			if arguments.length
				elm.width value for elm in @
				@
				
			else
				@first()?.width() ? 0
	
	class SIMBase
		constructor: (dom) ->
			Object.defineProperty @, '__dom',
				value: dom
	
			Object.defineProperty @, '__handlers',
				value: Object.create null
	
			Object.defineProperty @, '__data',
				value: Object.create null
			
			try
				Object.defineProperty dom, '__sim__',
					value: @
				
			catch ex
				# this fail sometimes on firefox for unknown reason
	
	Object.defineProperties SIMBase.prototype,
		nodeType:
			get: -> @__dom.nodeType
	
	class SIMElement extends SIMBase
		###
		@param {String|SIMElement} tag
		@param {SIMElement} [parent]
		@param {String} [props]
		@param {Function} [next]
		###
		
		constructor: (tag, parent, props, next) ->
			if 'function' is typeof props
				next = props
				props = undefined
			
			if 'string' is typeof parent
				props = parent
				parent = null
			
			if parent?
				check parent, SIMElement
	
			# resolve tag
	
			if tag instanceof SIMElement
				super tag.__dom
			
			else if JQUERY and tag instanceof window.jQuery
				super tag[0]
			
			else if tag.nodeName
				super tag
			
			else if 'string' is typeof tag
				if @constructor.NS?
					super window.document.createElementNS @constructor.NS, tag
				else
					super window.document.createElement tag
			
			else
				throw new Error "Invalid arguments."
			
			# parse properties
	
			if 'string' is typeof props
				props = parse(props)[0]
				
				if props.id? then @attr 'id', props.id
				if props.class? then @addClass klass for klass in props.class
				if props.attribute? then @attr attr.name, attr.value for attr in props.attribute
			
			# attach to parent
			
			if parent?
				@appendTo parent
			
			next?.call @
		
		addClass: (names) ->
			if 'string' isnt typeof names then return @
			classes = if @__dom.className.length is 0 then [] else @__dom.className.split ' '
			
			for name in names.split ' '
				if name not in classes
					classes.push name
	
			@__dom.className = classes.join ' '
			@
		
		after: (children) ->
			children = simArray(children).reverse()
			for child in children
				@__dom.parentNode.insertBefore child.__dom, @__dom.nextSibling
				
			@
		
		append: (children) ->
			children = simArray children
			for child in children
				@__dom.appendChild child.__dom
			
			@
		
		attr: (key, value) ->
			if arguments.length is 1
				@__dom.getAttribute key
	
			else
				if value?
					if key in ['disabled', 'checked'] and value in [true, false]
						if value
							@__dom.setAttribute key, key
						
						else
							@__dom.removeAttribute key
						
					else
						@__dom.setAttribute key, value
				
				else
					@__dom.removeAttribute key
				
				@
		
		appendTo: (parent) ->
			parent = sim parent
			parent.append @
			@
		
		before: (children) ->
			children = simArray children
			for child in children
				@__dom.parentNode?.insertBefore child.__dom, @__dom
	
			@
		
		blur: ->
			@__dom.blur()
			@
		
		css: (key, value) ->
			if 'object' is typeof key
				styles = key
			
			else if arguments.length > 1
				styles = {}
				styles[key] = value
			
			if not styles?
				if @__dom.ownerDocument.body.contains @__dom
					# do not use normalized css key for getComputedStyle
					@__dom.ownerDocument.defaultView.getComputedStyle(@__dom, null).getPropertyValue key
				
				else
					key = normalizeCssKey key
					
					@__dom.style[key]
	
			else
				for key, value of styles
					key = normalizeCssKey key
					value = normalizeCssValue key, value
					
					if value?
						@__dom.style[key] = value
					
					else
						delete @__dom.style[key]
					
				@
		
		closest: (selector) ->
			conditions = parse selector
			parent = SIMElement::parent.call @
			if not parent then return null
			
			while not matches parent, conditions
				parent = SIMElement::parent.call parent
				if not parent? then return null
			
			parent
		
		contains: (descendants) ->
			descendants = simArray descendants
			if descendants.length is 0 then return false

			for descendant in descendants
				if descendant is @ then return false
				if not @__dom.contains descendant.__dom then return false
			
			true

		contents: ->
			simArray Array::slice.call @__dom.childNodes
		
		clone: (withDataAndEvents) ->
			elm = sim @__dom.cloneNode true
			
			if withDataAndEvents
				for event, o of @__handlers
					for fn in o.original ? []
						elm.on event, fn
				
					for selector, oo of o.selector
						for fn in oo.original ? []
							elm.on event, selector, fn
			
			elm
		
		data: (key, value) ->
			if arguments.length is 0
				obj = {}
				for attr in @__dom.attributes when (/^data-(.*)$/).exec attr.name
					obj[RegExp.$1] = attr.value
				
				for key, value of @__data
					obj[key] = value
				
				obj
			
			else if arguments.length is 1
				if @__data[key]?
					return @__data[key]
				
				@__dom.getAttribute "data-#{key}"
	
			else
				if 'object' is typeof value
					if @__dom.hasAttribute "data-#{key}"
						@__dom.removeAttribute "data-#{key}"
					
					@__data[key] = value
					
				else
					@__data[key] = value
					@__dom.setAttribute "data-#{key}", value
					
				@
	
		detach: ->
			@remove arguments...
		
		do: (method) ->
			method.call @
			@
		
		###
		@param {String} name Event name.
		@param {Object} [options] Event options.
		
		**Options:**
		- `bubbles` - Is a Boolean indicating whether the event bubbles up through the DOM or not.
		- `cancelable` - Is a Boolean indicating whether the event is cancelable.
		- `detail` - Event detail.
		###
		
		emit: (name, options = {}) ->
			if FF and @__dom.disabled
				return # https://bugzilla.mozilla.org/show_bug.cgi?id=889376
			
			if BOOTSTRAP_EVENT.test name
				jq = @toJquery()
				jq.trigger.apply jq, arguments
				
			else
				if 'string' is typeof name
					klass = EVENT_CONSTRUCTOR[name] ? 'CustomEvent'
					try
						event = new window[klass] name, options
					catch
						event = (@__dom.ownerDocument ? @__dom.document).createEvent klass
						ALTERNATIVE_EVENT_CONSTRUCTORS[klass].call event, name, options
				
				else
					throw new Error "Invalid arguments."
				
				@__dom.dispatchEvent event
			
			@
		
		empty: ->
			while @__dom.hasChildNodes()
				@__dom.removeChild @__dom.lastChild
			
			@
		
		find: (selector) ->
			if not selector? then return new SIMArray
			
			if 'string' is typeof selector
				return simArray queryAll @__dom, selector
			
			else
				throw new Error "Invalid arguments."
		
		findOne: (selector) ->
			if not selector? then return null
			
			sim query @__dom, selector
		
		focus: ->
			@__dom.focus()
			@
		
		hasClass: (names) ->
			if @__dom.className.length is 0
				return false
			
			classes = @__dom.className.split ' '
			for name in names.split ' '
				if name not in classes then return false
	
			true
		
		height: (value) ->
			if arguments.length
				@css 'height', if 'string' is typeof value then value else "#{value}px"
				@
				
			else
				if @is ':visible'
					@__dom.offsetHeight
				
				else
					h = parseFloat @css 'height'
					if isNaN h then return 0
					h
		
		hide: ->
			@css 'display', 'none'
		
		html: (value) ->
			if arguments.length
				@__dom.innerHTML = value
				@
	
			else
				@__dom.innerHTML
		
		children: (selector) ->
			filter simArray(Array::slice.call(@__dom.childNodes)), selector
		
		insertAfter: (elms) ->
			elms = simArray elms
			for elm in elms
				SIMElement::after.call elm, @

			@
		
		insertBefore: (elms) ->
			elms = simArray elms
			for elm in elms
				SIMElement::before.call elm, @

			@
		
		inspect: ->
			"[SIMElement #{@__dom.nodeName.toLowerCase()}#{if @__dom.id then "##{@__dom.id}" else ""}]"
		
		is: (selector) ->
			matches @, parse selector
		
		next: (selector) ->
			elm = sim @__dom.nextSibling
			if not elm? then return null
			
			if selector?
				if not matches elm, parse selector
					return null
			
			elm
		
		nextAll: (selector) ->
			if not @__dom.parentNode then return simArray()
			index = Array::indexOf.call @__dom.parentNode.childNodes, @__dom
			if index is -1 then return simArray()
			filter simArray(Array::slice.call(@__dom.parentNode.childNodes, index + 1)), selector
		
		off: (events, selector, handler) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined
			
			fn = handler
			events ?= Object.keys(@__handlers).join ' '
			
			for event in events.split ' '
				if FF
					if event is 'focusin'
						event = 'focus'
					
					else if event is 'focusout'
						event = 'blur'
				
				if event in ['wheel', 'mousewheel']
					event = WHEEL_EVENT
			
				if selector
					index = @__handlers[event]?.selector[selector]?.original.indexOf handler
					if not index? or index is -1
						return @ # handler doesn't exist
					
					fn = @__handlers[event].selector[selector].temporary[index]
					
					@__handlers[event].selector[selector].original.splice index, 1
					@__handlers[event].selector[selector].temporary.splice index, 1
				
				else
					index = @__handlers[event]?.original.indexOf handler
					if not index? or index is -1
						return @ # handler doesn't exist
					
					fn = @__handlers[event].temporary[index]
					
					@__handlers[event].original.splice index, 1
					@__handlers[event].temporary.splice index, 1
				
				if BOOTSTRAP_EVENT.test event
					@toJquery().off event, fn
					
				else
					@__dom.removeEventListener event, fn

			@
		
		offset: ->
			bounds = @__dom.getBoundingClientRect()
			
			left: bounds.left + @__dom.ownerDocument.defaultView.pageXOffset
			top: bounds.top + @__dom.ownerDocument.defaultView.pageYOffset
		
		###
		@param {String} events Space separated list of event to handle.
		@param {String} [selector] Optional target selector.
		@param {Function} handler Event handler.
		###
		
		on: (events, selector, handler, _once) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined
			
			if 'function' isnt typeof handler
				throw new Error "Invalid arguments."
			
			self = @
			jqevt = false
			capture = undefined
			
			for event in events.split ' '
				if FF
					if event is 'focusin'
						event = 'focus'
						capture = true
					
					else if event is 'focusout'
						event = 'blur'
						capture = true
				
				if event in ['wheel', 'mousewheel']
					event = WHEEL_EVENT
				
				@__handlers[event] ?= original: [], temporary: [], selector: Object.create null
				
				if selector
					index = @__handlers[event].selector[selector]?.original.indexOf handler
					if index? and index isnt -1
						return @ # handler already exists
						
					fn = (e) ->
						if _once
							eventType = if jqevt then "#{e.type}#{if e.namespace then ".#{e.namespace}" else ''}" else e.type
							SIMElement::off.call self, eventType, selector, handler
							
						target = sim e.target
						if target.is selector
							ret = handler.apply target, arguments
							if ret is false then e.preventDefault?()
							return ret
						
						closest = target.closest selector
						if closest
							ret = handler.apply closest, arguments
							if ret is false then e.preventDefault?()
							return ret
						
						null
					
					@__handlers[event].selector[selector] ?= original: [], temporary: []
					@__handlers[event].selector[selector].original.push handler
					@__handlers[event].selector[selector].temporary.push fn
				
				else
					index = @__handlers[event].original.indexOf handler
					if index? and index isnt -1
						return @ # handler already exists
					
					fn = (e) ->
						if _once
							eventType = if jqevt then "#{e.type}#{if e.namespace then ".#{e.namespace}" else ''}" else e.type
							SIMElement::off.call self, eventType, selector, handler
						
						if e.type is 'DOMMouseScroll'
							e.wheelDelta = e.detail * -20
						
						ret = handler.call self, e
						if ret is false then e.preventDefault?()
						return ret
					
					@__handlers[event].original.push handler
					@__handlers[event].temporary.push fn
				
				if BOOTSTRAP_EVENT.test event
					jqevt = true
					@toJquery().on event, fn
					
				else
					@__dom.addEventListener event, fn, capture
	
			@
		
		once: (event, selector, handler) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined

			SIMElement::on.call @, event, selector, handler, true
			@
		
		outerHeight: (margin) ->
			add = 0
			if margin
				m = parseFloat @css 'margin-top'
				if not isNaN m then add += m
				m = parseFloat @css 'margin-bottom'
				if not isNaN m then add += m
			
			SIMElement::height.call(@) + add
		
		outerWidth: (margin) ->
			add = 0
			if margin
				m = parseFloat @css 'margin-left'
				if not isNaN m then add += m
				m = parseFloat @css 'margin-right'
				if not isNaN m then add += m
				
			SIMElement::width.call(@) + add
		
		parent: ->
			if @__dom.parentNode is @__dom.ownerDocument
				return null
	
			sim @__dom.parentNode
		
		prepend: (children) ->
			children = simArray(children).reverse()
			for child in children
				if @__dom.hasChildNodes()
					@__dom.insertBefore child.__dom, @__dom.firstChild
				
				else
					@__dom.appendChild child.__dom
			
			@
		
		prependTo: (parent) ->
			parent = sim parent
			SIMElement::prepend.call parent, @
			@
		
		prev: (selector) ->
			elm = sim @__dom.previousSibling
			if not elm? then return null
	
			if selector?
				if not matches elm, parse selector
					return null
			
			elm
		
		prevAll: (selector) ->
			if not @__dom.parentNode then return simArray()
			index = Array::indexOf.call @__dom.parentNode.childNodes, @__dom
			if index <= 0 then return simArray()
			filter simArray(Array::slice.call(@__dom.parentNode.childNodes, 0, index)), selector
		
		prop: (key, value) ->
			if arguments.length is 1
				@__dom[key]
	
			else
				if key in ['disabled', 'selected', 'checked']
					if value
						@__dom.setAttribute key, key
					else
						@__dom.removeAttribute key
					
				@__dom[key] = value
				@
		
		remove: (child) ->
			if not child?
				@__dom.parentNode?.removeChild @__dom
				return @
				
			child = sim child
			@__dom.removeChild child.__dom
			@
		
		removeClass: (names) ->
			if @__dom.className.length is 0
				return @
			
			classes = @__dom.className.split ' '
			for name in names.split ' '
				index = classes.indexOf name
				if index isnt -1 then classes.splice index, 1
				if classes.length is 0
					# to save some pointless loops
					@__dom.className = classes.join ' '
					return @
			
			@__dom.className = classes.join ' '
			@
		
		replaceWith: (children) ->
			children = simArray children

			for child in children
				@__dom.parentNode?.insertBefore child.__dom, @__dom
			
			@__dom.parentNode?.removeChild @__dom
			@
		
		scrollLeft: ->
			@__dom.scrollLeft

		scrollTop: ->
			@__dom.scrollTop

		show: ->
			SIMElement::css.call @, 'display', 'block'
		
		text: (value) ->
			if arguments.length
				@__dom.textContent = value
				@
	
			else
				@__dom.textContent
		
		toggleClass: (names) ->
			for name in names.split ' '
				if @hasClass name
					@removeClass name
				
				else
					@addClass name
			
			@
		
		toString: ->
			@__dom.outerHTML
		
		trigger: ->
			SIMElement::emit.apply @, arguments
		
		val: (value) ->
			if arguments.length
				@__dom.value = value ? ''
				@
	
			else
				@__dom.value
		
		width: (value) ->
			if arguments.length
				@css 'width', if 'string' is typeof value then value else "#{value}px"
				@
				
			else
				if @is ':visible'
					@__dom.offsetWidth
				
				else
					w = parseFloat @css 'width'
					if isNaN w then return 0
					w
			
		write: (text) ->
			if (/&#?([a-z0-9]+);/gi).test text
				text = sim.div().html(sanitize text).text()
			
			SIMElement::append.call @, new SIMText text
	
	Object.defineProperties SIMElement.prototype,
		enabled:
			get: -> not @is ':disabled'
			set: (value) -> @prop 'disabled', not value
		
		checked:
			get: -> @is ':checked'
			set: (value) -> @prop 'checked', value
	
		value:
			get: -> @val()
			set: (value) -> @val value
		
		visible:
			get: -> @is ':visible'
			set: (value) -> @[if value then 'show' else 'hide']()
	
	class SIMText extends SIMBase
		constructor: (text) ->
			if not text?
				super window.document.createTextNode ''
			
			else if 'string' is typeof text
				super window.document.createTextNode text
			
			else if text.nodeType is 3
				super text
			
			else
				throw new Error "Invalid arguments."
		
		after: SIMElement::after
		appendTo: SIMElement::appendTo
		before: SIMElement::before
		closest: -> null
		detach: SIMElement::detach
		hasClass: -> false
		prependTo: SIMElement::prependTo
		insertBefore: SIMElement::insertBefore
		insertAfter: SIMElement::insertAfter
		inspect: -> "[SIMText '#{@__dom.textContent}']"
		is: -> false
		next: SIMElement::next
		nextAll: SIMElement::nextAll
		parent: SIMElement::parent
		prev: SIMElement::prev
		prevAll: SIMElement::prevAll
		remove: SIMElement::remove
		text: SIMElement::text
	
	class SIMDocument extends SIMBase
		closest: -> null
		emit: SIMElement::emit
		height: -> window.document.documentElement.offsetHeight
		inspect: -> "[SIMDocument]"
		is: (selector) -> selector is 'document'
		on: SIMElement::on
		once: SIMElement::once
		off: SIMElement::off
		toString: -> "<!DOCTYPE html>#{@__dom.documentElement.outerHTML}"
		trigger: SIMElement::trigger
		width: -> window.document.documentElement.offsetWidth
	
	class SIMWindow extends SIMBase
		closest: -> null
		emit: SIMElement::emit
		height: -> window.document.documentElement.clientHeight
		inspect: -> "[SIMWindow]"
		is: -> false
		on: SIMElement::on
		once: SIMElement::once
		off: SIMElement::off
		open: -> window.open arguments...
		scrollLeft: -> @__dom.pageXOffset
		scrollTop: -> @__dom.pageYOffset
		toString: -> @inspect()
		trigger: SIMElement::trigger
		width: -> window.document.documentElement.clientWidth
	
	Object.defineProperties SIMWindow.prototype,
		devicePixelRatio:
			get: -> @__dom.devicePixelRatio ? 1

		document:
			get: -> sim window.document

		history:
			get: -> window.history
		
		location:
			get: -> window.location
			set: (value) -> window.location = value

	sim.create = (tag, parent, props) ->
		klass = if @prototype instanceof SIMElement then @ else SIMElement
		
		if HAS_COMPONENTS and (/@([-a-z0-9_]+)/i).exec props
			new (COMPONENT[RegExp.$1] ? klass) arguments...
		
		else
			new klass arguments...

	sim.one = ->
		res = sim arguments...
		if res instanceof SIMArray then res = res.first()
		res
	
	sim.array = (args...) ->
		if args.length is 0 then return new SIMArray
		if args.length is 1 then return new SIMArray args[0]
		new SIMArray args
	
	sim.html = sim.create.bind SIMElement, 'html', null
	sim.text = (text) -> new SIMText text
	sim.ready = (handler) ->
		if arguments.length is 0
			if sim.isReady then return
			sim.isReady = true
			
			listener() for listener in READY_LISTENERS
			READY_LISTENERS = null
			return
			
		if sim.isReady
			return setImmediate handler
		
		READY_LISTENERS.push handler
		@
	
	sim.registerComponent = (name, klass, init = false) ->
		if klass.prototype not instanceof SIMElement
			throw new Error "Invalid arguments."
		
		COMPONENT[name] = klass
		HAS_COMPONENTS = true
		
		if init then sim("[sim-component=\"#{name}\"]")
		
		@
	
	sim.registerNamespace = (name, klass) ->
		if klass.prototype not instanceof SIMElement
			throw new Error "Invalid arguments."
			
		NAMESPACE[name] = klass
		@
	
	sim.css = (name, style) ->
		if not CSS_SHEET?
			elm = window.document.createElement 'style'
			window.document.head.appendChild elm
			CSS_SHEET = elm.sheet

		CSS_SHEET.insertRule "#{name} {#{("#{key}: #{value}" for key, value of style).join '; '}}", 0
		
		null
	
	sim.cookies =
		get: (name) ->
			name += "="
			ca = window.document.cookie.split ';'
			
			for c in ca
				while ' ' is c.charAt 0
					c = c.substring 1, c.length
					
				if 0 is c.indexOf name then return c.substring name.length, c.length

			null
		
		set: (name, value, minutes) ->
			if not value?
				value = ""
				minutes = -1
			
			if minutes
				date = new Date()
				date.setTime date.getTime() + minutes * 60 * 1000
				expires = "; expires=#{date.toGMTString()}"
			
			else
				expires = ""
			
			window.document.cookie = "#{name}=#{value}#{expires}; path=/"
	
	sim.parse = (html) ->
		wrapper = window.document.createElement 'div'
		wrapper.innerHTML = html
		sim.array.apply sim, wrapper.childNodes
	
	sim.render = (next) ->
		container = sim.div()
		next.call container
		container.html()
	
	sim.SIMElement = SIMElement
	sim.SIMArray = SIMArray
	sim.SIMDocument = SIMDocument
	sim.SIMWindow = SIMWindow
	sim.SIMText = SIMText

	do ->
		for tag in TAGS
			if not sim.hasOwnProperty tag
				sim[tag] = sim.create.bind SIMElement, tag, null
			
			do (tag) ->
				if not SIMElement::hasOwnProperty tag
					Object.defineProperty SIMElement.prototype, tag,
						enumerable: false
						configurable: true
						writable: true
						value: -> sim.create.call SIMElement, tag, @, arguments...
		
		# jQuery integration
		
		if JQUERY
			sim.ajax = window.jQuery.ajax.bind jQuery
			
		for name in JQUERY_POLYFILLS
			do (name) ->
				SIMElement::[name] = ->
					if not JQUERY?
						throw new Error "jQuery is required in order to use '#{name}' method."
					
					@toJquery()[name] arguments...
				
				SIMArray::[name] = ->
					if not JQUERY?
						throw new Error "jQuery is required in order to use '#{name}' method."
					
					@toJquery()[name] arguments...
		
		SIMBase::toJquery = ->
			if not JQUERY
				throw new Error "jQuery is required in order to use 'toJquery' method."
			
			window.jQuery @__dom
		
		SIMArray::toJquery = ->
			if not JQUERY
				throw new Error "jQuery is required in order to use 'toJquery' method."
			
			window.jQuery (elm.__dom for elm in @)
	
	if NODE
		require('./mock') sim
