local _, addon = ...

-- Module setup
local M = {}
addon.Config = M
local _G = _G
setfenv(1, M)

--- Load this module
function Load()
	if _G.DEPGPStorage.options == nil then
		_G.DEPGPStorage.options = {}
	end
	if addon.data.tmp_options == nil then
		addon.data.tmp_options = {}
	end
end

--- Get option
-- Returns the value of an option, or nil if no value exists
-- @param key <string>
-- @return <mixed>
function GetOption(key)
	if _G.DEPGPStorage.options[key] ~= nil then
		return _G.DEPGPStorage.options[key]
	elseif addon.data.default_options[key] ~= nil then
		return addon.data.default_options[key]
	end
	return nil
end

--- Set option
-- Sets an option key to the given val
-- @param key <string>
-- @param val <mixed>
function SetOption(key, val)
	_G.DEPGPStorage.options[key] = val
end

--- Set options to default
function SetOptionsToDefaults()
	_G.DEPGPStorage.options = {}
end

--- Set tmp option
-- Temporarily set an option key to the given val
-- The options menu can be "cancelled", so changed options must be staged
-- @param key <string>
-- @param val <mixed>
function SetTmpOption(key, val)
	addon.data.tmp_options[key] = val
end

--- Commit tmp options
-- When the user hits "Okay" or "Apply" on the options menu
function CommitTmpOptions()
	for key, val in _G.pairs(addon.data.tmp_options) do
		SetOption(key, val)
	end
end

--- Reset tmp options
-- When the user hits "Cancel" on the options menu
function ResetTmpOptions()
	addon.data.tmp_options = {}
end
