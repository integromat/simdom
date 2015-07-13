assert = require 'assert'
assert.compare = (a, b) ->
	re = /<([a-z]+)\s?([^>]*)>/gi
	ra = /^style="(.*)"$/i
	fn = (a, b, c) ->
		attrs = c.match(/[_a-z0-9-]+(?:="[^"]*")?/gi)
		if not attrs then return a
		for attr, index in attrs
			attrs[index] = attr.replace ra, (a, b) ->
				styles = b.match(/-?[_a-zA-Z]+[_a-zA-Z0-9-]*\s*:\s*[^;]*;/gi)
				if not styles then return a
				styles.sort()
				"style=\"#{styles.join ' '}\""
		
		attrs.sort()
		"<#{b} #{attrs.join ' '}>"
	
	a = a?.toString().replace re, fn
	b = b?.toString().replace re, fn
	
	#console.log a
	#console.log b
	
	if a isnt b
		err = new Error "'#{a}' == '#{b}'"
		err.actual = a
		err.expected = b
		err.operator = '=='
		throw err

NODE = not (window ? null)?
OBJECT = {}

describe 'basic test suite', ->
	it 'should create sim array #1', ->
		assert.equal sim.array().length, 0
		assert.equal sim.array("asdf").length, 0
		assert.equal sim.array("body").length, 1
		assert.equal sim.array("body", "html").length, 2
		assert.equal sim.array(["body", "html"]).length, 2
	
	it 'should create basic dom #1', ->
		dom = sim.ul ->
			@li ->
				@a ->
					@attr 'href', '#'
					@text 'test'

		assert.compare dom, '<ul><li><a href="#">test</a></li></ul>'
		
		if NODE
			dom.appendTo sim.document.body
			assert.compare sim(sim.document), '<!DOCTYPE html><html><body><ul><li><a href="#">test</a></li></ul></body></html>'
	
	it 'should create basic dom #2', ->
		dom = sim.div '.header', ->
			@p()
			@img '.logo.modern#logo[title="hello world"]', ->
				@attr 'src', 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
				@css 'overflow', 'hidden'
				@data 'somevar', 'someval'
				@hide()
				@css
					left: '1px'
					top: '2px'
		
		assert.compare dom, '<div class="header"><p></p><img id="logo" class="logo modern" title="hello world" src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" style="overflow: hidden; display: none; left: 1px; top: 2px;" data-somevar="someval"></div>'
		dom.data 'test', 'abc'
		dom.data 'object', OBJECT
		assert.strictEqual dom.data('test'), 'abc'
		assert.strictEqual dom.data('object'), OBJECT
		dom.empty()
		assert.compare dom, '<div class="header" data-test="abc"></div>'
	
	it 'should create basic dom #3', ->
		dom = sim.div ->
			@css 'z-index': 1
			@css 'left', 1
			
			@div ->
				@css 'zIndex': 2
				
				@div ->
					@css
						'z-index': 3
					
					@div ->
						@css
							zIndex: 4
							left: 4
		
		assert.compare dom, '<div style="z-index: 1; left: 1px;"><div style="z-index: 2;"><div style="z-index: 3;"><div style="z-index: 4; left: 4px;"></div></div></div></div>'
		
	it 'should manipulate with dom #1', ->
		dom = sim.div '.header'
		dom.p('.third').before sim.p('.second')
		dom.prepend sim.p('.first')
		sim.p('.last').appendTo(dom).after(sim.i('.last')).remove()
		
		assert.compare dom, '<div class="header"><p class="first"></p><p class="second"></p><p class="third"></p><i class="last"></i></div>'
		
		first = dom.children('.first').first()
		last = dom.children().last()

		assert.compare first, '<p class="first"></p>'
		assert.compare first.next(), '<p class="second"></p>'
		assert.compare first.next('p'), '<p class="second"></p>'
		assert.compare first.next('html'), null
		assert.compare first.nextAll(), '<p class="second"></p><p class="third"></p><i class="last"></i>'
		assert.compare first.nextAll('i'), '<i class="last"></i>'
		assert.compare first.prev(), null
		assert.compare last, '<i class="last"></i>'
		assert.compare last.prev(), '<p class="third"></p>'
		assert.compare last.prevAll(), '<p class="first"></p><p class="second"></p><p class="third"></p>'
		assert.compare last.prevAll('.second'), '<p class="second"></p>'
		assert.compare last.next(), null
		
	it 'should manipulate with dom #2', ->
		dom = sim.div '.test', ->
			@append @clone().do ->
				@p().text 'test'
		
		dom.append dom.clone true
		assert.compare dom, '<div class="test"><div class="test"><p>test</p></div><div class="test"><div class="test"><p>test</p></div></div></div>'
		
	it 'should manipulate with dom #3', ->
		inner = sim.i '.inner'
		dom = sim.div '.test', ->
			@p '.first', ->
				@append inner
		
		assert.compare dom, '<div class="test"><p class="first"><i class="inner"></i></p></div>'
		dom.prepend inner
		assert.compare dom, '<div class="test"><i class="inner"></i><p class="first"></p></div>'
		inner.replaceWith sim.array sim.p('.rep1'), sim.p('.rep2')
		assert.compare dom, '<div class="test"><p class="rep1"></p><p class="rep2"></p><p class="first"></p></div>'
		
	it 'should query dom #1', ->
		dom = sim.div ->
			@p '.first'
			@p '.second'
			@i '.third'
		
		query = dom.children()
		assert.strictEqual query.length, 3
		assert.compare dom, '<div><p class="first"></p><p class="second"></p><i class="third"></i></div>'
		assert.compare query, '<p class="first"></p><p class="second"></p><i class="third"></i>'
		assert.compare query.filter(':even'), '<p class="second"></p>'
		assert.compare query.filter(':odd'), '<p class="first"></p><i class="third"></i>'
		assert.compare query.filter(':odd:not(.third)'), '<p class="first"></p>'
		query.remove()
		dom.width(100).height(100).appendTo sim('body')
		assert.compare dom, '<div style="width: 100px; height: 100px;"></div>'
		assert.strictEqual dom.is(':visible'), true
		dom.hide()
		assert.strictEqual dom.is(':visible'), false
		dom.remove()
	
	it 'should query dom #2', ->
		if NODE then return @skip() # not implemented yet
		
		i = null
		dom = sim.div ->
			@div ->
				i = @i ->
					@attr 'title', 'text'
		
		assert.ok dom.contains i
		
		assert.compare dom.find('[title]'), '<i title="text"></i>'
		assert.compare dom.find('[title="text"]'), '<i title="text"></i>'
		assert.compare dom.find('[titlex]'), ''
		assert.compare dom.find('[title="textx"]'), ''
	
	it 'should query dom #3', ->
		arr = sim.array [sim.p(), sim.a(), sim.i(), sim.b()]
		
		assert.compare arr.slice(0), '<p></p><a></a><i></i><b></b>'
		assert.compare arr.slice(2), '<i></i><b></b>'
		assert.compare arr.slice(1, 2), '<a></a>'
	
	it 'should handle events #1', (done) ->
		tick = false
		p = null
		dom = sim.div ->
			@on 'testevent', (event) ->
				assert.ok tick
				dom.remove()
				done()
			
			p = @p ->
				@on 'testevent', (event) ->
					tick = true
			
			@appendTo sim('body')
		
		p.emit 'testevent', bubbles: true
	
	it 'should handle events #2', (done) ->
		tick = false
		dom = sim.div ->
			@on 'e1 e2', (event) ->
				if event.type is 'e1'
					tick = true
				
				else if event.type is 'e2'
					assert.ok tick
					done()
		
		dom.emit 'e1'
		dom.emit 'e2'
	
	it 'should handle events #3', ->
		ticks = 0
		fn = -> ticks++
		
		dom = sim.div ->
			@on 'e', fn
		
		dom.emit 'e'
		assert.strictEqual ticks, 1
		dom.off 'e', fn
		dom.emit 'e'
		assert.strictEqual ticks, 1
	
	it 'should handle events #4', ->
		ticks = 0
		fn = -> ticks++
		
		dom = sim.div ->
			@once 'e', fn
		
		dom.emit 'e'
		assert.strictEqual ticks, 1
		dom.emit 'e'
		assert.strictEqual ticks, 1
	
	it 'should handle events #5', ->
		ticks = 0
		p = null
		i = null
		dom = sim.div ->
			@on 'e', 'p', (event) ->
				ticks++
			
			p = @p()
			i = @i()
			
			@appendTo sim('body')
		
		p.emit 'e', bubbles: true
		p.emit 'i', bubbles: true
		assert.strictEqual ticks, 1
		dom.remove()
	
	it 'should handle events #6', ->
		ticks = 0
		p = null
		fn = (event) -> ticks++
		dom = sim.div ->
			@on 'e', 'p', fn
			
			p = @p()
			
			@appendTo sim('body')
		
		p.emit 'e', bubbles: true
		dom.off 'e', 'p', fn
		p.emit 'e', bubbles: true
		assert.strictEqual ticks, 1
		dom.remove()
	
	it 'should handle events #7', ->
		ticks = 0
		p = null
		dom = sim.div ->
			@on 'e', ->
				assert.strictEqual @, dom
				ticks++

			@on 'e', 'p', ->
				assert.strictEqual @, p
				ticks++
			
			p = @p()
			
			@appendTo sim('body')
		
		p.emit 'e', bubbles: true
		assert.strictEqual ticks, 2
	
	it 'should handle events #8', ->
		ticks = 0
		fn = ->
			assert.strictEqual @, dom
			ticks++
		
		dom = sim.div ->
			@once 'resize', fn
		
		dom.emit 'resize'
		assert.strictEqual ticks, 1
		dom.emit 'resize'
		assert.strictEqual ticks, 1
		dom.once 'resize', fn
		dom.off 'resize', fn
		dom.emit 'resize'
		assert.strictEqual ticks, 1
	
	it 'should create a custom component #1', ->
		class SIMElementExtended extends sim.SIMElement
		sim.registerComponent 'custom-component', SIMElementExtended
		dom = sim.div '@custom-component'
		assert.ok dom instanceof SIMElementExtended
		assert.ok dom instanceof sim.SIMElement

describe 'basic svg test suite', ->
	it 'should create basic svg dom #1', ->
		dom = sim.svg ->
			@path ->
				@attr 'd', 'M 150 0 L 75 200 L 225 200 Z'
		
		assert.compare dom, '<svg><path d="M 150 0 L 75 200 L 225 200 Z"></path></svg>'