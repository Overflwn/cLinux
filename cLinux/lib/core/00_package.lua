--[[
--		cLinux package library
--	Load libraries via 'require(lib)'
--
--~Piorjade
--]]

_G.package = {}
_G.package.loaded = {}
_G.package.cpath = "/lib;/usr/lib"
local oldfs = fs

function _G.require(name)
	local paths = splitStr(_G.package.cpath, ";")
	for each, path in ipairs(paths) do
		if oldfs.exists(path.."/"..name..".lua") and not oldfs.isDir(path.."/"..name..".lua") then
			local file, err = loadfile(path.."/"..name..".lua")
			if not file then
				return false, err
			end
			local succ, data = pcall(file)
			if not succ then
				return false, data
			end
			_G.package.loaded[name] = data
			return _G.package.loaded[name]
		end
	end
end

function _G.package.unload(name)
	if _G.package.loaded[name] then
		_G.package.loaded[name] = nil
		return true
	end
	return false
end
