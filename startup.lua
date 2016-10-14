--[[
  cLinux001: cLinux 0.0.1 (complete rewrite)
  NAME:        /startup
  CATEGORY:    bootloader
  VERSION:     0.0.1 (didn't decide a version-system yet.)
  DESCRIPTION: Bootloader, may be called a 'GRUB' clone.

  Made by Piorjade & thecrimulo
]]--

--variables
local bootList = {} --The list with bootable images (.i) is going to be stored here
local selected = 1 --The pre-selected image
local defaultcmd = {} --The default command, which the command is booted with

--functions

local function getList()
	local file = fs.open("/grubcfg", "r")
	local inhalt = file.readAll()
	file.close()
	inhalt = textutils.unserialize(inhalt)
	bootList = inhalt.list
	selected = inhalt.default
	defaultcmd = inhalt.command
	blacklist = inhalt.blacklist
    for _, a in ipairs(bootList) do
        local i,j = string.find(a, "../")
        if i then
            table.remove(bootList, _)
        end
    end
end

local function readNoJump()	--Reads the user input, but doesn't jump to the next line when finishing
	local str = ""
	local reading = true
	term.setCursorBlink(true)
	sleep(0.2)
	while reading do
		local _, k = os.pullEventRaw()
		local x, y = term.getCursorPos()
		if _ == "key" and k == keys.enter then
			term.setCursorBlink(false)
			reading = false
			return str
		elseif _ == "key" and k == keys.backspace and x > 1 then
			str = string.reverse(str)
			str = string.sub(str, 2)
			str = string.reverse(str)
			local x, y = term.getCursorPos()
			term.setCursorPos(x-1, y)
			term.write(" ")
			term.setCursorPos(x-1, y)
		elseif _ == "char" then
			str = str..tostring(k)
			term.write(tostring(k))
		end
	end
end

local function drawMenu()
	local function clear()
		term.setCursorPos(1,1)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
	end
	clear()

	
	oldTerm = term.current()
	local w, h = 15, 11
	local wlist = window.create(term.current(), 26-w/2, 10-h/2, w, h)
	local str = "-GRUB-"
	local str2 = "Please select an image."
	local str3 = "Press E to write additional commands."
	local cmd = window.create(term.current(), 26-#str3/2, 19, #str3, 1)
	cmd.setBackgroundColor(colors.gray)
	cmd.clear()
	term.setCursorPos(26-#str/2, 1)
	term.write(str)
	term.setCursorPos(26-#str2/2, 2)
	term.write(str2)
	term.setCursorPos(26-#str3/2, 18)
	term.write(str3)
	local function redrawList()
		wlist.setBackgroundColor(colors.gray)
		wlist.clear()
		wlist.setCursorPos(1,1)
		wlist.setTextColor(colors.white)
		term.redirect(wlist)
		for _, o in ipairs(bootList) do
			local x, y = term.getCursorPos()
			if _ == selected then
				term.setBackgroundColor(colors.lightBlue)
				term.clearLine()
				term.write(o)
				if _ < #bootList then
					term.setCursorPos(1, y+1)
				end
				term.setBackgroundColor(colors.gray)
			else
				term.write(o)
				if _ < #bootList then
					term.setCursorPos(1, y+1)
				end
			end
		end
		term.redirect(oldTerm)
	end

	local function redrawCommand()
		term.redirect(cmd)
		term.setCursorPos(1,1)
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lime)
		term.clear()
		if defaultcmd[selected] ~= nil then
			term.write(defaultcmd[selected])
		else
			term.write("NONE")
		end
		term.redirect(oldTerm)
	end

	redrawList()
	redrawCommand()
	local running = true
	term.redirect(wlist)
	while running do
		local _, k = os.pullEventRaw("key")
		if k == keys.up and selected > 1 then
			selected = selected-1
			redrawList()
			redrawCommand()
		elseif k == keys.down and selected < #bootList then
			selected = selected+1
			redrawList()
			redrawCommand()
		elseif k == keys.e then
			term.redirect(cmd)
			term.setCursorPos(1,1)
			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.lime)
			term.clear()
			local e = readNoJump()
			term.redirect(oldTerm)
			defaultcmd[selected] = e
		elseif k == keys.enter then
			if fs.exists("/boot/"..bootList[selected]) == false then
				clear()
				printError("/boot/"..bootList[selected].." does not exist.")
				running = false
				break
			else
				running = false
				clear()
				local tArgs = {}
				if defaultcmd[selected] ~= nil then
					repeat
						local i, j = string.find(defaultcmd[selected], " ")
						if i then
							local a = string.sub(defaultcmd[selected], 1, i-1)
							table.insert(tArgs, a)
							defaultcmd[selected] = string.sub(defaultcmd[selected], j+1, #defaultcmd[selected])
						end
					until i == nil
					table.insert(tArgs, defaultcmd[selected])
				end
				
				term.redirect(oldTerm)
				term.setCursorPos(1,1)
				term.clear()
				os.run({}, "/boot/"..bootList[selected], unpack(tArgs))
			end
		end
	end
	term.redirect(oldTerm)
end


if fs.exists("/grubcfg") then
	getList()
	
	if #bootList <= 11 then
		drawMenu()
	elseif #bootList > 11 then
		printError("/grubcfg: Too many entries.")
	elseif #bootList < 1 then
		printError("/grubcfg: No entries.")
	end
else
	printError("/grubcfg: Not found.")
end