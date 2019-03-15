#!/usr/bin/lua
--[[ Rule required in modsecurity.conf file: secRuleScript "<path to script>" "deny"
This rule will block a request if anything but nil is returned from the verify_args function.
Exceptions to the rule can be added for certain arguements e.g. a password arguement can have any special character. ]]

function main()
	local getUrls = m.getvars("ARGS_GET", "urlDecode")
	local postUrls = m.getvars("ARGS_POST", "urlDecode")
	local argsNames = m.getvars("ARGS_NAMES", "urlDecode")

	urlArguementsWithExceptions= {
    ["action"] = "%p",
		["_action"] = "%p",
		["config_content"] = "%p",
		["email"]  		= "%@%+",
		["filename"]  = "%:%/",
		["password"] 	= "%p",
		["next"] 		= "%:%/%=%?%&",
		["reg_next"] 	= "%:%/%=%?%&",
		["i"] 			= "%:%/%=%?%&",
		["code"]        = "%p",
		["customer_name"]	= "%p%Yä%Yé%Yö%Yñ",  
		["timezone"] = "%/"          
		}

	if #getUrls > 0 then
		inputUrls = getUrls
	elseif #postUrls > 0 then
		inputUrls = postUrls
	else
		inputUrls = {}
	end

	local inputUrlsCount = #inputUrls
	local sanitizedUrlInputs = sanitize_url_inputs(inputUrls, inputUrlsCount)
	local argsNamesCount = #argsNames
	local sanitizedArgNames = sanitize_url_inputs(argsNames, argsNamesCount)

	local arguementResult = verify_args(sanitizedUrlInputs)
	local arguementNameResult = verify_arg_names(sanitizedArgNames)
	local result = nil

  if arguementResult == nil and arguementNameResult == nil then
		result = nil
	else
		result = "Malicious string detected"
	end

	return result

end

function sanitize_url_inputs (inputUrls, inputUrlsCount)
	local sanitizedUrlInputs = {}

	-- calls the to-string function on the initial list
	for k,v in pairs(inputUrls, inputUrlsCount) do
		currentTable = table.tostring(v)
		sanitizedUrlInputs [inputUrlsCount] = currentTable
		inputUrlsCount = inputUrlsCount - 1
	end

	-- sanitise POST, GET and NAME args
	for i,v in ipairs(sanitizedUrlInputs) do

		if string.find(v, "ARGS_POST:") then
			newValue = string.gsub(v, "ARGS_POST:", "")
			sanitizedUrlInputs [i] = newValue
		elseif string.find(v, "ARGS_GET:") then
			newValue = string.gsub(v, "ARGS_GET:", "")
			sanitizedUrlInputs [i] = newValue
		elseif string.find(v, "ARGS_NAMES:") then
			newValue = string.gsub(v, "ARGS_NAMES:", "")
			sanitizedUrlInputs [i] = newValue
		end
	end

	-- remove name and value strings from dictionaries
	for i,v in ipairs(sanitizedUrlInputs) do
		if string.find(v, "name=") then
			newValue = string.gsub(v, "name=", "")
			sanitizedUrlInputs [i] = newValue
		end
	end
	for i,v in ipairs(sanitizedUrlInputs) do
		if string.find(v, "value=") then
			newValue = string.gsub(v, "value=", "")
			sanitizedUrlInputs [i] = newValue
		end
	end

	-- remove quotes
	for i,v in ipairs(sanitizedUrlInputs) do
		if string.find(v, "\"") then
			newValue = string.gsub(v, "\"", "")
			sanitizedUrlInputs [i] = newValue
		end
	end

	-- decode base64 encoded arguement names
	for i,v in ipairs(sanitizedUrlInputs) do
		local argNameEncoded = false
		local argName, argValue = v:match("([^,]+),([^,]+)")
		-- add nil handling
		if argName then
			while is_base_64_encoded(argName) do
			argNameEncoded = true
			argName = base64_decode_string(argName)
		    end
		end

		-- rebuild sanitized URL with decoded arg name
	    if argNameEncoded then
			local updatedNameInput = argName .. "," .. argValue
			sanitizedUrlInputs[i] = updatedNameInput
		end
	end

	return sanitizedUrlInputs
end

-- verify arguement names added for .gathered exploit
function verify_arg_names(argnames)
	local result
	for i,v in ipairs(argnames) do
		local argname, argValue = v:match("([^,]+),([^,]+)")

		-- deal with nested base64 encoded argnames e.g. devices.owned['c2VydmVycw==']
		if argname then
			if argname:find('%b[]') then
				-- check the value in the quotes
				local index0, index1 = string.find(argname, "%b''")
				local unknownArg = string.sub(argname, index0+1, index1-1)
			  -- if encoded decode
				if (is_base_64_encoded(unknownArg)) then
					unknownArg = base64_decode_string (unknownArg)
					-- rebuild with decoded value
					argname = string.gsub(argname, "%b[]", "."..unknownArg)
				end
			end
			if has_illegal_characters(argname) then
				result = "URL argname contains illegal characters"
			end
		end
	end
	return result
end

