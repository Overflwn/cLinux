--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /lib/perm.l
	CATEGORY:    Library
	SET:         Core Library
	VERSION:     01:alpha0
	DESCRIPTION: 
		This script is manages users and their permissions.
		Most of these functions are selfexplaining.
]]--

local sha = os.loadAPI("/lib/sha.l")

local forbidden = {"/vit", "/boot"}
local perm = {}


if not _check(_users) then
	_G._users = {}
end

function hashPw(p, salt)
	return tostring(sha.pbdk2(p, salt, 10):toHex())
end

_put('hashPw', hashPw)

local usrs = {}

function usrs.addUser(name, pw)
	if _users[name] then return false end
	pw = hashPw(pw, name)
	_users[name] = pw
	old.fs.makeDir("/home/"..name)
	return true
end

function usrs.removeUser(name, rpw)
	if name == nil or rpw == nil then return end
	if _users[name] then
		local rpw = hashPw(rpw, "root")
		local a = perm.checkRootPw(rpw)
		if a == false then
			return false
		elseif a == true then
			old.fs.delete("/home/"..name)
			_users[name] = nil
		end
	else
		return nil
	end
end

function usrs.changePw(name, oldPw, newPw)
	if name == nil or oldPw == nil or newPw == nil then return nil end
	if _users[name] then
		local oldPw = hashPw(oldPw, name)
		if oldPw == _users[name] then
			local nPw = hashPw(newPw, name)
			_users[name] = nPw
		else
			return false
		end
	else
		return nil
	end
end

local permission = {}

function permission.check(name, f, wx)
	for each, folder in ipairs(forbidden) do
		if folder == f and name ~= "root" then return false end	--Not finished
	end

	local fldrs = _fs.scanFs()
	for _, a in pairs(fldrs) do
		if _ == f then
			if fldrs[_]['owner'] ~= "root" then
				return "w"
			elseif fldrs[_]['owner'] == "root" then
				return "x"
			end
		end
	end
	return nil
end



perm = {permission, usrs}
_put('perm', perm)