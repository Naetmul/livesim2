-- Async, callback-based download (thread part)
-- Part of AquaShine loader
-- See copyright notice in AquaShine.lua

require("love.thread")

local cin = ...
local socket = require("socket")
local http = require("socket.http")
local lt = require("love.timer")
http.TIMEOUT = 60

--function print() lt.sleep(0.001) end

-- AquaShine download event
local le = require("love.event")

local function push_event(name, data)
	le.push("aqs_download", cin, name, data)
end

-- We create our custom sink function which does send
-- the response data to LOVE channel
local function custom_sink(chunk, err)
	print("custom_sink", chunk, err)
	if cin:peek() ~= "QUIT" then
		print("QUIT req")
		return nil, "QUIT Requested"
	elseif chunk then
		push_event("RECV", chunk)
	end
	
	return 1
end

-- HTTP request function
local lasturl
local lasthttp

local function get_http(url, force)
	local h
	local dest, uri = assert(url:match("http://([^/]+)(/?.*)"))
	local host, port = dest:match("([^:]+):?(%d*)")
	port = #port > 0 and port or "80"
	h = http.open(host, assert(tonumber(port)))
	
	return h, #uri == 0 and "/" or uri, dest
end

local function send_http(h, str)
	return h.c:send(str)
end

local request_http = socket.protect(function(url, headers)
	-- Build request table
	local h, uri, dest = get_http(url)
	print("http hand", h, uri)
	
	-- Adjust
	local basic_header = {
		["host"] = dest,
		["connection"] = "close",
		["user-agent"] = "AquaShine.Download "..socket._VERSION
	}
	print("header base", basic_header, headers)
	
	-- Override headers
	for n, v in pairs(headers) do
		print("add header", n, v)
		if v == math.huge then
			basic_header[n:lower()] = nil
		else
			basic_header[n:lower()] = tostring(v)
		end
	end
	print("header modified", basic_header)
	
	-- Send
	do
		local reqline = string.format("GET %s HTTP/1.1\r\n", uri)
		
		print("pre-send req")
		send_http(h, reqline)
		print("1st send req")
	end
	print("pre-send header")
	do
		local headerstr = {}
		for n, v in pairs(basic_header) do
			headerstr[#headerstr + 1] = string.format("%s: %s\r\n", n, v)
		end
		headerstr[#headerstr + 1] = "\r\n"
		send_http(h, table.concat(headerstr))
	end
	print("post-send header")
	
	local code, status = h:receivestatusline()
	print("post-reveice req")
	-- if it is an HTTP/0.9 server, simply get the body and we are done
	if not code then
		push_event("RESP", 200)
		push_event("SIZE", -1)
		h:receive09body(status, custom_sink)
		push_event("DONE", 0)
		h:close()
		return
	end
	
	local headers
	-- ignore any 100-continue messages
	while code == 100 do 
		headers = h:receiveheaders()
		code, status = h:receivestatusline()
	end
	headers = h:receiveheaders()
	
	push_event("RESP", code)
	print("resp", code)
	push_event("SIZE", headers['content-length'] and tonumber(headers['content-length']) or -1)
	push_event("HEDR", headers)
	
	h:receivebody(headers, custom_sink)
	h:close()
	push_event("DONE", 0)
end)

local command = cin:demand()
while command ~= "QUIT" do
	print("command", command)
	local headers = cin:pop()
	local a, b, c = pcall(request_http, command, headers)
	
	if c then
		push_event("ERR ", c)
	end
	
	command = cin:demand()
end
