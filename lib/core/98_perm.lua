--[[
--		cLinux permission library
--
--
--~Piorjade
--]]

local oldfs = fs
local serialization = require("serialization")
local sha = require("sha-256")
_G.perm = {}
local users = {}
local perm_filesystem = {
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
}
-- Default root user (password is toorroot hard-coded in case there is no users file)
local currentUser, currentPassword = "root", "C812B3C9507E06610998EEDA309E9C4A733A04A8EDE09427EDC705E6802AD7AE"

if not oldfs.exists("/etc/perm.conf.d/users") then
  log.print(log.type.INFO, "perm.lua", "/etc/perm.conf.d/users does not exist, creating...")
  users["root"] = {}
  users.root.password = "C812B3C9507E06610998EEDA309E9C4A733A04A8EDE09427EDC705E6802AD7AE"
  local str_users = serialization.serialize(users)
  local file, err = oldfs.open("/etc/perm.conf.d/users", "w")
  if not file then
    log.log(log.type.ERROR, "perm.lua", "Could not create users file: "..tostring(err))
    log.print(log.type.ERROR, "perm.lua", "Could not create users file: "..tostring(err))
    os.sleep(2)
    return false
  end
  file.write(str_users)
  file.close()
end
