--[[
	cLinux: Ran out of lores... already
	Made by Piorjade, daelvn

	NAME:        /sys/thread.l
	CATEGORY:    library
	SET:         Core Libraries I
	VERSION:     01:alpha0
	DESCRIPTION:
		Manages the coroutines, used in
		the TLCO.
		(This is only locally to the TLCO)
]]--

--Define thread table (containing the main functions)
local thread = {}
--Function to create a new thread
function thread.new(p, env, name, tasklist, tArgs)
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
	self.func = p
	self.task = coroutine.create(self.func)
	self.dead = false
	self.name = name
	self.uid = uid
	self.filter = nil
	--resume/start the coroutine (function/file)
	--saveArgs is to store the arguments and execute the program after resume is being called the 2nd time
	function self.resume(args)
		local fst = args
		local stat = coroutine.status(self.task)
		if stat == "dead" then self.dead = true end
		if not self.dead and self.filter == nil or not self.dead and self.filter == fst[1] then
			local ok, err = coroutine.resume(self.task, table.unpack(fst))
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
	end
	--insert self into tasks (with uid (as string) as key)
	table.insert(tasklist.list, self)

	return true
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
--resume all tasks, with optionally given arguments/events
function thread.resumeAll(tasklist, tArgs)
	for k, v in ipairs(tasklist.list) do
		if not v.dead then
			local ok, err = v.resume(tArgs)
			if ok == false then
				cLinuxPrintError(v.name, err)
				return false
			end
		end
	end
end


_put("thread", thread)
