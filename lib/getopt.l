-- Copyright (C) 2017, GReaperEx & cLinux Team

-- This library implements getopt of linux's unistd.h

local getopt = {}

getopt.optarg = ""
getopt.optind = 1
getopt.opterr = 1
getopt.optopt = "?"

local posixly_correct = (_G["POSIXLY_CORRECT"] ~= nil)
local nonopt_code1 = false
local erropt = "?"
-- Return type: { name, has_arg }
-- 0 No arg, 1 mandatory, 2 optional
local function parseOptions(optstr)
	local stIndex = 1;
	if string.sub(optstr, 1, 1) == "+" then
		posixly_correct = true
		stIndex = stIndex + 1
	elseif string.sub(optstr, 1, 1) == "-" then
		nonopt_code1 = true
		stIndex = stIndex + 1
	end
	if string.sub(optstr, stIndex, stIndex) == ":" then
		erropt = ":"
		stIndex = stIndex + 1
	end
	
	local opts = {}
	for i=stIndex,#optstr do
		local c = string.sub(optstr, i, i)
		if c == ":" then
			opts[#opts].has_arg = opts[#opts].has_arg + 1
		else
			opts[#opts + 1] = { name=c, has_arg=0 }
		end
	end

	return opts
end

local nonOptions = 0
local function permute(args, index)
	local temp = args[index]
  if #args > 1 then
	  for i=index,#args-1 do
		  args[i] = args[i+1]
	  end
  end
	args[#args] = temp
	nonOptions = nonOptions + 1
end

local _nextc = 1
local oldArgs = nil
-- Equivalent to the standard ''int getopt(int argc, char * const argv[], const char *optstring);''
function getopt.std(args, optstr)
	if oldArgs ~= args then
		-- Reinitialize everything
		getopt.optarg = ""
		getopt.optind = 1
		getopt.opterr = 1
		getopt.optopt = "?"

		posixly_correct = (_G["POSIXLY_CORRECT"] ~= nil)
		nonopt_code1 = false
		erropt = "?"
		nonOptions = 0
		_nextc = 1
		oldArgs = args
	end

	if getopt.optind + nonOptions > #args then
		return -1
	end

	local opts = parseOptions(optstr)
	local c = string.sub(args[getopt.optind], _nextc, _nextc)

	-- This is indeed an infinite loop
	while true do
    c = string.sub(args[getopt.optind], _nextc, _nextc)
    if _nextc == 1 and c ~= "-" or args[getopt.optind] == "-" then
      if posixly_correct or getopt.optind + nonOptions > #args then
				return -1
			end
      if nonopt_code1 then
        getopt.optarg = args[getopt.optind]
        getopt.optind = getopt.optind + 1
        return string.char(1)
      else
			  permute(args, getopt.optind)
      end
		else
      break
    end
	end

  local changedIndex = false
  _nextc = _nextc + 1
	if _nextc > #(args[getopt.optind]) then
		getopt.optind = getopt.optind + 1
		_nextc = 1
		changedIndex = true
	end
	if getopt.optind + nonOptions > #args then
		return -1
	end
	c = string.sub(args[getopt.optind], _nextc, _nextc)

	if _nextc ~= 1 or (_nextc == 1 and c == "-") then
    if posixly_correct and c ~= "-" and _nextc == 1 then
      return -1
    end

		if c == "-" then
      if _nextc == 1 and changedIndex == true then
        -- Jumped to the next argument, rereading first available command
        changedIndex = false
        _nextc = _nextc + 1
        if _nextc > #(args[getopt.optind]) then
	        getopt.optind = getopt.optind + 1
	        _nextc = 1
	        changedIndex = true
        end
        if getopt.optind + nonOptions > #args then
	        return -1
        end
        c = string.sub(args[getopt.optind], _nextc, _nextc)
      else
			  return -1
      end
		else
      changedIndex = false
    end

		local index = -1
		for i, v in ipairs(opts) do
			if v.name == c then
				index = i
				break
			end
		end

		if index == -1 then
      if nonopt_code1 then
        getopt.optarg = string.sub(args[getopt.optind], _nextc)
        getopt.optind = getopt.optind + 1
        return string.char(1)
      else
			  getopt.optopt = c
			  if getopt.opterr ~= 0 then
				  printError("getopt: \""..c.."\" isn't an option.")
			  end
			  return erropt
      end
		end

		if opts[index].has_arg == 1 then
			local substr = string.sub(args[getopt.optind], _nextc+1)
			if substr == "" or substr == nil then
        if args[getopt.optind+1] ~= nil then
          substr = args[getopt.optind+1]
			    getopt.optind = getopt.optind + 1
        else
				  getopt.optopt = c
				  if getopt.opterr ~= 0 then
					  printError("getopt: \""..c.."\" mandatory argument missing.")
				  end
				  return erropt
        end
			end

			getopt.optarg = substr
			getopt.optind = getopt.optind + 1
      _nextc = 1
			return c
		end
		if opts[index].has_arg == 2 then
			local substr = ""
			if args[getopt.optind] ~= nil then
				substr = string.sub(args[getopt.optind], _nextc+1)
			end
			if substr == nil or changedIndex then
				substr = ""
			end

			getopt.optarg = substr
			getopt.optind = getopt.optind + 1
      _nextc = 1
			return c
		end

		getopt.optarg = ""
		return c
  end
	return -1
end

_putLib("getopt", getopt)
