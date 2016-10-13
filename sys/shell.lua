

--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /bin/shell
	CATEGORY:    boot
	SET:         Boot III
	VERSION:     01:alpha0
	DESCRIPTION: 
		This script is ran after /boot/load
		and starts the basic services up.
]]--
--[[local ok = perm.permission.login("patrick", "")
if not ok then
	print("login failed")
	sleep(1)
else
	print("login success")
	sleep(1)
end]]
local tasks = {}
local curPath = "/"
thread = sThread
term.setCursorPos(1,1)
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()



--[[
						##EXPERIMENTAL##
				PLEASE REPORT BUGS IN THE FORUM POST
				
					--Shell API dummies--
					(simulate shell functions)
]]
shell = {}
function shell.run(path, ...)
	local tArgs = {...}
	local function _copy(a, b)
		for k, v in pairs(a) do
			b[k] = v
		end
	end
	local env = {}
	_copy(_G, env)
	blacklist = {'rawget', 'rawset', 'dofile', 'thread', 'sThread'}	--things that shouldn't get added, and extras
	for k, v in ipairs(blacklist) do env[v] = nil end
	return os.run(env, path, unpack(tArgs))
end
function shell.exit()
	flag.STATE_SHUTDOWN = true
	thread.killAll(tasks)
	return
end
function shell.dir()
	return curPath
end
function shell.setDir(p)
	if fs.exists(p) and fs.isDir(p) then
		local i, j = string.find(p, "/")
		if i == 1 then
			curPath = p
		else
			curPath = "/"..p
		end
		return
	elseif fs.exists(curPath..p) and fs.isDir(curPath..p) then
		curPath = curPath..p
		return
	elseif fs.exists(p) == false or fs.isDir(p) == false then
		return false
	end
end
function shell.path()
	local str = ""
	for _, a in pairs(tasks) do
		str = str..":".._
	end
	return str
end
function shell.setPath()
	return nil
end
function shell.resolve(p)
	if fs.exists(curPath..p) then
		return curPath..p
	else
		return nil
	end
end
function shell.resolveProgram(p)
	if fs.exists("/bin/"..p) then
		return "/bin/"..p
	else
		return nil
	end
end
function shell.aliases()
	return nil
end
function shell.setAlias()
	return nil
end
function shell.clearAlias()
	return nil
end
function shell.programs(hidden)
	local a = fs.list("/bin/")
	if hidden then
		return a
	else
		for _, b in ipairs(a) do
			local i, j = string.find(b, ".")
			if i == 1 then
				table.remove(a, _)
			end
		end
		return a
	end
end
function shell.getRunningProgram()
	return shell.dir()
end
function shell.openTag()
	return nil
end
function shell.switchTab()
	return nil
end
function shell.complete(s)
	local a = fs.list("/bin/")
	local c = {}
	for _, b in ipairs(a) do
		local i, j = string.find(b, s)
		if i == 1 then
			table.insert(c, b)
		end
	end
	return c
end
function shell.completeProgram(s)
	return shell.complete(s)
end
function shell.setCompletionFunction()
	return nil
end
function shell.getCompletionInfo()
	return nil
end

function printError(str)
	local c = term.getTextColor()
	term.setTextColor(colors.red)
	print(str)
	term.setTextColor(c)
end

local services = lib.serv.giveList()
for _, a in pairs(services) do
	if type(a) == true then
		if _ == "/sys/commandline" then
			_ = _
		else
			_ = "/etc/services.d/".._
		end
		local n, err = thread.new(_, nil, nil, nil, nil, nil, nil, nil, nil)
		if not n then
			local c = term.getTextColor()
			term.setTextColor(colors.red)
			term.write("[SERVICE] ")
			term.setTextColor(c)
			print(_.." failed. "..err)
			sleep(0.5)
		else
			local c = term.getTextColor()
			term.setTextColor(colors.green)
			term.write("[SERVICE] ")
			term.setTextColor(c)
			print(_.." started.")
			tasks = n.next
			sleep(0.5)
		end
	elseif a == "core" then
		local x, y = term.getCursorPos()
		x = 1
		y = y+1
		local par = term.current()
		local n, err = thread.new(_, nil, nil, 51, 19, par, true, x, y)
		if not n then
			local c = term.getTextColor()
			term.setTextColor(colors.red)
			term.write("[SERVICE] ")
			term.setTextColor(c)
			print(_.." failed. "..err)
			sleep(0.5)
		else
			local c = term.getTextColor()
			term.setTextColor(colors.green)
			term.write("[SERVICE] ")
			term.setTextColor(c)
			print(_.." started as core.")
			tasks = n.next
			sleep(0.5)
		end
	end
end

function startServ(k, args)
	local n, err = thread.new(_, nil, nil, nil, nil, nil, nil, nil, nil, args)
	if not l then
		return false, err
	else
		tasks = n.next
		return true
	end
end
_putLib('startService', startServ)

while true do
	
	thread.runAll(tasks)
	local ok, err = thread.getError()
	if ok ~= "noError" then
		printError(err)
	end
	if #tasks < 1 then
		flag.STATE_DEAD = true
		break
	end
	--[[term.write("#")
	local e = read()
	if fs.exists(e) and #e > 0 then
		local f, err = thread.new(e)
		if not f then
			printError(err)
		else
			tasks = f.next
		end
	elseif fs.exists(e) == false and #e > 0 then
		print("Command not found.")
	end]]
end
