'use strict'

jsdom = require 'jsdom'
config = virtualConsole: jsdom.createVirtualConsole().sendTo(console)
module.exports = window = jsdom.jsdom(undefined, config).defaultView

Object.defineProperties window.navigator,
	appName:
		get: -> 'simDOM'
	
	platform:
		get: ->
			switch require('os').platform()
				when 'darwin' then return 'Macintosh'
				when 'linux' then return 'Linux'
				when 'win32' then return 'Windows'
				else null
	
	userAgent:
		get: ->
			"#{@appName} (#{@platform})"

Object.defineProperties window.HTMLElement.prototype,
	offsetLeft:
		get: -> parseFloat(window.getComputedStyle(@).marginLeft) or 0
	
	offsetTop:
		get: -> parseFloat(window.getComputedStyle(@).marginTop) or 0
	
	offsetHeight:
		get: ->
			if 'none' is window.getComputedStyle(@, null).getPropertyValue 'display' then return 0
			parseFloat window.getComputedStyle(@, null).getPropertyValue 'height'
	
	offsetWidth:
		get: ->
			if 'none' is window.getComputedStyle(@, null).getPropertyValue 'display' then return 0
			parseFloat window.getComputedStyle(@, null).getPropertyValue 'height'

class window.CustomEvent extends window.Event
	constructor: ->
		window.Event.apply @, arguments