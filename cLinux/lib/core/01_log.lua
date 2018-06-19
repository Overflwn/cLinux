--[[
--		cLinux logging system
--
--~Overflwn
--]]

_G.log = {}
local oldfs = fs
local currentLog = nil
function newLog()
	local logfile, err = oldfs.open("/sys/log/"..tostring(os.day())..".txt", "w")
	if not logfile then
		return false, err
	end
	return logfile
end

currentLog = newLog()
_G.log.type = {
	ERROR = "ERROR",
	INFO = "INFO",
	SUCCESS = "SUCCESS",
	WARNING = "WARNING"
}

function _G.log.log(t, source, message)
	oldfs.write(currentLog, "["..t.."] "..tostring(source)..": "..tostring(message).."\n")
end

function _G.log.print(t, source, message)
	term.write("[")
	if t == log.type.ERROR then
		term.setTextColor(16384)
		term.write(log.type.ERROR)
	elseif t == log.type.INFO then
		term.setTextColor(1)
		term.write(log.type.INFO)
	elseif t == log.type.SUCCESS then
		term.setTextColor(8192)
		term.write(log.type.SUCCESS)
	elseif t == log.type.WARNING then
		term.setTextColor(16)
		term.write(log.type.WARNING)
	end
	term.setTextColor(1)
	print("] "..tostring(source)..": "..tostring(message))
end

function _G.log.printAndLog(t, source, message)
	_G.log.print(t, source, message)
	_G.log.log(t, source, message)
end
