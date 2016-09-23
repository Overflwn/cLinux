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

local _fs = {}

function _fs.scanFs(p)
	local root = {}
	local rt = old.fs.list(p)
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
end