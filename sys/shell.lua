
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
local maintask = 0
local thread = sThread
term.setCursorPos(1,1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
--_put('os', lib.os)

--[[
						##EXPERIMENTAL##
				PLEASE REPORT BUGS IN THE FORUM POST

					--Shell API dummies--
					(simulate shell functions)
]]
shell = {}
function shell.run(path, ...)
	if not string.find(path, "/", 1, 1) then
		path = "/bin/"..path
	end
	local tArgs = {...}
	local c = path
	local counter = 1
	repeat
		local i, j = string.find(c, " ")
		if i then
			if counter == 1 then
				path = string.sub(c, 1, i-1)
				c = string.sub(c, j+1)
				counter = counter+1
			else
				local arg = string.sub(c, 1, i-1)
				if not arg then
					printError("Fatal Error.")
					return false
				end
				c = string.sub(c, j+1)
				if not a then
					break
				end
				table.insert(tArgs, arg)
				counter = counter+1
			end
		elseif counter > 1 then
			table.insert(tArgs, c)
		end
	until i == nil
	local function _copy(a, b)
		for k, v in pairs(a) do
			b[k] = v
		end
		for k, v in pairs(b['lib']) do
			b[k] = v
		end
	end
	local env = {}
	_copy(_G, env)
	blacklist = {'rawget', 'rawset', 'dofile', 'flag'}	--things that shouldn't get added, and extras
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
		local i, j = string.find(p, "/", 1)
		if not string.find(p, "/", #p) then p = p.."/" end
		if i == 1 and #p > 1 then
			curPath = p
		elseif #p == 1 and p == "/" then
			curPath = p
		else
			curPath = "/"..p
		end
		return
	elseif fs.exists(curPath..p) and fs.isDir(curPath..p) and string.find(p, "/", 1) ~= 1 then
		curPath = curPath..p
		if not string.find(curPath, "/", #curPath) then curPath = curPath.."/" end
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
	if string.find(p, "/", 1, 1) then
		return p
	else
		return curPath.."/"..p
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
	local x = fs.list(shell.dir())
	for _, b in ipairs(x) do
		table.insert(a, b)
	end
	if hidden then
		return a
	else
		for _, b in ipairs(a) do
			local i = string.sub(b, 1, 1)
			if i == "." then
				table.remove(a, _)
			end
		end
		return a
	end
end

function shell.openTab()
	return nil
end
function shell.switchTab()
	return nil
end
local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
	local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end
local tCompletionInfo = {}
local function completeProgramArgument( sProgram, nArgument, sPart, tPreviousParts )
    local tInfo = tCompletionInfo[ sProgram ]
    if tInfo then
        return tInfo.fnComplete( shell, nArgument, sPart, tPreviousParts )
    end
    return nil
end
local function completeProgram( sLine )
	if #sLine > 0 and string.sub( sLine, 1, 1 ) == "/" then
	    -- Add programs from the root
	    return fs.complete( sLine, "", true, false )

    else
        local tResults = {}
        local tSeen = {}

        -- Add aliases

        -- Add programs from the path
        local tPrograms = shell.programs()
        for n=1,#tPrograms do
            local sProgram = tPrograms[n]
            if #sProgram > #sLine and string.sub( sProgram, 1, #sLine ) == sLine then
                local sResult = string.sub( sProgram, #sLine + 1 )
                if not tSeen[ sResult ] then
                    table.insert( tResults, sResult )
                    tSeen[ sResult ] = true
                end
            end
        end

        -- Sort and return
        table.sort( tResults )
        return tResults
    end
end

function shell.complete(sLine)
	if #sLine > 0 then
        local tWords = tokenise( sLine )
        local nIndex = #tWords
        if string.sub( sLine, #sLine, #sLine ) == " " then
            nIndex = nIndex + 1
        end
        if nIndex == 1 then
            local sBit = tWords[1] or ""
            local sPath = shell.resolveProgram( sBit )
            if tCompletionInfo[ sPath ] then
                return { " " }
            else
                local tResults = completeProgram( sBit )
                for n=1,#tResults do
                    local sResult = tResults[n]
                    local sPath = shell.resolveProgram( sBit .. sResult )
                    if tCompletionInfo[ sPath ] then
                        tResults[n] = sResult .. " "
                    end
                end
                return tResults
            end

        elseif nIndex > 1 then
            local sPath = shell.resolveProgram( tWords[1] )
            local sPart = tWords[nIndex] or ""
            local tPreviousParts = tWords
            tPreviousParts[nIndex] = nil
            return completeProgramArgument( sPath , nIndex - 1, sPart, tPreviousParts )

        end
    end
	return nil
end


function shell.setCompletionFunction( sProgram, fnComplete )
    tCompletionInfo[ sProgram ] = {
        fnComplete = fnComplete
    }
end

function shell.getCompletionInfo()
	return tCompletionInfo
end
function shell.getRunningProgram(threadlist)		--if you make your service, you NEED to specify a table with names of your running programs
	return threadlist[#threadlist]
end

function shell.startServ(k, args)
	local n, err = thread.new(k, nil, nil, nil, nil, nil, nil, nil, nil, args)
	if not n then
		return false, err
	else
		tasks = n.next
		return true
	end
end
function shell.stopServ(name)

	for _, a in ipairs(tasks) do
		if a.file == tostring(name) then
			thread.kill(a)
			return true
		end
	end
	return false
end

_G['shell'] = shell

function printError(str)
	local c = term.getTextColor()
	term.setTextColor(colors.red)
	print(str)
	term.setTextColor(c)
end

local services = lib.serv.giveList()

if flag.text == true then
	services = {
	  [ "/sys/cmdbak" ] = "core",
	  [ "/sys/redn" ] = false,
	}
end



for _, a in pairs(services) do
	if a == true then
		if _ == "/sys/cmdbak" then
			_ = _
		elseif string.find(_, "/", 1, 1) then
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
		if not string.find(_, "/", 1, 1) then
			_ = "/etc/services.d/".._
		end
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
			maintask = n.uid
			tasks = n.next
			sleep(0.5)

		end
	end
end



while true do
	local ok, err = pcall(thread.runAll, tasks)
	if not ok then
		flag.STATE_CRASHED = err
	end
	local ok, err = thread.getError()
	if ok ~= "noError" then
		printError(err)
	end
	if #tasks < 1 or tasks[maintask].dead then
		flag.STATE_DEAD = true
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