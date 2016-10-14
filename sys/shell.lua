

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
thread = sThread
term.setCursorPos(1,1)
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()
_put('rednet', lib.rednet)


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
	blacklist = {'rawget', 'rawset', 'dofile'}	--things that shouldn't get added, and extras
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
	elseif fs.exists(curPath.."/"..p) and fs.isDir(curPath.."/"..p) then
		curPath = curPath.."/"..p
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
function shell.getRunningProgram()
	return shell.dir()
end
function shell.openTag()
	return nil
end
function shell.switchTab()
	return nil
end
--[[function shell.complete(s)
	local a = fs.list("/bin/")
	local c = {}
	for _, b in ipairs(a) do
		local i, j = string.find(b, s)
		if i == 1 then
			table.insert(c, b)
		end
	end
	return c
end]]
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
			maintask = n.uid
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
	if #tasks < 1 or tasks[maintask].dead then
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
