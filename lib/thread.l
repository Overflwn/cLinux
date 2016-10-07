--[[
	cLinux: Ran out of lores... already
	Made by Piorjade, daelvn

	NAME:        /lib/thread.l
	CATEGORY:    library
	SET:         Native Libraries I
	VERSION:     01:alpha0
	DESCRIPTION: 
		Manages the coroutines, used in
		the TLCO.
]]--

thread = {}

local started = {}
local running = {}
local last_uid = 0

function thread.getStatus(uid)
	if started[uid] then
		return started[uid].status
	else
		return nil
	end
end


function thread.new(file, uid)
	uid = uid or last_uid + 1
	last_uid = last_uid + 1

	local self = {}
	self.uid = uid
	local function _copy(a, b)
		for k, v in pairs(a) do
			b[k] = v
		end
	end
	self.env = {}
	_copy(_G, self.env)
	blacklist = {'rawget', 'rawset', 'dofile', '_G'}
	for k, v in pairs(blacklist) do self.env[k] = nil end
	self.task = loadfile(file, nil, self.env)
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
			else
				printError("Error: "..tostring(ok).." "..tostring(err))
				sleep(2)
				self.status = coroutine.status(self.thread)
				if self.status == "dead" then self.dead = true end
				return err
			end
		--end
	end
	started[self.uid] = self
	self.next = started
	return self
end

function thread.queue(process, event, parameters)
	process.queue[#process.queue+1] = {event = event, parameters = parameters}
	return true
end
 
function thread.kill(process)
	process.dead = true
	process.status = "dead"
	thread.queue(process, "sig:terminate", {})
end

function thread.killAll(tasklist)
	if not flag.STATE_SHUTDOWN or not flag.STATE_RESTART then return false end
	for uid, task in pairs(tasklist) do
			thread.kill(task)
	end
end

function thread.runAll(tasklist)
	evt = {"key", keys.l}
	while true do
		
		for uid, task in ipairs(tasklist) do
			if task.dead then
				table.remove(tasklist, uid)
			else 
				local ok = task.resume(unpack(evt))
				if ok == nil or ok == true then
				else
					table.remove(tasklist, uid)
					flag.STATE_DEAD = true
					return false, ok
				end
			end
		end
		if #tasklist < 1 then
			flag.STATE_DEAD = true
			break
		end
		evt = {os.pullEventRaw()}
	end
	return
end