--[[
    Filesystem manager

  Load up drivers for filesystems to be able to interact with different
  ComputerCraft-HD-Formats.

  Drivers are currently expected to have these methods:

  driver:createNewHD(path) --Create a new (virtual, of course) hard drive, load it and additionally save it to the specified path
  driver:loadHD(path) --Load the hard drive from the specified path
  driver:saveToFile(path) --Save the currently loaded hard drive to the specified path

  driver:open
  driver:write
  driver:read
  driver:close

  driver:makeDir

  driver:delete

  driver:list

  driver:getOwner	--Get the name of the user that owns that file/directory
  driver:getOwnerGroup	--Get the name of the group that own(s) that file/directory
  driver:setOwner	--Set the name of the user that owns that file/directory
  driver:setOwnerGroup	--Set the name of the group(s) that own(s) that file/directory

  driver:exists

  driver:isDir

  driver.split

  This does not mean that you can't add
  even more methods or have different parameters/return values,
  as this manager allows to use the raw driver aswell.

~Piorjade

]]

local drivers = {}

_G.fs_mgr = {}

fs_mgr.path = "/hd"

for each, file in ipairs(fs.list("fs_drivers")) do
  local func, err = loadfile("fs_drivers/"..file)
  if not func then
    print("Could not load "..file..": "..tostring(err))
  else
    local _, driver = pcall(func)
    if not _ then
      print("Could not load "..file..": "..tostring(driver))
    else
      print("Loaded driver: "..file)
      drivers[file] = driver
    end
  end
end

function fs_mgr:setDriver(name, newPath)
  if not drivers[name] then
    return false, "no such driver"
  end
  if self.driver ~= nil then
    self.driver:saveToFile(self.path)
  end
  self.path = newPath
  self.driver = drivers[name]
  self.driver:createNewHD(newPath)
  return true
end

function fs_mgr.open(...)
  return fs_mgr.driver:open(...)
end

function fs_mgr.write(...)
  return fs_mgr.driver:write(...)
end

function fs_mgr.read(...)
  return fs_mgr.driver:read(...)
end

function fs_mgr.close(...)
  return fs_mgr.driver:close(...)
end

function fs_mgr.makeDir(...)
  return fs_mgr.driver:makeDir(...)
end

function fs_mgr.delete(...)
  return fs_mgr.driver:delete(...)
end

function fs_mgr.list(...)
  return fs_mgr.driver:list(...)
end

function fs_mgr.getOwner(...)
  return fs_mgr.driver:getOwner(...)
end

function fs_mgr.getOwnerGroup(...)
  return fs_mgr.driver:getOwnerGroup(...)
end

function fs_mgr.setOwner(...)
  return fs_mgr.driver:setOwner(...)
end

function fs_mgr.setOwnerGroup(...)
  return fs_mgr.driver:setOwnerGroup(...)
end

function fs_mgr.exists(...)
  return fs_mgr.driver:exists(...)
end

function fs_mgr.isDir(...)
  return fs_mgr.driver:isDir(...)
end

function fs_mgr.split(...)
  return fs_mgr.driver.split(...)
end
