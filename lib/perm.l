

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
local old = {}
old['fs'] = fs
local sha = os.loadAPI("/lib/sha.l")
local forbidden = {"/boot", "/vit", "/bin", "/startup", "/sys"}
local perm = {}
local name = ""
local password = ""
local oldname = ""
local oldpassword = password
local _users = nil

if _users == nil then
	_users = {}
	print("No users")
	local file = old.fs.open("/sys/usrData", "r")
	local inhalt = file.readAll()
	_users = textutils.unserialize(inhalt)
	file.close()
	
end

function hashPw(p, salt)
	local str = pbkdf2(p, salt, 10):toHex()
	return tostring(str)
end

_put('hashPw', hashPw)

local usrs = {}

function usrs.getList()
	local inhalt = {}
	
	for k, v in pairs(_users) do
		table.insert(inhalt, k)
	end
	return inhalt
end

local function setUsr(n, p)
	name = n
	password = p
end

function usrs.addUser(name, pw)
	if _users[name] or name == "root" then return false end
	local i = usrs.getList()
	local oldname = name
	local oldpw = password
	if #i < 1 then
		local n = "root"
		local file = fs.open("/sys/.rootpw", "r")
		local p = file.readLine()
		file.close()
		setUsr(n, p)
	end
	pw = hashPw(pw, name)
	_users[name] = pw
	local file = old.fs.open("/sys/usrData", "w")
	file.write(textutils.serialize(_users))
	file.close()
	old.fs.makeDir("/home/"..name)
	setUsr(oldname, oldpw)
	return true
end

function usrs.checkRootPw(p)
	local file = old.fs.open("/sys/rootpw", "r")
	local pw = file.readLine()
	file.close()
	if p == pw then
		return true
	else
		return false
	end
end

function usrs.removeUser(name, rpw)
	if name == nil or rpw == nil or name == "root" then return end
	if _users[name] then
		local rpw = hashPw(rpw, "root")
		local a = perm.checkRootPw(rpw)
		if a == false then
			return false
		elseif a == true then
			old.fs.delete("/home/"..name)
			_users[name] = nil
			local file = old.fs.open("/sys/usrData", "w")
			file.write(textutils.serialize(_users))
			file.close()
		end
	else
		return nil
	end
end

function usrs.changePw(name, oldPw, newPw)
	if name == nil or oldPw == nil or newPw == nil then return nil end
	if _users[name] and name ~= "root" then
		local oldPw = hashPw(oldPw, name)
		if oldPw == _users[name] then
			local nPw = hashPw(newPw, name)
			_users[name] = nPw
			local file = old.fs.open("/sys/usrData", "w")
			file.write(textutils.serialize(_users))
			file.close()
		else
			return false
		end
	elseif name == "root" then
		local oldPw = hashPw(oldPw, name)
		local newPw = hashPw(newPw, name)
		if usrs.checkRootPw(oldPw) then
			local file = old.fs.open("/sys/.rootpw", "w")
			file.writeLine(newPw)
			file.close()
		else
			return false
		end
	else
		return nil
	end
end

local permission = {}

function permission.check(f)
	if folder == f and name ~= "root" then return "x" end	--Not finished
	local found = false
	for each, folder in ipairs(forbidden) do
		local i, j = string.find(f, folder)
		if i == 1 and name ~= "root" then
			found = true
			break
		else
			found = false
		end
	end
	if found then
		return "x"
	else
		return "w"
	end
	return nil
end

function permission.login(n, p)
	if n == nil or p == nil then return nil end
	p = hashPw(p, n)
	
	local file = old.fs.open("/sys/usrData", "r")
	local inhalt = file.readAll()
	file.close()
	inhalt = textutils.unserialize(inhalt)
	if n ~= "root" and inhalt[n] then
		if p == inhalt[n] then
			name = n
			password = p
			return true
		else
			return false
		end
	elseif n == "root" then
		local file = old.fs.open("/sys/.rootpw", "r")
		local rpw = file.readLine()
		file.close()
		if p == rpw then
			oldname = name
			oldpassword = password
			name = "root"
			password = p
			return true
		else
			return false
		end
	elseif inhalt[n] == nil then
		return nil
	end
end

function permission.reLog()
	if oldname then
		name = oldname
		password = oldpassword
		return true
	else
		return false
	end
end

function permission.getCurrentUser()
	return name
end

perm['permission'] = permission
perm['usrs'] = usrs
_putLib('perm', perm)