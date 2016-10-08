

--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /bin/shell
	CATEGORY:    boot
	SET:         Boot III
	VERSION:     01:alpha0
	DESCRIPTION: 
		This script is ran after /boot/load
		and starts the basic commandline up.
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

while true do
	
	thread.runAll(tasks)
	local ok, err = thread.getError()
	if ok ~= "noError" then
		printError(err)
	end
	term.write("#")
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
	end
end