-- decodes arguements and checks for illegal strings
function verify_args(args)
	local result
	local count = 0
	for i,v in ipairs(args) do
		local arg, argValue = v:match("([^,]+),([^,]+)")

		if argValue then
		    count = count + 1
			while is_base_64_encoded(argValue) do
				argValue = base64_decode_string(argValue)
			end
		end

		if arg then
			if setContains(urlArguementsWithExceptions, arg) then
				exception = urlArguementsWithExceptions[arg]
				m.log(1, "verify_args-Found an exception for: " .. arg .. " where the value is: " .. argValue) 
			else
				m.log(1, "verify_args-Found no exception found for: " .. arg .. " where the value is: " .. argValue)
				exception = nil
			end
		end

		if argValue then
			if has_illegal_characters(argValue, exception) then
				-- deal with nested encoded lists
				if argValue:find('%,+') then
					m.log(1, "verify_args-Unencoded arguement value is a list: " .. argValue) 
					local convertedTable = {}
					convertedTable = convert_string_to_table(argValue)
					result = verify_list(convertedTable)
				else
					-- Returning a string should ultimately cause Modsecurity to deny the current request
					result = "URL arguement contains illegal characters"
				end
			end
		end
	end
	return result
end

-- if an arguement has been decoded it could be a list or dictionary so it will need further processing
function verify_list(listToVerify)
	for i,v in ipairs(listToVerify) do
		local listValue = v

		if listValue then
			while is_base_64_encoded(listValue) do
				listValue = base64_decode_string(listValue)
			end
		end

		if listValue then
			if setContains(urlArguementsWithExceptions, listValue) then
				listException = urlArguementsWithExceptions[listValue]
				m.log(1, "verify_list-Found an exception for: " .. listValue) 
			else
				m.log(1, "verify_list- has no exception for: " .. listValue)
				listException = nil
			end
		end

		if listValue then
			if has_illegal_characters(listValue, listException) then
				return "URL arguement contains illegal characters"
			end
		end
	end
	return nil
end

-- utility method for checking if a table contains a specified value
function setContains(set, key)
	return set[key] ~= nil
end

-- utility method to check for illegal characters in a given string.
function has_illegal_characters (argValueToCheck, exception)
	-- build regex with exception if provided
	if exception ~= nil then
		regex = "[%w%_%-%.%s" .. exception .. "]"
	else
		regex = "[%w%_%-%.%s]"
	end

	local totalChars = #argValueToCheck
	local matchedChars = 0

    for c in argValueToCheck:gmatch(regex) do
	    matchedChars = matchedChars + 1
	end

	if totalChars ~= matchedChars then
		m.log(1, "has_illegal_characters-Arg value: " .. argValueToCheck .. " has failed with regex: " .. regex)
		return true
	end

	return false
end

-- utility methods used to convert input strings into tables
function convert_string_to_table(stringToConvert)
	local stringToConvert = stringToConvert:gsub('[%"%:%{%}%[%]]', '')
	local stringToConvert = stringToConvert:gsub('[%,]', ' ')
	local tempTable = {}
	tempTable = split(stringToConvert, ' ')
	return tempTable
end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- utility methods used to convert table data structures to strings for easier validation
function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
	  table.insert( result, table.val_to_str( v ) )
	  done[ k ] = true
	end
	for k, v in pairs( tbl ) do
	  if not done[ k ] then
		table.insert( result,
		  table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
	  end
	end
	return table.concat( result, "," )
end

function table.val_to_str ( v )
	if "string" == type( v ) then
	  v = string.gsub( v, "\n", "\\n" )
	  if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
		return "'" .. v .. "'"
	  end
	  return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
	else
	  return "table" == type( v ) and table.tostring( v ) or
		tostring( v )
	end
end

function table.key_to_str ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
	  return k
	else
	  return "[" .. table.val_to_str( k ) .. "]"
	end
end

-- utility methods to verify if a string is base64 encoded
function is_base_64_encoded (stringToCheck)
	if #stringToCheck >= 4 and #stringToCheck % 4 == 0 and not hasInvalidBase64Characters(stringToCheck) and not cannotDecode(stringToCheck) then
	return true
end
	return false
end

function hasInvalidBase64Characters (stringToCheck)

	local totalChars = #stringToCheck
	local matchedBase64Chars = 0

	for c in stringToCheck:gmatch("[%w%/%+%=]") do
		matchedBase64Chars = matchedBase64Chars + 1
	end

	if matchedBase64Chars ~= totalChars then
		return true
	end

	return false
end

function cannotDecode (stringToCheck)
	local decodedStringAttempt = base64_decode_string(stringToCheck)
	local decodedStringAttemptLength = #decodedStringAttempt
	local legalCharacters = 0
	local nonAlphaChars = 0

	for c in decodedStringAttempt:gmatch("[%w%p%s]") do
		legalCharacters = legalCharacters + 1
	end

	for c in decodedStringAttempt:gmatch("[%p]") do
		nonAlphaChars = nonAlphaChars + 1
	end

	if nonAlphaChars == decodedStringAttemptLength then
		return true
	elseif legalCharacters == decodedStringAttemptLength then
		return false
	else
		return true
	end
end

-- utility method to base64 decode a given string
local b ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function base64_decode_string (data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end
