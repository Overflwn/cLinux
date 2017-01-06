--[[
	cLinux: Ran out of lores... already
	Made by Piorjade, daelvn

	NAME:        /sys/sThread.l
	CATEGORY:    library
	SET:         Native Libraries I
	VERSION:     01:alpha0
	DESCRIPTION:
		Manages the coroutines, used in shell. (mainly services)

		PLEASE USE /lib/thread.l FOR YOUR PROGRAMS, WAY BETTER
]]--



sThread = {}

local errors = {
	ok = "noError",
	err = nil,
}
local started = {}
local windows = {}
local last_uid = 0
local mainwindow = nil
local mainuid = nil
local lastx, lasty = 1, 1

function sThread.getStatus(tasklist, uid)
	if tasklist[uid] then
		return tasklist[uid].status
	else
		return nil
	end
end


function sThread.new(file, uid, fg, width, height, parent, main, lx, ly, args) --fg is a boolean if the process should show term drawing
	if fg == nil then
		fg = true
	end
	if main == nil then
		main = false		--main indicates if that thread is the core window, for example the commandline
	end
	uid = uid or last_uid + 1
	last_uid = last_uid + 1
	extra = extra or {}
	local self = {}
	self.main = false
	self.lastx, self.lasty = 1, 1
	if width ~= nil then
		if parent == nil then
			parent = mainwindow
		end
		self.window = window.create(parent, 1, 1, width, height, fg)
		self.window.clear()
	end
	if main == true then
		self.main = true
		mainuid = uid
		mainwindow = self.window
		if lx ~= nil then
			self.lastx = lx
		else
			self.lastx = 1
		end
		if ly ~= nil then
			self.lasty = ly
		else
			self.lasty = 1
		end
		lastx = self.lastx
		lasty = self.lasty
	else
		self.main = false
	end

	self.uid = uid
	local function _copy(a, b)
		for k, v in pairs(a) do
			b[k] = v
		end
		for k, v in pairs(_G.lib) do
			b['lib'][k] = v
		end
	end
	self.env = {}

	_copy(_G, self.env)
	blacklist = {'rawget', 'rawset', 'dofile', 'sThread','old'}	--things that shouldn't get added, and extras
	for k, v in ipairs(blacklist) do self.env[v] = nil end
	setmetatable(self.env, {__index = _G.lib})
	if not fs.exists(file) then
		return false, "File not found."
	end
	self.task, err = loadfile(file)

	if not self.task then
		return false, err
	end
	--setfenv(self.task, self.env)
	self.thread = coroutine.create(self.task)
	self.file = tostring(file)
	self.filter = nil
	self.error = nil
	self.dead = false
	self.status = "suspended"
	self.queue = {}
	if args then
		self.args = args
	else
		self.args = nil
	end
	self.resume = function(...)
		local fst = {}
		if not self.args then
			fst = {...}
		else
			fst = {unpack(self.args)}
			self.args = nil
		end
		if not self.dead then
			ok, err = coroutine.resume(self.thread, unpack(fst))
			self.lastx, self.lasty = term.getCursorPos()
			if self.main == true then
				lastx = self.lastx
				lasty = self.lasty
			end
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
		else
			return false, "is dead"
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
		if #tasklist < 1 then
			break
		end
		for uid, task in ipairs(tasklist) do
			if task.dead then
				table.remove(tasklist, uid)
				last_uid = #tasklist
			else
				ok, err = task.resume(unpack(evt))
				if ok == nil or ok == true then

				else
					errors.ok = ok
					errors.err = err
					table.remove(tasklist, uid)
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

_put('sThread', sThread)