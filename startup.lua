--[[
  cLinux001: cLinux 0.0.1 (complete rewrite)
  NAME:        /startup
  CATEGORY:    bootloader
  VERSION:     0.0.1 (didn't decide a version-system yet.)
  DESCRIPTION: Bootloader, may be called a 'GRUB' clone.

  Made by Piorjade & thecrimulo
]]--


--Functions

local function clear(bg, fg) --This function is practically in every of my programs, lol ~Piorjade
	term.setCursorPos(1,1)
	term.setTextColor(fg)				--Clears the screen with the given Text- and BackgroundColor and sets the cursor to 1,1 (it depends where this function is defined, right now it clears the original term)
	term.setBackgroundColor(bg)
end

local function getBootfiles() --Lists every file (which does not begin with ".") in /boot/ and returns that table
	local t = {}
	local raw = fs.list("/boot/")
	for _, file in ipairs(raw) do
		local i, j = string.find(file, "[.]")
		if i == 1 and i == j then
			
		else
			table.insert(t, file)
		end
	end
	return t
end

local function drawMenu()
	clear(colors.black, colors.white)
	local function drawMessage()
		local str = "Please select an OS"
		term.setCursorPos(26-#str/2, 3)			--Function, just to have the ability to redraw the actual term
		term.write(str)
	end
	drawMessage()
	local oldTerm = term.current()
	local w, h = 26, 10
	local list = window.create(oldTerm, 26-w/2, 10-h/2, w, h)
	term.redirect(list)
	local bFiles = getBootfiles()							--Gets the list of the files in /boot/ and sets the values, which are important for scrolling
	local max = #bFiles 	
	local missing = 0  --The maximum number, which the cursor can scroll up
	local left = max-10  --The maximum number (all the files - 10 (the heigth of the window) ), which the cursor can scroll down
	if left < 0 then left = 0 end --If there aren't more files than the heigth of the screen
	term.setCursorPos(1,1)
	term.setBackgroundColor(colors.gray)
	term.setTextColor(colors.white)
	term.clear()
	local c = 1
	for _, file in ipairs(bFiles) do
		term.setCursorPos(1, c)
		term.write(file)
		c=c+1
	end
	c = 1
	term.redirect(oldTerm)
	local cX, cY = 26-w/2-1, 10-h/2-1
	term.setCursorPos(cX, cY+1)
	term.write(">")
	local loop = true
	while loop do  --Start moving cursor loop
		local _, k = os.pullEventRaw("key")
		if k == keys.down and c < max then --Self explaining
			if c < h then
				term.clear()
				c=c+1
				term.setCursorPos(cX, cY+c)
				term.write(">")
				list.redraw()
				drawMessage()
			elseif c >= h then
				list.scroll(1)
				list.setCursorPos(1, h)
				missing = missing+1
				left = left-1
				list.write(bFiles[missing+10+1])
				term.clear()
				c=c+1
				term.setCursorPos(cX, cY+c)
				term.write(">")
				list.redraw()
				drawMessage()
			end

		elseif k == keys.up and c > missing+1 then --Self explaining
			if c > 1 then
				term.clear()
				c=c-1
				term.setCursorPos(cX, cY+c)
				term.write(">")
				list.redraw()
				drawMessage()
			elseif c == 1 then
				list.scroll(-1)
				list.setCursorPos(1, 1)
				missing = missing-1
				left = left+1
				list.write(bFiles[missing])
				term.clear()
				c=c-1
				term.setCursorPos(cX, cY+c)
				term.write(">")
				list.redraw()
				drawMessage()
			end
		end

	end
end


--Code

drawMenu()