--[[
	cLinux: Ran out of lores... already
	Made by Piorjade, daelvn

	NAME:        /lib/sThread.l
	CATEGORY:    library
	SET:         Native Libraries I
	VERSION:     01:alpha0
	DESCRIPTION: 
		Manages the coroutines, used in shell.
]]--



sThread = {}

local errors = {
	ok = "noError",
	err = nil,
}
local started = {}
local running = {}
local last_uid = 0

function sThread.getStatus(tasklist, uid)
	if tasklist[uid] then
		return tasklist[uid].status
	else
		return nil
	end
end


function sThread.new(file, uid) --extra is a table with extra things that should be removed from the env
	uid = uid or last_uid + 1
	last_uid = last_uid + 1
	extra = extra or {}
	local self = {}
	self.uid = uid
	local function _copy(a, b)
		for k, v in pairs(a) do
			b[k] = v
		end
	end
	self.env = {}
	_copy(_G, self.env)
	blacklist = {'rawget', 'rawset', 'dofile', '_G'}	--things that shouldn't get added, and extras
	for k, v in ipairs(blacklist) do self.env[v] = nil end
	self.task, err = loadfile(file)
	
	if not self.task then
		return false, err
	end
	setfenv(self.task, self.env)
	self.thread = coroutine.create(self.task)
	self.file = file
	self.filter = nil
	self.error = nil
	self.dead = false
	self.status = "suspended"
	self.queue = {}
	self.resume = function(...)
		local fst = {...}
		--if self.filter == nil or fst[1] == self.filter then
			ok, err = coroutine.resume(self.thread, unpack(fst))
				
			if ok then
				self.filter = err
				self.status = coroutine.status(self.thread)
				if self.status == "dead" then self.dead = true end
				return ok, err
			else
				self.status = coroutine.status(self.thread)
				if self.status == "dead" then self.dead = true end
				return ok, err
			end
		--end
	end
	started[self.uid] = self
	self.next = started
	return self
end

function sThread.queue(process, event, parameters)
	process.queue[#process.queue+1] = {event = event, parameters = parameters}
	return true
end
 
function sThread.kill(process)
	process.dead = true
	process.status = "dead"
	sThread.queue(process, "sig:terminate", {})
end

function sThread.killAll(tasklist)
	if not flag.STATE_SHUTDOWN or not flag.STATE_RESTART then return false end
	for uid, task in pairs(tasklist) do
			sThread.kill(task)
	end
end

function sThread.getError()
	if errors.ok ~= "noError" then
		local oldok, olderr = errors.ok, errors.err
		errors.ok, errors.err = "noError", nil
		return oldok, olderr
	else
		return "noError"
	end
end

function sThread.runAll(tasklist)
	evt = {"key", keys.l}
	while true do
		for uid, task in ipairs(tasklist) do
			if task.dead then
				tasklist[uid] = nil
				last_uid = #tasklist
			else 
				ok, err = task.resume(unpack(evt))
				if ok == nil or ok == true then
					
				else
					errors.ok = ok
					errors.err = err
					tasklist[uid] = nil
					last_uid = #tasklist
					--[[if uid == 1 then
						flag.STATE_DEAD = true
						return false, ok
					end]]
				end
			end
		end
		if #tasklist < 1 then
			break
		end
		evt = {os.pullEventRaw()}
	end
	return
end