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

--Define thead table (containing the main functions)
local thread = {}
local tasks = {}
local last_uid = -1
--Function to create a new thread
function thread.new(p, env, name)
	if not p then return end
	if not env then return end
	if not name then
		name = tostring(p)
	end
	--load p as function, if it's a path (string)
	if not type(p) == "function" then
		if type(p) == "string" then
			p, err = loadfile(p)
			if not p then
				return false, err
			end
		else
			return false, "function expected, got "..type(p)
		end
  end
	local uid = last_uid+1
	last_uid = last_uid+1
	--define self, containing important functions and variables
	local self = {}
	--set self.function as p, with a new environment
	self.function = load(p, nil, "t", env)
	self.task = coroutine.create(self.function)
	self.dead = false
	self.uid = uid
	self.filter = nil
	function self.resume(...)
		local fst = {...}
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
		else
			return false, "is dead"
		end
	end
	--insert self into tasks (with uid (as string) as key)
	tasks[tostring(self.uid)] = self
	return true
end
--resume a specific uid (give uid as string)
function thread.resume(uidstr, ...)
	local targs = {...}
	local ok, err = tasks[uidstr].resume(table.unpack(targs))
	if not ok then
		return false, err
	else
		return true
	end
end
--resume all tasks, with optionally given arguments/events
function thread.resumeAll(...)
	local tArgs = {...}
	for k, v in pairs(tasks) do
		if not v.dead then
			local ok, err = v.resume(table.unpack(tArgs))
			if not ok then
				cLinuxPrintError(err)
			end
		end
	end
end
