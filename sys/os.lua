--[[
	CLinux
	A Linux-tryhard OS
	
	You will probably like the original more.
	
	This OS will defenitely not be as polished, 
	as DoorOS. Thats why I recommend DoorOS more than that.
	
	This OS will stay in "Command-Line"-mode, that means
	you guys can make your own, installable Desktop-Enviroment!
	
	(Yes I will probably consider adding my DoorOS-Desktop, when the command-line
	is polished enough...)
]]
--APIs (WILL PROBABLY BE IMPORTANT FOR DESKTOP ENVIROMENTS TOO)
os.loadAPI("/sys/API/sha")
_G.sha = sha
X = nil --ENTER THE PATH TO YOUR DESKTOP ENVIROMENT, IF IT'S NOT NIL IT WILL TRY TO LOAD IT

--Variablen
_ver = 0.1
os.version = function()
	return "CLinux Version "..tostring(_ver)
end

_verstr = os.version()
usrData = {
	usrName = {},
	password = {},
}
tmpUsr = ""
tmpPw = ""
currentDir = "/usr/"
currentUsr = ""
cUsrNmbr = 1

--Backup

local oldOpen = fs.open
local oldmkdir = fs.makeDir
local oldMove = fs.move
local oldCopy = fs.copy
local oldDelete = fs.delete
--Funktionen

function clear(bg, fg) --did you know that you can see this function in any of my codes? xD
	term.setCursorPos(1,1)
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
	term.clear()
end

_G.clear = clear

function limitRead(nmbr, a)
	term.setCursorBlink(true)
	str = ""
	local reading = true
	while reading do
		local _, key = os.pullEventRaw()
		if _ == "char" then
			if #str < nmbr and a == nil then
				term.write(key)
				str = str..key
			else
				term.write(a)
				str = str..key
			end
		elseif _ == "key" and key == keys.backspace then
			if #str > 0 then
				str = string.reverse(str)
				str = string.sub(str, 2)
				str = string.reverse(str)
				local x, y = term.getCursorPos()
				term.setCursorPos(x-1, y)
				term.write(" ")
				term.setCursorPos(x-1, y)
			end
		elseif _ == "key" and key == keys.enter then
			term.setCursorBlink(false)
			return str
			
				
		end
	end
end

_G.limitRead = limitRead

function limitReadPw(nmbr)
	term.setCursorBlink(true)
	str = ""
	local reading = true
	while reading do
		local _, key = os.pullEventRaw()
		if _ == "char" then
			if #str < nmbr then
				str = str..key
			end
		elseif _ == "key" and key == keys.backspace then
			if #str > 0 then
				str = string.reverse(str)
				str = string.sub(str, 2)
				str = string.reverse(str)
			end
		elseif _ == "key" and key == keys.enter then
			term.setCursorBlink(false)
			return str
			
				
		end
	end
end

_G.limitReadPw = limitReadPw

local function register(step)
	clear(colors.black, colors.white)
	if step == 1 then
		term.write("Username: ")
		tmpUsr = limitRead(16)
		print("")
		if #tmpUsr < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter an username.")
			term.setTextColor(col)
			register(1)
		elseif tmpUsr == "root" then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please use another name.")
			term.setTextColor(col)
			register(1)
		else
			register(2)
		end
		
	elseif step == 2 then
		term.write("Password: ")
		tmpPw = limitReadPw(99)
		if #tmpPw < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter a password.")
			term.setTextColor(col)
			register(2)
		else
			register(3)
		end
		
	elseif step == 3 then
		term.write("Repeat Password: ")
		local pw = limitReadPw(99)
		print("")
		if #pw < 1 or pw ~= tmpPw then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Passwords do not match.")
			term.setTextColor(col)
			register(2)
		else
			register(4)
		end
		
		
	elseif step == 4 then
		print("Account "..tmpUsr.." successfully created.")
		table.insert(usrData.usrName, tmpUsr)
		tmpPw = sha.pbkdf2(tmpPw, tmpUsr, 10):toHex()
		table.insert(usrData.password, tostring(tmpPw))
		local file = fs.open("/sys/usrData","w")
		local a = textutils.serialize(usrData)
		file.write(a)
		file.close()
		fs.makeDir("/usr/"..tmpUsr.."/home/")
		fs.makeDir("/usr/root/home/")
		print("Done.")
	end
end

