--[[
--		cLinux permission library
--
--
--~Piorjade
--]]

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
	INVALID_PARAMETERS = 4
}

local users = {}
--	TODO: This is unused, as it is (or should be) implemented by the filesystem drivers that we'll use
--[[local perm_filesystem = {
  ["/boot"] = {
    type = "directory",
    owner = "root"
  },
  ["/boot/clinux.lua"] = {
    type = "file",
    owner = "root"
  },
  ["/etc"] = {
    type = "directory",
    owner = "root"
  },
  ["/etc/perm.conf.d"] = {
    type = "directory",
    owner = "root"
  },
  ["/lib"] = {
    type = "directory",
    owner = "root"
  },
  ["/lib/core"] = {
    type = "directory",
    owner = "root"
  }
}]]
-- Default root user (password is toorroot hard-coded in case there is no users file)
local currentUser, currentPassword = "root", "C812B3C9507E06610998EEDA309E9C4A733A04A8EDE09427EDC705E6802AD7AE"

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

function _G.perm.isRoot()
	if currentUser == "root" then return true else return false end
end

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

function _G.perm.getUser()
	return currentUser
end

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
	local enc_pw = tostring(sha.sha56(pw..user))
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
