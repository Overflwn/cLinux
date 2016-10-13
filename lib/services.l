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
	if type(bool) ~= "boolean" then return false, "boolean exptected" end
	serv.update()
	if list[k] or fs.exists(k) then
		list[k] = bool
		serv.update()
		return true
	else
		return false, "no such service"
	end
end

function serv.giveList()
	return list
end

_putLib('serv', serv)