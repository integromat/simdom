MOCKS =
	click: ->
		@emit 'click', bubbles: true, cancelable: false
	
	input: (value) ->
		@val value
		@emit 'input'
	
	select: (value) ->
		old = @val()
		@val value
		canceled = not @emit 'change', bubbles: true, cancelable: false
		if canceled then @val old
		not canceled

module.exports = (sim) ->
	Object.defineProperty sim.SIMElement.prototype, 'mock',
		get: ->
			o = {}
			for key, value of MOCKS
				o[key] = value.bind @
			
			o

	Object.defineProperty sim.SIMArray.prototype, 'mock',
		get: ->
			self = @
			o = {}
			for key, value of MOCKS
				o[key] = (args...) ->
					self.each ->
						value.apply @, args
			
			o