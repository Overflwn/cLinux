--[[
--		cLinux permission library
--
--
--~Overflwn
--]]

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

local oldfs = fs
local serialization, err = require("serialization")
if not serialization then
	return false, log.print(log.type.ERROR, "perm.lua", "Failed to load serialization: "..tostring(err))
end
local sha, err = require("sha-256")
if not sha then
	return false, log.print(log.type.ERROR, "perm.lua", "Failed to load sha: "..tostring(err))
end
_G.perm = {}

-- Status codes for returning
_G.perm.status = {
	SUCCESS = 0,
	USER_NOT_FOUND = 1,
	WRONG_PW = 2,
	USER_FOUND = 3,
	INVALID_PARAMETERS = 4,
	ILLEGAL_SESSION = 5
}

local users = {}
local sessionMeta = {}
-- TODO: Prevent counterfeit sessions
local sessions = {}
-- Default root user (password is toor (salted with root) hard-coded in case there is no users file) TODO: Deprecated, use new session system
--local currentUser, currentPassword = "root", "C812B3C9507E06610998EEDA309E9C4A733A04A8EDE09427EDC705E6802AD7AE"

-- Get the list of users and if non-existend: create the file with root user
if not oldfs.exists("/etc/perm.conf.d/users") then
  log.printAndLog(log.type.INFO, "perm.lua", "/etc/perm.conf.d/users does not exist, creating...")
  users["root"] = {}
  users.root.password = "C812B3C9507E06610998EEDA309E9C4A733A04A8EDE09427EDC705E6802AD7AE"
	users.root.group = ""
	users.root.homedir = "/root"
  local str_users = serialization.serialize(users)
  local file, err = oldfs.open("/etc/perm.conf.d/users", "w")
  if not file then
    log.printAndLog(log.type.ERROR, "perm.lua", "Could not create users file: "..tostring(err))
    os.sleep(2)
    return false
  end
  fs.write(file, str_users)
  fs.close(file)
else
	log.printAndLog(log.type.INFO, "perm.lua", "/etc/perm.conf.d/users found, loading...")
	local file, err = oldfs.open("/etc/perm.conf.d/users", "r")
	if not file then
		log.printAndLog(log.type.ERROR, "perm.lua", "Could not load users file: "..tostring(err))
		os.sleep(2)
		return false
	end
	local data = ""
	repeat
		local d = fs.read(file, 10000)
		if type(d) == "string" and #d > 0 then
			data = data..d
		end
	until d == "" or d == nil
	fs.close(file)
	users = serialization.unserialize(data)
end

function _G.perm.createSession()
	-- TODO: WIP
	--[[
		Goal:
				Create a session-based permission system.
	]]
	local user = ""
	local password = ""
	local loggedIn = false
	local opened = true
	local session = {}
	-- Get the unique ID of this lua table (memory address?) to identify it later on
	local unique_id = string.sub(tostring(session), 8)
	function session.isLoggedIn()
		return loggedIn
	end

	function session.logIn(usr, pw)
		local succ = perm.checkPassword(usr, pw)
		if succ == perm.status.USER_NOT_FOUND then
			return succ
		elseif succ == perm.status.WRONG_PW then
			return succ
		else
			user = usr
			password = tostring(sha.sha256(pw..usr))
			return succ
		end
	end

	function session.isRoot()
		if user == "root" then return true else return false end
	end

	function session.getUser()
		return user
	end

	function session.hasAccess(path)
		if oldfs.getOwner(path) == user or user == "root" then
			return true
		else
			return false
		end
	end

	function session.close()
		-- Completely close the session, I guess it is not needed itself but
		--		it frees some space in the sessions table.
		-- Counterfeit sessions obviously don't get closed anyway
		if opened then
			loggedIn = false
			opened = false
			for each, s in ipairs(sessions) do
				if s == unique_id then
					table.remove(sessions, each)
					return perm.status.SUCCESS
				end
			end
			return perm.status.ILLEGAL_SESSION
		else
			return perm.status.SUCCESS
		end
	end

	function session.getID()
		return unique_id
	end

	table.insert(sessions, unique_id)
	return readonlytable(session)
end

function _G.perm.isSessionLegal(t)
	-- Check if the given session / table is registered
	-- This counters counterfeit sessions lol
	-- Get the unique id
	local given_id = t.getID()
	for each, id in ipairs(sessions) do
		if id == given_id then
			return perm.status.SUCCESS
		end
	end
	return perm.status.ILLEGAL_SESSION
end

--[[ TODO: Deprecated, use new session system
function _G.perm.isRoot()
	if currentUser == "root" then return true else return false end
end
]]

function _G.perm.getUsers()
	local list = {}
	for name, pw in pairs(users) do
		table.insert(list, name)
	end
	return list
end

function _G.perm.userExists(name)
	if users[name] then
		return true
	else
		return false
	end
end

--[[ TODO: Deprecated, use new session system
function _G.perm.getUser()
	return currentUser
end
]]

function _G.perm.getUserGroup(name)
	return users[name].group
end

function _G.perm.getUserHomeDir(name)
	return users[name].homedir
end

function _G.perm.checkPassword(user, pw)
	if not users[user] then
		return perm.status.USER_NOT_FOUND
	end
	local enc_pw = string.upper(tostring(sha.sha256(pw..user)))
	if users[user].password == enc_pw then
		return perm.status.SUCCESS
	else
		return perm.status.WRONG_PW
	end
end

function _G.perm.createUser(user, pw, group)
	if type(user) ~= "string" or #user < 1 or type(pw) ~= "string" or #pw < 1 then
		return perm.status.INVALID_PARAMETERS
	end
	if users[user] then
		return perm.status.USER_FOUND
	end
	local enc_pw = tostring(sha.sha256(pw..user))
	users[user].password = enc_pw
	users[user].group = group or ""
	users[user].homedir = "/home/"..user
	return perm.status.SUCCESS
end

--[[ TODO: Deprecated, use new session system
function _G.perm.switchUser(user, pw)
	if _G.perm.checkPassword(user, pw) == perm.status.SUCCESS then
		currentUser = user
		pw = tostring(sha.sha256(user..pw))
		return perm.status.SUCCESS
	else
		return perm.checkPassword(user, pw)
	end
end

function _G.perm.hasAccess(path)
	if oldfs.getOwner(path) == currentUser or currentUser == "root" then
		return true
	else
		return false
	end
end
]]
