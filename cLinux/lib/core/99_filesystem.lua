--[[
		fs (wrapper) library

~Piorjade
]]

local newfs = {}
local oldfs = _G.fs

newfs.status = {
	FILE_NOT_FOUND = 0,
	INVALID_PARAMETERS = 1,
	SUCCESS = 2,
	ACCESS_DENIED = 3,
	USER_NOT_FOUND = 4,
	FILE_EXISTS = 5
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

function newfs.open(path, mode)
	if mode ~= "w" and mode ~= "r" and mode ~= "a" then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if oldfs.exists(path) then
		if perm.hasAccess(path) then
			return oldfs.open(path, mode, perm.getUser(), perm.getUserGroup(perm.getUser()))
		else
			return false, newfs.status.ACCESS_DENIED
		end
	else
		local parts = oldfs.split(path, "/")
		table.remove(parts)
		local connected=""
		for each, part in ipairs(parts) do
			connected = connected.."/"..part
		end
		if perm.hasAccess(connected) then
			return oldfs.open(path, mode, perm.getUser(), perm.getUserGroup(perm.getUser()))
		else
			return false, newfs.status.ACCESS_DENIED
		end
	end
end

newfs.write = oldfs.write
newfs.read = oldfs.read
newfs.close = oldfs.close
newfs.exists = oldfs.exists
newfs.isDir = oldfs.isDir
newfs.list = oldfs.list
newfs.split = oldfs.split
function newfs.setOwner(path, owner, ...)
	if type(owner) ~= "string" or #owner < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	if not perm.userExists(owner) then return false, newfs.status.USER_NOT_FOUND end
	if not perm.hasAccess(path) then return false, newfs.status.ACCESS_DENIED end
	return oldfs.setOwner(path, owner, ...)
end

function newfs.setOwnerGroup(path, owner, ...)
	if type(owner) ~= "string" or #owner < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	if not perm.userExists(owner) then return false, newfs.status.USER_NOT_FOUND end
	if not perm.hasAccess(path) then return false, newfs.status.ACCESS_DENIED end	
	return oldfs.setOwnerGroup(path, owner, ...)
end

function newfs.getOwner(path)
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	return oldfs.getOwner(path)	
end

function newfs.getOwnerGroup(path)
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	return oldfs.getOwnerGroup(path)	
end

function newfs.makeDir(path)
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if newfs.exists(path) then return false, newfs.status.FILE_EXISTS end
	local parts = oldfs.split(path, "/")
	table.remove(parts)
	local connected=""
	for each, part in ipairs(parts) do
		connected = connected.."/"..part
	end
	if not newfs.exists(connected) then return false, newfs.status.INVALID_PARAMETERS end
	if not perm.hasAccess(connected) then return false, newfs.status.ACCESS_DENIED end
	return oldfs.makeDir(path, perm.getUser(), perm.getUserGroup(perm.getUser()))
end

function newfs.delete(path, ...)
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	
	if not perm.hasAccess(path) then return false, newfs.status.ACCESS_DENIED end
	return oldfs.delete(path, ...)
end

function newfs.makeLink(path, path2)
	--Path
	if type(path) ~= "string" or #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
	if string.sub(path, #path) == "/" then path = string.sub(path, 1, #path-1) end
	if #path < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if not newfs.exists(path) then return false, newfs.status.FILE_NOT_FOUND end
	
	--Path2
	if type(path2) ~= "string" or #path2 < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if string.sub(path2, 1, 1) == "/" then path2 = string.sub(path2, 2) end
	if string.sub(path2, #path2) == "/" then path2 = string.sub(path2, 1, #path2-1) end
	if #path2 < 1 then return false, newfs.status.INVALID_PARAMETERS end
	if newfs.exists(path2) then return false, newfs.status.FILE_EXISTS end
	local parts = oldfs.split(path2, "/")
	table.remove(parts)
	local connected=""
	for each, part in ipairs(parts) do
		connected = connected.."/"..part
	end
	if not newfs.exists(connected) then return false, newfs.status.INVALID_PARAMETERS end
	if not perm.hasAccess(connected) then return false, newfs.status.ACCESS_DENIED end
	return oldfs.driver:makeLink(path, path2, perm.getUser(), perm.getUserGroup(perm.getUser()))
end

function newfs.readAll(handle)
	local data = ""
	repeat
		local d = newfs.read(handle, 10000)
		if type(d) == "string" and #d > 0 then
			data = data..d
		end
	until d == "" or d == nil
	return data
end

--Just testing things out
_G.fs = readonlytable(newfs)
