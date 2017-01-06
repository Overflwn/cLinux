

--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /sys/perm.l
	CATEGORY:    Library
	SET:         Core Library
	VERSION:     02:alpha6
	DESCRIPTION:
		This script manages users and their permissions.
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


--Initiate system
if _users == nil then
	_users = {}
	if fs.exists("/sys/usrData") then
		local file = old.fs.open("/sys/usrData", "r")
		local inhalt = file.readAll()
		_users = textutils.unserialize(inhalt)
		file.close()
	else
		local file = old.fs.open("/sys/usrData", "w")
		file.write(textutils.serialize(_users))
		file.close()
	end
end

--Hash a password with the given salt and return the hashed password, open for all programs
function hashPw(p, salt)
	local str = pbkdf2(p, salt, 10):toHex()
	return tostring(str)
end

_put('hashPw', hashPw)

local usrs = {}

--Return the list of every registered user
function usrs.getList()
	local inhalt = {}
	for k, v in pairs(_users) do
		table.insert(inhalt, k)
	end
	return inhalt
end

--set the current user
local function setUsr(n, p)
	name = n
	password = p
end


--self explaining
function usrs.addUser(nm, pw)
	if _users[nm] or nm == "root" or fs.exists("/home/"..nm) then return false, "exists" end
	local i = usrs.getList()
	local oldname = name
	local oldpw = password
	if #i < 1 then
		--first run
		local n = "root"
		local file = fs.open("/sys/.rootpw", "r")
		local p = file.readLine()
		file.close()
		setUsr(n, p)
	end
	pw = hashPw(pw, nm)
	_users[nm] = pw
	local file = old.fs.open("/sys/usrData", "w")
	file.write(textutils.serialize(_users))
	file.close()
	old.fs.makeDir("/home/"..nm)
	setUsr(oldname, oldpw)
	return true
end

function usrs.checkRootPw(p)
	local file = old.fs.open("/sys/.rootpw", "r")
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
	if #name < 1 or #oldPw < 1 or #newPw < 1 then return nil end
	if _users[name] and name ~= "root" then
		local oldPw = hashPw(oldPw, name)
		if oldPw == _users[name] then
			local nPw = hashPw(newPw, name)
			_users[name] = nPw
			local file = old.fs.open("/sys/usrData", "w")
			file.write(textutils.serialize(_users))
			file.close()
			return true
		else
			return false, "Wrong password."
		end
	elseif name == "root" then
		local oldPw = hashPw(oldPw, name)
		local newPw = hashPw(newPw, name)
		if usrs.checkRootPw(oldPw) then
			local file = old.fs.open("/sys/.rootpw", "w")
			file.writeLine(newPw)
			file.close()
		else
			return false, "Wrong password."
		end
	else
		return nil, "User does not exist."
	end
end

function usrs.changeName(oldname, newname, pw)
	if oldname and newname and pw then
		if #oldname < 1 or #newname < 1 or #pw < 1 then return nil end
		if fs.exists("/home/"..newname) or _users[newname] then return "exists" end
		if _users[oldname] and oldname ~= "root" then
			local ps = hashPw(pw, oldname)
			if ps == _users[oldname] then
				_users[newname] = hashPw(pw, newname)
				_users[oldname] = nil
				if fs.exists("/home/"..oldname) then
					fs.move("/home/"..oldname, "/home/"..newname)
				else
					fs.makeDir("/home/"..newname)
				end
				local file = old.fs.open("/sys/usrData", "w")
				file.write(textutils.serialize(_users))
				file.close()
				return true
			else
				return false, "Wrong Password"
			end
		elseif oldname == "root" then
			return false, "Can't change root"
		else
			return nil, "User doesn't exist"
		end
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

function permission.saveOld()
	oldname = name
	oldpassword = password
	return
end

function permission.login(n, p, nohash)
	if n == nil or p == nil then return nil end
	if not nohash then
		p = hashPw(p, n)
	end
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
	return name, password
end

perm['permission'] = permission
perm['usrs'] = usrs
perm['hashPw'] = hashPw
_putLib('perm', perm)