--Load cfs mgr
dofile("customfs_manager.lua")

fs_mgr:setDriver("cmx", "/cLinuxTestHD")

local function copyAll(parent)
	if string.sub(parent, #parent) == "/" then parent = string.sub(parent, 1, #parent-1) end
	local list = fs.list(parent)
	for each, thing in ipairs(list) do
		if not fs.isDir(parent.."/"..thing) then
			local file, err = fs.open(parent.."/"..thing, "r")
			if not file then
				return false, print("FATAL ERROR: "..tostring(err))
			end
			--Remove '/cLinux'
			local virtfile, verr = fs_mgr.open(string.sub(parent, 8).."/"..thing, "w")
			if not virtfile then
				return false, print("(V)FATAL ERROR: "..tostring(err))
			end
			fs_mgr.write(virtfile, file.readAll())
			fs_mgr.close(virtfile)
			file.close()
			print("WROTE: "..parent.."/"..thing)
		else
			print(parent.."/"..thing.." is a directory, making "..string.sub(parent,8).."/"..thing)
			fs_mgr.makeDir(string.sub(parent,8).."/"..thing)
			copyAll(parent.."/"..thing)
		end
	end
	return true, print("WROTE EVERYTHING FROM "..parent)
end

if not copyAll("/cLinux") then
	return
end
print("Seems like everything went fine...")

local newEnv = {}
for each, thing in pairs(_G) do
	newEnv[each] = thing
end


newEnv.io = nil
newEnv.fs = fs_mgr
metaEnv = setmetatable({}, {
	__index = newEnv,
	__metatable = false
})
metaEnv["_G"] = metaEnv

local function newloadfile(name)
	
	if not fs_mgr.exists(name) then
		return false, "file not found"
	end
	local file, err = fs_mgr.open(name, "r")
	if not file then return false, err end
	--Read everything
	local final_data = ""
	repeat
		local data = fs_mgr.read(file, 10000)
		if type(data) == "string" and #data > 0 then
			final_data = final_data..data
		end
	until data == "" or data == nil
	fs_mgr.close(file)
	
	local f = loadstring(final_data, "=("..name..")")
	setfenv(f, metaEnv)
	return f
end

local function newdofile(name)
	return newloadfile(name)()
end

newEnv.loadfile = newloadfile
newEnv.dofile = newdofile

local bootFunc, err = newloadfile("/boot/clinux.lua")
if not bootFunc then
	return print("FATAL BOOT ERROR: "..tostring(err))
else
	print("Loaded "..type(bootFunc))
end

setfenv(bootFunc, metaEnv)
local ok, err = pcall(bootFunc)
if not ok then
	fs_mgr.driver:saveToFile("cLinuxTestHD")
	return print("FATAL RUNTIME ERROR: "..tostring(err))
else
	fs_mgr.driver:saveToFile("cLinuxTestHD")
	return print("Boot finished.")
end
