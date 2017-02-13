--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /lib/services.l
	CATEGORY:    Library
	SET:         Core Library
	VERSION:     01:alpha0
	DESCRIPTION:
		This script is manages things, that should be started after shell.
		Services can be added and removed as root.
		(Basically this is an autorun manager, for things like starting a window manager)
]]--
local serv = {}
local list = {}

local function initServicesConf()
	list['/sys/commandline'] = true
	for _, a in ipairs(fs.list("/etc/services.d")) do
		list[a] = false
	end
	local file = fs.open("/etc/services.conf", "w")
	file.write(textutils.serialize(list))
	file.close()
end

function serv.update()
	for _, a in ipairs(fs.list("/etc/services.d")) do
		if list[a] == nil then
			list[a] = false
		end
	end
	for _, a in pairs(list) do
		if fs.exists(_) or fs.exists("/etc/services.d/".._) then

		else
			list[_] = nil
		end
	end
	local file = fs.open("/etc/services.conf", "w")
	file.write(textutils.serialize(list))
	file.close()
end

local file = fs.open("/etc/services.conf", "r")
if not file then
	print("error")
	sleep(2)
	initServicesConf()
else
	local inhalt = file.readAll()
	inhalt = textutils.unserialize(inhalt)
	file.close()
	local foundcore = false
	for k, v in pairs(inhalt) do
		if v == "core" then
			foundcore = true
			break
		else
			foundcore = false
		end
	end
	if not foundcore then
		initServicesConf()
	else
		list = inhalt
		serv.update()

	end
end


function serv.set(k, bool)
	if type(bool) ~= "boolean" and bool ~= "core" then return false, "boolean exptected" end
	serv.update()
	if list[k] ~= nil or fs.exists(k) then
		if bool == "core" then
			for _, a in pairs(list) do
				if a == "core" then
					list[_] = false
				end
			end
		end
		list[k] = bool
		serv.update()
		return true
	else
		return false, "no such service"
	end
end

function serv.giveList()
	local l = {}
	for each, val in pairs(list) do
		l[each] = val
	end
	return l
end

_putLib('serv', serv)
