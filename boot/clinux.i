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

--dofile("/lib/thread.l")
old = {
	fs = {}
}
for k, v in pairs(fs) do
	old.fs[k] = v
end

local tTables = {}
local tReadOnly = {}
local native_rawset = rawset
local mt = {
                __metatable = 'Attempt to get protected metatable',
                __newindex = function(self, key, value)
                        if not tTables[self][key] then
                                native_rawset(self, key, value)
                                return
                        end
                        error('Try to write to read only table', 2)
                end
}
mt.__index = function (self, key)
                local var = tTables[self][key]
                if type(var) == 'table' then
                                setmetatable({}, mt)
                end
                return var
end

_G.rawset = function (tab, key, value)
                if tReadOnly[tab] then error('Try to write to read only table', 2) end
                return native_rawset(tab, key, value)
end

local function createReadOnly (tab)
                if type(tab) ~= 'table' then
                                error('table expected, got ' .. type(tab), 2)
                end
                local self = setmetatable({}, mt)
                tTables[self] = tab
                tReadOnly[self] = true
                return self
end

-- Put in _G
function _put(a,b) _G[a]=b end
_put('_put', _put)
_put('old', old)
function _check(a)
	if _G[a] == nil then
		return false
	else
		return true
	end
end
_put('_check', _check)
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
-- Starts DE / Windowmanager (located in /boot/X/xserv.i), use /startup
_flag('startX', false)

_arg = {...}
if #_arg > 0 then
	for _,arg in pairs(_arg) do
		if arg == "sysdebug" then
		    SYSDEBUG = SYSDEBUG + 1
		elseif arg == "rescue" then
			RESCUE = true 
		elseif arg == "startX" then
			startX = true
		end
	end
end
-- Top Level Corroutine Override
local syserror = printError
_put('syserror', syserror)
_G.printError = function()
	_G.printError = syserror
	local bLoad = loadfile("/boot/load")
	local bAlive = loadfile("/vit/alive")
	local c1 = coroutine.create(bLoad)
	local evt = {}
	while not flag.STATE_DEAD do
		coroutine.resume(c1, unpack(evt))
		evt = {os.pullEvent()}
	end
	if flag.STATE_DEAD then
		bAlive()
	end
	--local system_alive = thread.new(loadfile("/vit/alive"), "/vit/alive", 0, createReadOnly(_G))
	--local nextf = thread.new(loadfile("/boot/load"), "/boot/load", 1, createReadOnly(_G))
	-- NOTE: /boot/load is now in charge of all files to run. If that you know when is
	-- that branch going to die, please do _flag('STATUS_DEAD') to force a restart.
	--thread.runAll(nextf.next)
end
os.queueEvent("modem_message", 0)