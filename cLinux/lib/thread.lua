--[[
		cLinux Thread Library

	Threading/Multitasking library

	TODO:
		This is not tested and even implemented yet, do that

    ~Overflwn
]]

local thread = {}
local status = {
	SUCCESS = 0,
	INVALID_PARAMETERS = 1,
	FUNCTION_ERROR = 2,
	THREAD_DEAD = 3
}

local function readonlytable(table)
	-- Create a read-only proxy of the given table
	return setmetatable({}, {
		__index = table,
		__newindex = function(table, key, value)
			error("Attempt to modify read-only table")
		end,
		__metatable = false
	})
end

thread.status = readonlytable(status)

function thread.newThreadList()
	local threads = {}
	local last_pid = 0
	local threadList = {}

	function threadList.newThread(user, func, env, io_in, io_out)
		-- Create a new thread with the given function and custom I/O buffers

		if type(user) ~= "string" then return status.INVALID_PARAMETERS end
		if type(io_in) ~= "table" or type(io_out) ~= "table" then return status.INVALID_PARAMETERS end

		local c, err = coroutine.create(func)
		if not c then return status.FUNCTION_ERROR, err end
		local the_pid = last_pid+1
		last_pid = last_pid+1
		local killed = false
		local nthread = {}
		nthread = setmetatable(nthread, {
			__index = env
		})
		nthread["_G"] = nthread
		if nthread.io then
			-- I/O redirection
			-- TODO: Probably broken
			io.input(io_in)
			io.output(io_out)
		end
		function nthread.getPID()
			return the_pid
		end

		function nthread.status()
			local stat = coroutine.status(c)
			if killed then
				return "dead"
			else
				return stat
			end
		end

		function nthread.resume(e)
			-- Resume the coroutine with the given arguments (which should be inside a table)
			if not killed then
				local succ, err = coroutine.resume(unpack(e))
				return succ, err
			else
				return false, status.THREAD_DEAD
			end
		end

		function nthread.kill()
			killed = true
		end
		table.insert(threads, nthread)
	end

	function threadList.iterator()
		local i = 1
		local n = table.getn(threads)
		return function()
			i = i+1
			if i <= n then return threads[i] end
		end
	end

	function threadList.getFromPID(pid)
		for each, thread in ipairs(threads) do
			if thread.getPID() == pid then
				return thread
			end
		end
		return nil
	end

	function threadList.clean()
		-- Delete killed threads
		-- TODO: Maybe not safe
		local toDelete = {}
		for each, thread in ipairs(threads) do
			if thread.status() == "dead" then
				table.insert(toDelete, each)
			end
		end
		table.sort(toDelete)
		for i=table.getn(threads), 1, -1 do
			for a, b in ipairs(toDelete) do
				if b == i then
					table.remove(threads, i)
					table.remove(toDelete, a)
					break
				end
			end
		end
	end

	return threadList
end