local function login(step)
	if step == 1 then
		
		nTerm = term.native()
		term.write("Username: ")
		local e = limitRead(16)
		print("")
		if #e < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter an username.")
			term.setTextColor(col)
			login(1)
		else
			for _, name in ipairs(usrData.usrName) do
				if name == e then
					currentUsr = e
					cUsrNmbr = _
					login(2)
				elseif e == "root" then
					currentUsr = e
					cUsrNmbr = 0
					login(2)
				elseif _ == #usrData.usrName then
					local col = term.getTextColor()
					term.setTextColor(colors.red)
					print("User not found.")
					term.setTextColor(col)
					login(1)
				end
			end
		end
	elseif step == 2 then
		term.write("Password: ")
		local p = limitReadPw(99)
		print("")
		if #p < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter a password.")
			term.setTextColor(col)
			login(2)
		else
			p = sha.pbkdf2(p, currentUsr, 10):toHex()
			p = tostring(p)
			local file = fs.open("/sys/.rootpw","r")
			local rpw = file.readLine()
			file.close()
			if currentUsr ~= "root" and p ~= usrData.password[cUsrNmbr] then
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print("Oops, that didn't work! Let's try it again.")
				term.setTextColor(col)
				login(1)
			elseif currentUsr == "root" and p ~= rpw then
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print("Oops, that didn't work! Let's try it again.")
				term.setTextColor(col)
				login(1)
			else
				--stuff
				currentDir = "/usr/"..currentUsr.."/home/"
				_G.vDir = "/usr/"..currentUsr.."/home/"
				_G.currentUsr = currentUsr
				_G.currentDir = currentDir
				_G.currentPw = p
				print("Success.")
				--limitFunctions()
				linuxShell()
			end
		end
	end
end



function limitFunctions()
	
	fs.open = function(path, mode)
		if mode ~= "a" or mode ~= "w" or mode ~= "r" or mode ~= "br" or mode ~= "bw" then
			return nil
		end
		local a, b = string.find(path, "/usr/".._G.currentUsr.."/home/")
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if mode == "a" and _G.currentUsr ~= "root" and inhome == false or mode == "w" and _G.currentUsr ~= "root" and inhome == false or mode == "bw" and _G.currentUsr ~= "root" and inhome == false then
			return false
		elseif mode == "a" and _G.currentUsr == "root" or mode == "w" and _G.currentUsr == "root" or mode == "bw" and _G.currentUsr == "root" then
			local c = oldOpen("/sys/.rootpw","r")
			local rpw = c.readLine()
			c.close()
			if _G.currentPw == rpw then
				return oldOpen(path, mode)
			else
				return false
			end
		elseif mode == "a" and inhome or mode == "w" and inhome or mode == "bw" and inhome then
			return oldOpen(path, mode)
		elseif mode == "r" or mode == "br" then
			return oldOpen(path, mode)
		end
	end
	fs.makeDir = function(path)
		local a, b = string.find(path, "/usr/".._G.currentUsr.."/home/")
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if _G.currentUsr ~= "root" and inhome == false then
			return false
		elseif _G.currentUsr == "root" then
			local c = oldOpen("/sys/.rootpw","r")
			local rpw = c.readLine()
			c.close()
			if _G.currentPw == rpw and fs.exists(path) == false then
				return oldmkdir(path)
			elseif _G.currentPw ~= rpw then
				return false
			elseif fs.exists(path) then
				return "Folder/Files already exists."
			end
		elseif inhome then
			if fs.exists(path) == false then
				return oldmkdir(path)
			else
				return "Folder/File already exists."
			end
		end
	end
	fs.move = function(oldPath, newPath)
		local a, b = string.find(oldPath, "/usr/".._G.currentUsr.."/home/")
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		local a, b = string.find(newPath, "/usr/".._G.currentUsr.."/home/")
		local tohome = false
		if a == nil then
			tohome = false
		else
			tohome = true
		end
		if _G.currentUsr ~= "root" and inhome == false or _G.currentUsr ~= "root" and tohome == false then
			return false
		elseif _G.currentUsr == "root" then
			local c = oldOpen("/sys/.rootpw","r")
			local rpw = c.readLine()
			c.close()
			if _G.currentPw == rpw and fs.exists(oldPath) then
				return oldMove(oldPath, newPath)
			elseif fs.exists(oldPath) == false then
				return "Folder/File does not exist."
			else
				return false
			end
		elseif inhome and tohome then
			if fs.exists(inhome) and fs.exists(tohome) == false then
				return oldMove(path)
			elseif fs.exists(inhome) == false then
				return "Folder/File does not exist."
			elseif fs.exists(tohome) then
				return "Folder/File already exists."
			end
		end
	end
	fs.copy = function(oldPath, newPath)
		local a, b = string.find(newPath, "/usr/".._G.currentUsr.."/home/")
		local tohome = false
		if a == nil then
			tohome = false
		else
			tohome = true
		end
		if _G.currentUsr ~= "root" and tohome == false then
			return false
		elseif _G.currentUsr == "root" then
			local c = oldOpen("/sys/.rootpw","r")
			local rpw = c.readLine()
			c.close()
			if _G.currentPw == rpw and fs.exists(oldPath) and fs.exists(newPath) == false then
				return oldOpen(oldPath, newPath)
			elseif fs.exists(oldPath) == false then
				return "Folder/File does not exist."
			elseif fs.exists(newPath) then
				return "Folder/File already exists."
			else
				return false
			end
		elseif tohome then
			if fs.exists(oldPath) and fs.exists(newPath) == false then
				return oldCopy(oldPath, newPath)
			elseif fs.exists(oldPath) == false then
				return "Folder/File does not exist."
			elseif fs.exists(newPath) then
				return "Folder/File already exists."
			end
		end
	end
	fs.delete = function(path)
		local a, b = string.find(path, "/usr/".._G.currentUsr.."/home/")
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if _G.currentUsr ~= "root" and inhome == false then
			return false
		elseif _G.currentUsr == "root" then
			local c = oldOpen("/sys/.rootpw","r")
			local rpw = c.readLine()
			c.close()
			if _G.currentPw == rpw and fs.exists(path) then
				return oldDelete(path)
			elseif fs.exists(path) == false then
				return "Folder/File does not exist."
			else
				return false
			end
		elseif inhome then
			if fs.exists(path) then
				return oldDelete(path)
			elseif fs.exists(path) == false then
				return "Folder/File does not exist."
			end
		end
	end
