--[[
--		cLinux chain
--
--~Overflwn
--]]


print("HELLO WORLD!!!")

local oldfs = fs
function _G.splitStr(str, sep)
	-- Solution I found on StackOverflow
	if sep == nil then
		sep = "%s"
	end
	local t = {}; i = 1
	for st in string.gmatch(str, "([^"..sep.."]+)") do
		t[i] = st
		i = i+1
	end
	return t
end

-- Execute all core libraries
for each, lib in ipairs(oldfs.list("/lib/core/")) do
	local file, err = loadfile("/lib/core/"..lib)
	if not file then
		term.setTextColor(16384)
		print("Could not load "..lib..": "..tostring(err)..", aborting...")
		os.sleep(3)
		return
	end
	local succ, err = pcall(file)
	if not succ then
		term.setTextColor(16384)
		print("Error executing "..lib..": "..tostring(err)..", aborting...")
		os.sleep(3)
		return
	end
end

log.log(log.type.SUCCESS, "cLinux Kernel", "Loaded core libraries!")
log.print(log.type.SUCCESS, "cLinux Kernel", "Loaded core libraries!")

log.print(log.type.INFO, "cLinux Kernel", "Running bin/bash...")
dofile("/bin/bash")
