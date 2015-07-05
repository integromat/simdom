###!
 * simDOM
 * http://simdom.org/

 * Released under the MIT license
 * http://simdom.org/license
###

do (window = window ? null) ->
	NODE = not window?
	TEMP_ID = 0
	TAGS = ['a', 'article', 'aside', 'b', 'blockquote', 'body', 'button', 'br', 'canvas', 'dd', 'div', 'dl', 'dt', 'em', 'footer', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header', 'hr', 'input', 'i', 'img', 'label', 'legend', 'li', 'nav', 'ol', 'optgroup', 'option', 'p', 'pre', 'section', 'select', 'small', 'span', 'strong', 'textarea', 'table', 'title', 'tr', 'th', 'td', 'ul']
	SVG_TAGS = ['defs', 'g', 'linearGradient', 'path', 'radialGradient', 'stop', 'svg']
	JQUERY_POLYFILLS = ['animate', 'stop', 'slideDown', 'slideUp', 'slideToggle', 'fadeIn', 'fadeOut', 'fadeToggle', 'scrollTop', 'scrollLeft']
	READY_LISTENERS = []
	EVENT_CONSTRUCTOR = resize: 'UIEvent', scroll: 'UIEvent', click: 'MouseEvent'
	CSS_NUMBER = 'columnCount': true, 'fillOpacity': true, 'flexGrow': true, 'flexShrink': true, 'fontWeight': true, 'lineHeight': true, 'opacity': true, 'order': true, 'orphans': true, 'widows': true, 'zIndex': true, 'zoom': true
	COMPONENT = Object.create null
	HAS_COMPONENTS = false
	
	# major methods
	
	sim = (selector) ->
		if not selector? then return null
		if selector instanceof SIMBase or selector instanceof SIMArray then return selector
		if selector.__sim__ instanceof SIMBase then return selector.__sim__
		if 'function' is typeof selector then return sim.ready selector
		if 'string' is typeof selector
			# only one possilbe result when # is used in selector
			if selector in ['html', 'body'] or (/#([a-zA-Z]+[_a-zA-Z0-9-]*)/).test selector
				return sim query document, selector
			
			else
				return simArray queryAll document, selector
		
		if Array.isArray selector then return new SIMArray selector
		if selector.nodeType is 3 then return new SIMText selector
		if selector.nodeType is 9 then return new SIMDocument selector
		if selector.nodeType is 1
			defaultKlass = if selector.namespaceURI is SIMSVGElement.URI then SIMSVGElement else SIMElement

			if HAS_COMPONENTS
				if selector.hasAttribute 'sim-component'
					return new (COMPONENT[selector.getAttribute 'sim-component'] ? defaultKlass) selector
				
				else if selector.hasAttribute 'data-sim-component'
					return new (COMPONENT[selector.getAttribute 'data-sim-component'] ? defaultKlass) selector
			
			return new defaultKlass selector
		
		if window.jQuery? and selector instanceof window.jQuery then return new SIMArray selector.toArray()
		if window.Window? and selector instanceof window.Window then return new SIMWindow selector
		
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
		window = new (require './dom')
		module.exports = sim
		sim.isReady = true
		sim.destroy = -> window = new (require './dom')

	else
		window.sim = sim
		window.document.addEventListener 'DOMContentLoaded', ->
			if sim.isReady then return
			sim.isReady = true
			
			listener() for listener in READY_LISTENERS

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
						when 'attr'
							match = buffer.match(/^([_a-z0-9-]+)(?:=(.*))?\]$/i)
							if match then condition.attribute.push name: match[1], operator: '=', value: match[2]
							
						when 'pseudo'
							match = buffer.match(/^([a-z]+)(?:\((.*))?$/i)
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
	
	matches = (elm, conditions) ->
		if conditions.length is 0
			return true
		
		for condition in conditions
			if condition.id? and elm.attr('id') isnt condition.id then continue
			if condition.tag and elm.prop('tagName').toLowerCase() isnt condition.tag then continue
			if condition['class'].length
				fulfilled = true
				for name in condition['class'] when not elm.hasClass name
					fulfilled = false
					break
				
				if not fulfilled then continue
			
			if condition.attribute.length
				fulfilled = true
				for attr in condition.attribute when attr.value isnt elm.attr attr.name
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
							if not elm.__dom.parentNode?
								fulfilled = false
								break
								
							if Array::indexOf.call(elm.__dom.parentNode.childNodes, elm.__dom) % 2 is 1
								fulfilled = false
								break
								
						when 'even'
							if not elm.__dom.parentNode?
								fulfilled = false
								break
								
							if Array::indexOf.call(elm.__dom.parentNode.childNodes, elm.__dom) % 2 is 0
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
		
		append: ->
			elm.append arguments... for elm in @
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
			if arguments.length is 1
				@first()?.data key
	
			else
				elm.data key, value for elm in @
				@
		
		detach: ->
			elm.detach() for elm in @
			@
		
		each: (method) ->
			method.call item, index, item for item, index in @
			@
		
		emit: ->
			elm.emit arguments... for elm in @
			@
		
		filter: (selectors) ->
			arr = new SIMArray
			if not selectors?
				arr.push item for item in @
				return arr
			
			conditions = parse selectors
			arr.push item for item in @ when matches item, conditions
			arr
		
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
		
		not: (selectors) ->
			arr = new SIMArray
			if not selectors?
				arr.push item for item in @
				return arr
			
			conditions = parse selectors
			arr.push item for item in @ when not matches item, conditions
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
		
		push: (elm) ->
			if not elm? then return @
			check elm, SIMElement, SIMText, SIMArray
			
			if elm instanceof SIMArray
				@push e for e in elm
				return @
				
			Array::push.call @, elm
			
			@
		
		prev: ->
			arr = new SIMArray
			for elm in @
				arr.push elm.prev arguments...
			
			arr
		
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
			
			Object.defineProperty dom, '__sim__',
				value: @
	
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
			
			else if 'undefined' isnt typeof jQuery and tag instanceof jQuery
				super tag[0]
			
			else if tag.nodeName
				super tag
			
			else if 'string' is typeof tag
				if @constructor.NS?
					super document.createElementNS @constructor.NS, tag
				else
					super document.createElement tag
			
			else
				throw new Error "Invalid arguments."
			
			# attach to parent
			
			if parent?
				@appendTo parent
			
			# parse properties
	
			if 'string' is typeof props
				props = parse(props)[0]
				
				if props.id? then @attr 'id', props.id
				if props.class? then @addClass klass for klass in props.class
				if props.attribute? then @attr attr.name, attr.value for attr in props.attribute
			
			next?.call @
		
		addClass: (names) ->
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
			sim @__dom.cloneNode true
		
		data: (key, value) ->
			if arguments.length is 1
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
			if 'string' is typeof name
				klass = EVENT_CONSTRUCTOR[name] ? 'CustomEvent'
				try
					event = new window[klass] name, options
				catch
					event = @__dom.ownerDocument.createEvent klass
					event.initCustomEvent name, options.bubbles ? true, options.cancelable ? false, options.detail
			
			else
				throw new Error "Invalid arguments."
			
			@__dom.dispatchEvent event
		
		empty: ->
			while @__dom.hasChildNodes()
				@__dom.removeChild @__dom.lastChild
			
			@
		
		find: (selector) ->
			if 'string' is typeof selector
				# only one possilbe result when # is used in selector
				if (/#([a-zA-Z]+[_a-zA-Z0-9-]*)/).test selector
					return sim query @__dom, selector
				
				else
					return simArray queryAll @__dom, selector ? '*'
			
			else
				throw new Error "Invalid arguments."
		
		findOne: (selector) ->
			sim query @__dom, selector ? '*'
		
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
				parseFloat @css 'height'
		
		hide: ->
			@css 'display', 'none'
		
		html: (value) ->
			if arguments.length
				@__dom.innerHTML = value
				@
	
			else
				@__dom.innerHTML
		
		children: (selector) ->
			simArray(elm for elm in @__dom.childNodes when elm.nodeType is 1).filter selector
		
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
			"[SIMElement #{@__dom.nodeName.toLowerCase()}]"
		
		is: (selector) ->
			matches @, parse selector
		
		next: (selector) ->
			elm = sim @__dom.nextSibling
			
			if selector?
				if not matches elm, parse selector
					return null
			
			elm
		
		nextAll: (selector) ->
			if not @__dom.parentNode then return simArray()
			index = Array::indexOf.call @__dom.parentNode.childNodes, @__dom
			if index is -1 then return simArray()
			simArray(Array::slice.call(@__dom.parentNode.childNodes, index + 1)).filter selector
		
		off: (event, selector, handler) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined
			
			fce = handler
			if selector
				index = @__handlers[event]?[selector]?.original.indexOf handler
				if not index? or index is -1
					return @ # handler doesn't exist
				
				fce = @__handlers[event][selector].temporary[index]
				
				@__handlers[event][selector].original.splice index, 1
				@__handlers[event][selector].temporary.splice index, 1
			
			@__dom.removeEventListener event, fce
			@
		
		offset: ->
			bounds = @__dom.getBoundingClientRect()
			
			left: bounds.left + @__dom.ownerDocument.defaultView.scrollX
			top: bounds.top + @__dom.ownerDocument.defaultView.scrollY
		
		on: (events, selector, handler) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined
	
			for event in events.split ' '
				index = @__handlers[event]?[selector]?.original.indexOf handler
				if index? and index isnt -1
					return @ # handler already exists
				
				fce = handler
				if selector
					fce = (event) ->
						target = sim event.target
						if target.is selector
							return handler.apply target, arguments
						
						closest = target.closest selector
						if closest
							return handler.apply closest, arguments
						
						null
					
					@__handlers[event] ?= Object.create null
					@__handlers[event][selector] ?= original: [], temporary: []
					@__handlers[event][selector].original.push handler
					@__handlers[event][selector].temporary.push fce
				
				@__dom.addEventListener event, fce
	
			@
		
		once: (event, selector, handler) ->
			if 'function' is typeof selector
				handler = selector
				selector = undefined
	
			fce = =>
				SIMElement::off.call @, event, fce
				handler arguments...
	
			SIMElement::on.call @, event, selector, fce
			@
		
		outerHeight: (margin) ->
			add = 0
			if margin
				m = parseFloat @css 'margin-top'
				if not isNaN m then add += m
				m = parseFloat @css 'margin-bottom'
				if not isNaN m then add += m
			
			if @is ':visible'
				@__dom.offsetHeight + add
			
			else
				SIMElement::height.call(@) + add
		
		outerWidth: (margin) ->
			add = 0
			if margin
				m = parseFloat @css 'margin-left'
				if not isNaN m then add += m
				m = parseFloat @css 'margin-right'
				if not isNaN m then add += m
				
			if @is ':visible'
				@__dom.offsetWidth + add
			
			else
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
	
			if selector?
				if not matches elm, parse selector
					return null
			
			elm
		
		prevAll: (selector) ->
			if not @__dom.parentNode then return simArray()
			index = Array::indexOf.call @__dom.parentNode.childNodes, @__dom
			if index <= 0 then return simArray()
			simArray(Array::slice.call(@__dom.parentNode.childNodes, 0, index)).filter selector
		
		prop: (key, value) ->
			if arguments.length is 1
				@__dom[key]
	
			else
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
				parseFloat @css 'width'
			
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
	
	class SIMSVGElement extends SIMElement
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
	
	class SIMText extends SIMBase
		constructor: (text) ->
			if not text?
				super document.createTextNode ''
			
			else if 'string' is typeof text
				super document.createTextNode text
			
			else if text.nodeType is 3
				super text
			
			else
				throw new Error "Invalid arguments."
		
		after: SIMElement::after
		appendTo: SIMElement::appendTo
		before: SIMElement::before
		detach: SIMElement::detach
		prependTo: SIMElement::prependTo
		insertBefore: SIMElement::insertBefore
		insertAfter: SIMElement::insertAfter
		is: -> false
		remove: SIMElement::remove
		text: SIMElement::text
	
	class SIMDocument extends SIMBase
		emit: SIMElement::emit
		height: -> document.documentElement.offsetHeight
		on: SIMElement::on
		once: SIMElement::once
		off: SIMElement::off
		trigger: SIMElement::trigger
		width: -> document.documentElement.offsetWidth
	
	class SIMWindow extends SIMBase
		emit: SIMElement::emit
		height: -> document.documentElement.clientHeight
		on: SIMElement::on
		once: SIMElement::once
		off: SIMElement::off
		open: -> window.open arguments...
		scrollLeft: -> window.scrollX
		scrollTop: -> window.scrollY
		trigger: SIMElement::trigger
		width: -> document.documentElement.clientWidth
	
	Object.defineProperties SIMWindow.prototype,
		devicePixelRatio:
			get: -> @__dom.devicePixelRatio

		document:
			get: -> sim document

		history:
			get: -> window.history
		
		location:
			get: -> window.location
			set: (value) -> window.location = value
	
	#if 'undefined' isnt CustomEvent then SIMEvent.prototype = CustomEvent.prototype
	
	create = (tag, parent, props) ->
		if HAS_COMPONENTS and (/@([-a-z0-9_]+)/i).exec props
			new (COMPONENT[RegExp.$1] ? SIMElement) arguments...
		
		else
			new SIMElement arguments...
		
	createSVG = (tag, parent, props) ->
		if HAS_COMPONENTS and (/@([-a-z0-9_]+)/i).exec props
			new (COMPONENT[RegExp.$1] ? SIMSVGElement) arguments...
		
		else
			new SIMSVGElement arguments...
	
	sim.array = (args...) ->
		if args.length is 0 then return new SIMArray
		if args.length is 1 then return new SIMArray args[0]
		new SIMArray args
	
	sim.html = create.bind null, 'html', null
	sim.svg = createSVG.bind null, 'svg', null
	sim.text = (text) -> new SIMText text
	sim.ready = (handler) ->
		if sim.isReady
			return setImmediate handler
		
		READY_LISTENERS.push handler
		@
	
	sim.register = (name, klass) ->
		if klass.prototype not instanceof SIMElement
			throw new Error "Invalid arguments."
		
		COMPONENT[name] = klass
		HAS_COMPONENTS = true
		@

	sim.SIMElement = SIMElement
	sim.SIMArray = SIMArray
	sim.SIMDocument = SIMDocument
	sim.SIMWindow = SIMWindow
	sim.SIMText = SIMText
	
	do ->
		for tag in TAGS
			sim[tag] = create.bind null, tag, null
			
			do (tag) ->
				Object.defineProperty SIMElement.prototype, tag,
					enumerable: false
					configurable: true
					writable: true
					value: -> create tag, @, arguments...
		
		for tag in SVG_TAGS
			sim[tag] = createSVG.bind null, tag, null
			
			do (tag) ->
				Object.defineProperty SIMSVGElement.prototype, tag,
					enumerable: false
					configurable: true
					writable: true
					value: -> createSVG tag, @, arguments...
		
		# jQuery integration
		
		if window.jQuery
			sim.ajax = jQuery.ajax.bind jQuery
		
		for name in JQUERY_POLYFILLS
			do (name) ->
				SIMElement::[name] = ->
					if not window.jQuery?
						throw new Error "jQuery is required in order to use '#{name}' method."
					
					window.jQuery(@__dom)[name] arguments...
		
		SIMBase::toJquery = ->
			if not window.jQuery?
				throw new Error "jQuery is required in order to use '#{name}' method."
			
			window.jQuery @__dom
		
		SIMArray::toJquery = ->
			if not window.jQuery?
				throw new Error "jQuery is required in order to use '#{name}' method."
			
			window.jQuery (elm.__dom for elm in @)