end

local function restoreFunctions()
	fs.open = oldOpen
	fs.makeDir = oldmkdir
	fs.delete = oldDelete
	fs.move = oldMove
	fs.copy = oldCopy
end

function linuxShell()
	clear(colors.black, colors.white)
	local loop = true
	local d = "/"

	while loop do
		currentDir = _G.currentDir
		local x, y = term.getCursorPos()
		term.setCursorPos(1,y)
		term.setTextColor(colors.yellow)
		local a, b = string.find(currentDir, "/usr/"..currentUsr.."/home/")
		if a then
			d = string.gsub(currentDir, "/usr/"..currentUsr.."/home/", "~/", 1)
		else
			d = currentDir
		end
		
		term.write(currentUsr.."@ ")
		term.setTextColor(colors.blue)
		term.write(d.."> ")
		term.setTextColor(colors.white)
		term.setCursorBlink(true)
		local command = read()
		local args = {}
		local arg = ""
		--[[local function insert(str)
			table.insert(cTbl, str)
		end]]
		--string.gsub(command, "(%w+)", insert)
		local i, j = string.find(command, " ")
		if i == nil then
			command = command
		else
			arg = string.sub(command, j+1, #command)
			command = string.sub(command, 1, i-1)
			
		end
		
		if arg == nil or arg == "" then
			arg = ""
		else
			repeat
				local i, j = string.find(arg, " ")
				if i ~= nil then
					local a = string.sub(arg, 1, i-1)
					local i, j = string.find(a, "~/")
					if i == 1 and j == 2 then
						local c = string.sub(a, 3, #a)
						a = "/usr/".._G.currentUsr.."/home/"..c
					end
					table.insert(args, a)
					arg = string.sub(arg, j+1, #arg)
				else
					local i, j = string.find(arg, "~/")
					if i == 1 and j == 2 then
						local c = string.sub(arg, 3, #arg)
						arg = "/usr/".._G.currentUsr.."/home/"..c
					end
					table.insert(args, arg)
				end
			until i == nil
		end
		if fs.exists("/usr/bin/"..command) then
			--stuff
			local a = loadfile("/usr/bin/"..command)
			limitFunctions()
			--a(unpack(args))
			local ok, err = pcall(a, unpack(args))
			if ok == false then
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print(err)
				term.setTextColor(col)
			end
			restoreFunctions()
			--os.run({}, "/usr/bin/"..command, unpack(args))

		elseif fs.exists("/usr/bin/"..command) == false then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Command not found.")
			term.setTextColor(col)
		end
		
	end
end

_G.linuxShell = linuxShell

local function checkUsr()
	print("Welcome to ".._verstr.."!")
	sleep(1)
	local file = fs.open("/sys/usrData","r")
	usrData = file.readAll()
	usrData = textutils.unserialize(usrData)
	file.close()
	
	if #usrData.usrName < 1 then
		term.setTextColor(colors.red)
		print("No user(s) found.")
		print("Starting registration.")
		term.setTextColor(colors.white)
		sleep(2)
		register(1)
	else
		--[[
		
		EXAMPLE LOGIN SYSTEM:
		
		print(usrData.usrName[1])
		local a = limitReadPw(16)
		a = sha.pbkdf2(a, usrData.usrName[1], 10):toHex()
		a = tostring(a)
		if a == usrData.password[1] then
			print("true")
		else
			print("False")
		end]]
		clear(colors.black, colors.white)
		login(1)
	end
end

--Code

clear(colors.black, colors.white)
checkUsr()