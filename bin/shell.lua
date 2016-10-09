

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
thread = sThread
term.setCursorPos(1,1)
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()

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
		local n, err = thread.new(_, nil, nil, nil, nil, nil, nil, nil, nil, true)
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
		local n, err = thread.new(_, nil, nil, nil, nil, par, true, x, y, true)
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
