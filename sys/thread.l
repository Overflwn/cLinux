--[[
	cLinux: Ran out of lores... already
	Made by Piorjade, daelvn

	NAME:        /sys/thread.l
	CATEGORY:    library
	SET:         Core Libraries I
	VERSION:     09:beta2
	DESCRIPTION:
		Manages coroutines of a GIVEN tasklist
		The tasklist should look like the following:

		mytasklist = {
			last_uid = 0,
			somethingInFG = false,
			list = {},
		}



		Almost every function needs the tasklist to work.
]]--

--Define thread table (containing the main functions)
local thread = {}
--Function to create a new thread
function thread.new(p, env, name, tasklist, tArgs, logfunc)
	if not p then return end
	if not env then return end
	if not name then
		name = tostring(p)
	end
	--load p as function, if it's a path (string)
	if type(p) ~= "function" then
		if type(p) == "string" then
			p, err = loadfile(p)
			if not p then
				return false, err
			end
		else
			return false, "function expected, got "..type(p)
		end
  end
	local uid = tasklist.last_uid+1
	tasklist.last_uid = tasklist.last_uid+1
	--define self, containing important functions and variables
	local self = {}
	--set self.function as p, with a new environment
	setfenv(p, env)
	local tAPIsLoading = {}
	function env.os.loadAPI( _sPath )
			print("Loading ".._sPath)
			sleep(2)
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
			env[sName] = tAPI
			_G[sName] = tAPI
	    return true
	end
	self.func = p
	self.task = coroutine.create(self.func)
	self.dead = false
	self.name = name
	self.background = true



	--get the current user and save his data
	if logfunc ~= nil then
		self.userName, self.userPassword = logfunc.name, logfunc.password
	end

	self.uid = uid
	self.filter = nil
	--resume/start the coroutine (function/file)
	--saveArgs is to store the arguments and execute the program after resume is being called the 2nd time
	function self.resume(args)
		local fst = args
		if self.startArgs ~= nil then
			fst = self.startArgs
			self.startArgs = nil
		end
		local stat = coroutine.status(self.task)
		if stat == "dead" then self.dead = true end
		if not self.dead and self.filter == nil or not self.dead and self.filter == fst[1] then
			if self.userName ~= nil then
				lib.perm.permission.saveOld()
				lib.perm.permission.login(self.userName, self.userPassword, true)
			end
			local ok, err = coroutine.resume(self.task, table.unpack(fst))
			if self.userName ~= nil then
				lib.perm.permission.reLog()
			end
			if ok then
				local stat = coroutine.status(self.task)
				if stat == "dead" then
					self.dead = true
				else
					self.filter = err
				end
			else
				return false, err
			end
		elseif self.dead then
			return false, "is dead"
		end
	end
	if tArgs ~= nil then
		env['startArgs'] = tArgs
		self.startArgs = tArgs
	end
	--insert self into tasks
	table.insert(tasklist.list, self)
	return true, uid
end
--resume a specific task (by given name)
function thread.resume(name, tasklist, ...)
	for uid, v in ipairs(tasklist.list) do
		if v.name == name then
			local targs = {...}
			local ok, err = tasklist.list[uid].resume(table.unpack(targs))
			if not ok then
				return false, err
			else
				return true
			end
			break
		end
	end

end

--search thread by name and return status
function thread.getStatus(name, tasklist)
	for k, v in ipairs(tasklist.list) do
		if v.name == name then
			if v.dead then
				return "dead"
			else
				return "yielding"
			end
		end
	end
	return nil
end

--kill a task, in the given tasklist of course, with the UID as number

function thread.kill(tasklist, uid)
	--check if the uid is a string, convert to number
	if type(uid) == "string" then uid = tonumber(uid) end
	if uid == nil then return end
	for k, v in pairs(tasklist.list) do
		if v.uid == uid then
			tasklist.list[k] = nil
			return true
		end
	end
	return nil
end

--resume all tasks, with optionally given arguments/events
function thread.resumeAll(tasklist, tArgs)
	for k, v in ipairs(tasklist.list) do
		if not v.dead then
			if _G.shell then
				_G.shell.getRunningProgram = function()
					return v.name
				end
			end
			if not tasklist.somethingInFG then
				local ok, err = v.resume(tArgs)
				if ok == false then
					cLinuxPrintError(v.name, err)
					--return false
				end
			else
				if v.background == false then
					local ok, err = v.resume(tArgs)
					if ok == false then
						cLinuxPrintError(v.name, err)
						--return false
					end
					local ok = thread.getStatus(v.name, tasklist)
					if ok == "dead" then
						v.background = true
						tasklist.somethingInFG = false
						table.remove(tasklist.list, k)
					end
				end
			end
		end
	end
end


_put("thread", thread)