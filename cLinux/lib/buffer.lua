--[[
        cLinux Buffer Library
    
    (This is a very simple API to create string buffers;
    These are to be used with redirecting I/O of programs)

    ~Overflwn
]]

local bufferMeta = {
}

local buffer = {}

function bufferMeta:write(self, str)
    if type(str) ~= "string" then str = "" end
    self.data = self.data..str
end

function bufferMeta:read(self, format)
    if format == "*a" then
        --Read the whole buffer
        local buf = self.data
        self.data = ""
        return buf
    elseif format == "*l" or format == nil then
        --Read the next line, skipping newline
        local buf = ""
        if #self.data < 1 then
            buf = nil
            return buf
        end
        local pos = string.find(self.data, "\n")
        if pos then
            buf = string.sub(self.data, 1, pos-1)
            self.data = string.sub(self.data, pos+1)
            return buf
        else
            buf = self.data
            self.data = ""
            return buf
        end
    elseif type(format) == "number" then
        local buf = ""
        if format < 1 and #self.data > 0 then
            return ""
        elseif format < 1 and #self.data < 1 then
            return nil
        else
            local counter = 0
            repeat
                buf = buf..string.sub(self.data, counter+1, counter+1)
                counter = counter+1
            until counter == format or counter == #self.data
            self.data = string.sub(self.data, counter+1)
            return buf
        end
    else
        return false, "invalid format"
    end
end

function buffer.newBuffer()
    return setmetatable({
        data ={} 
    }, bufferMeta)
end