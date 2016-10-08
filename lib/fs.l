--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /lib/fs.l
	CATEGORY:    Library
	SET:         Core Library
	VERSION:     01:alpha0
	DESCRIPTION: 
		Manages files & folders.
		Most of these functions are selfexplaining.
]]--
local old = {}
old['fs'] = fs
local _fs = {}
local forbidden = {"/boot", "/vit", "/bin"}


function _fs.scanFs(p)
	local root = {}
	local rt = old.fs.list(p or "/")
	for _, a in ipairs(rt) do
		if old.fs.isDir(p..a) then
			root[p..a] = true
			root[p..a]['$dir'] = true
			local tree = _fs.scanFs(p..a)
			table.insert(root[p..a], tree)
		else
			root[p..a] = true
			root[p..a]['$dir'] = false
			root[p..a]['owner'] = "user"
			for _, folder in ipairs(forbidden) do
				local i, j = string.find(p, folder)
				if i == 1 and j == i then
					root[p..a]['owner'] = "root"
				end
			end
		end
	end
	return root
end

function _fs.getPrefix(a)
	str = string.reverse(a)
	i, j = string.find(str, "/")
	if i == 1 and j == 1 then
		local prefix = string.sub(str, 2)
		prefix = string.reverse(prefix)
		prefix, suffix = getPrefix(prefix)
		return prefix, suffix
	elseif i > 1 then
		local strS = string.sub(str, 1, i-1)
		local strP = string.sub(str, i, #str)
		return strP, strS
	end
end

function _fs.makeDir(p)
	local i, j = string.find(p, "/")
	if i == 1 and j == i then
		p = p
	else
		p = getCurPath()
	end
	
	local wx = perm.permission.check(p)
	if wx == "w" then
		old.fs.makeDir(p)
	elseif wx == "x" then
		return "noPermission"
	else
		return
	end
end

function _fs.open(p, mode)
	if mode == "w" or mode == "a" then
		local ok = perm.permission.check(p)
		if ok ~= "w" then
			return nil
		elseif ok == "w" then
			return old.fs.open(p, mode)
		end
	elseif mode == "r" then
		return old.fs.open(p, mode)
	end
end

_fs.list = old.fs.list
_fs.exists = old.fs.exists
_fs.isDir = old.fs.isDir

function _fs.isReadOnly(p)
	for _, a in ipairs(forbidden) do
		local i, j = string.find(p, a)
		if i == 1 then
			return true
		else
			return false
		end
	end
end

_fs.getName = old.fs.getName
_fs.getDrive = old.fs.getDrive
_fs.getSize = old.fs.getSize
_fs.getFreeSpace = old.fs.getFreeSpace

function _fs.move(from, to)
	local m = perm.permission.check(from)
	
	if m == "w" then
		local m = perm.permission.check(to)
		if m == "w" then
			old.fs.move(from, to)
		else
			return "noPermission"
		end
	else
		return "noPermission"
	end
end

function _fs.copy(from, to)
	local m = perm.permission.check(to)
	if m == "w" then
		old.fs.copy(from, to)
	else
		return "noPermission"
	end
end

function _fs.delete(p)
	local m = perm.permission.check(p)
	if m == "w" then
		old.fs.delete(p)
	else
		return "noPermission"
	end
end

_fs.combine = old.fs.combine
_fs.find = old.fs.find
_fs.getDir = old.fs.getDir
_fs.complete = old.fs.complete

_put('fs', _fs)