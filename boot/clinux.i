--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /boot/clinux.i
	CATEGORY:    boot
	SET:         Boot I
	VERSION:     01:alpha0
	DESCRIPTION: 
		This script is ran after /startup and
		it sets flags manually, also loading
		some utils for posterior scripts.
]]--
dofile("/lib/thread.l")


-- Put in _G
function _put(a,b) _G[a]=b end
_put('_put', _put)
function _check(a)
	if _G[a] == nil then
		return false
	else
		return true
end
-- Put in _G.flag
_put('flag', {})
function _flag(a,b) _G.flag[a] = b end
_put('_flag', _flag)

-- Get _G.flag[flag]
function _getflag(flag) return flag[flag] end
_put('_getflag', _getflag)

-- Loadfile, securely
_put('_REQUIRECACHE', {})
local function require(file)
	local ok, ret = pcall(loadfile(file))
	if ok then
		_REQUIRECACHE[#_REQUIRECACHE+1] = file
		return true
	else
		return false
	end
end
_put('require', require)

-- Set system flags
--- Debug level, set to 0 by default, use /startup
_flag('SYSDEBUG', 0)
-- Rescue shell mode, set to false by default
_flag('RESCUE', false)
-- Starting the OS, can't be changed
_flag('STATE_INIT', true)

_arg = {...}
if #_arg > 0 then
	for _,arg in pairs(_arg) do
		if arg == "sysdebug" then SYSDEBUG = SYSDEBUG + 1
		elseif arg == "rescue" then RESCUE = true end
	end
end

-- Top Level Corroutine Override
local syserror = printError
printError = function()
	local printError = syserror
	local system_alive = thread.new(loadfile("/vit/alive"), "/vit/alive", 0))
	local nextf = thread.new(assert(loadfile("/boot/load"))(), "/boot/load", 1)
	-- NOTE: /boot/load is now in charge of all files to run. If that you know when is
	-- that branch going to die, please do _flag('STATUS_DEAD') to force a restart.
	thread.runAll(nextf.next)
end
os.queueEvent("modem_message", 0)