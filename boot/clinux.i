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



print("Welcome to cLinux !")
sleep(2)



--Modify the os.loadAPI and others.... NOTE: I think loadAPI is useless here, as I already did that in the right way in thread.l
local bos = {}

for k, v in pairs(_G.os) do
	bos[k] = v
end

local tAPIsLoading = {}
function bos.loadAPI( _sPath )
		print("Loading ".._sPath)
    local sName = fs.getName( _sPath )
    if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath, tEnv )
    if fnAPI then
        local ok, err = pcall( fnAPI )
        if not ok then
            printError( err )
            tAPIsLoading[sName] = nil
            return false
        end
    else
        printError( err )
        tAPIsLoading[sName] = nil
        return false
    end

    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end
    tAPIsLoading[sName] = nil
		--Edited part
    return true, _putLib(sName, tAPI), _put(sName, tAPI)
end

local oos = {}
for k, v in pairs(_G.os) do
    oos[k] = v
end

--There was an error with returning the right event, this should fix it
function bos.pullEvent(_filtr)
    if _filtr then
        repeat
            local evt = {oos.pullEvent()}
        until evt[1] == _filtr
        return unpack(evt)
    else
        return oos.pullEvent()
    end
end

function bos.pullEventRaw(_filtr)
    if _filtr then
        repeat
            local _, a, b, c = oos.pullEventRaw()
        until _ == _filtr
        return _, a, b, c
    else
        return oos.pullEventRaw()
    end
end


--Load the API, in the cLinux way (use _putLib in the API, for example)
function loadAPI(path)
	local ok, err = loadfile(path)
	if not ok then
		return false, err
	else
		local ok, err = ok()
		if ok == false then
			return false, err
		else
			return true
		end
	end
end

-- Put in _G
function _put(a,b) _G[a]=b end



local lib = {}
function _putLib(a,b) _G['lib'][a]=b end

_put('_put', _put)
_put('lib', lib)
_put('_putLib', _putLib)
_putLib('os', bos)
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


local ok, err = loadAPI("/sys/thread.l")
if not ok then
	printError(err)
	return
end


function _flag(a,b) _G.flag[a] = b end
_put('_flag', _flag)
_put('loadAPI', loadAPI)
-- Get _G.flag[flag]
function _getflag(flag) return flag[flag] end
_put('_getflag', _getflag)
-- Loadfile, securely
_put('_REQUIRECACHE', {})
local function require(file)
	local function go()
		loadfile(file)
	end
	local ok, ret = pcall(go)
	if ok then
		_REQUIRECACHE[#_REQUIRECACHE+1] = file
		return true
	else
		return false
	end
end
local function cLinuxPrintError(status, message)
	local c = term.getTextColor()
	term.setTextColor(colors.red)
	print("["..tostring(status).."] "..tostring(message))
	term.setTextColor(c)
end

_put('cLinuxPrintError', cLinuxPrintError)
_put('require', require)
-- Set system flags
--- Debug level, set to 0 by default, use /startup
_flag('SYSDEBUG', 0)
-- Starting the OS, can't be changed
_flag('STATE_INIT', true)
-- Ignore the current services.conf, for example to start the commandline
_flag('text', false)



_arg = {...}
if #_arg > 0 then
	for _,arg in pairs(_arg) do
		if arg == "sysdebug" then
		    flag.SYSDEBUG = flag.SYSDEBUG + 1
		elseif arg == "rescue" then
			flag.RESCUE = true
		elseif arg == "text" then
			flag.text = true
		end
	end
end
-- Top Level Corroutine Override
local syserror = printError
_put('syserror', syserror)
_G.printError = function()
	_G.printError = syserror
	_G['rednet'] = nil
	local evt = {}
		--initiate ground-environment
		local newenv = {}
		for k, v in pairs(_G) do
			newenv[k] = v
		end
		setmetatable(newenv, {})
		--initiate ground-tasklist
		local tasks = {}
		tasks['list'] = {}
		tasks['last_uid'] = 0
		tasks['somethingInFG'] = false


		term.clearLine() -- cLinux#10
		print("Loading core")
		sleep(0.5)
		local ok, err = thread.new("/boot/load", newenv, "Core", tasks)
		if not ok then
			cLinuxPrintError("Core", err)
		end
		print("Loading alive")
		sleep(0.5)
		local ok, err = thread.new("/vit/alive", newenv, "Alive", tasks, tasks)
		if not ok then
			cLinuxPrintError("Alive", err)
		end

		sleep(0.5)


		local running = true
		while running do
			local ok = thread.resumeAll(tasks, evt)
			evt = {os.pullEventRaw()}
			if ok == false then
				running = false
			end
		end
		print(err)
		sleep(2)
	--end
	print("Looks like /vit/alive failed..")
	sleep(1)
	os.reboot()
	-- NOTE: /boot/load is now in charge of all files to run. If that you know when is
	-- that branch going to die, please do _flag('STATUS_DEAD') to force a restart.
end
os.queueEvent("modem_message", 0)