task 'compile', 'compile sources', ->
	setImmediate -> run [
		'coffee -c -o ./lib ./src'
		'coffee -c -o ./test/browser ./test/test.coffee'
	]

task 'watch', 'watch & compile sources', ->
	setImmediate -> run [
		'coffee -c -w -o ./lib ./src'
		'coffee -c -w -o ./test/browser ./test/test.coffee'
	]

# ---------------

run = (cmds) ->
	procs = []
	for cmd in cmds
		cmd = cmd.split ' '
		
		if process.platform is 'win32'
			cmd.unshift('/c');
			procs.push require('child_process').spawn process.env.comspec, cmd, stdio: 'inherit', cwd: process.cwd()
			
		else
			procs.push require('child_process').spawn cmd.shift(), cmd, stdio: 'inherit', cwd: process.cwd()