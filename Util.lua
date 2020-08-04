local _, addon = ...

-- Module setup
local M = {}
addon.Util = M
local _G = _G
local dd = function (msg)
	-- _G.print("Util." .. msg)
end
setfenv(1, M)

--- Returns the player name with the server part removed
-- @param name <string>
-- @return <string>
function RemoveServerFromPlayerName(name)
	dd("RemoveServerFromPlayerName")
	if not name or name == nil then
		return ""
	end
	local s, e = _G.string.find(name, "-")
	if s == nil then return name end
	return _G.string.sub(name, 1, s - 1)
end

--- Returns the item ID from the given itemlink
-- @param itemlink <string>
-- @return <number>
function GetItemIdFromItemLink(itemlink)
	dd("GetItemIdFromItemLink")
	if not itemlink or itemlink == nil then
		return 0
	end
	local item_id = _G.string.match(itemlink, "item:(%d+)")
	return _G.tonumber(item_id)
end

--- Returns the size of the given table
-- @param tbl <table>
-- @return <number>
function SizeOf(tbl)
	dd("SizeOf")
	local count = 0
	for _ in _G.pairs(tbl) do
		count = count + 1
	end
	return count
end

--- Returns a new table containing the keys of the given table as values
-- @param tbl <table>
-- @return <table>
function TableGetKeys(tbl)
	dd("TableGetKeys")
	local i = 1
	local keys = {}
	for key, _ in _G.pairs(tbl) do
		keys[i] = key
		i = i + 1
	end
	return keys
end

--- Returns a new table with the key/value pairs flipped
-- @param tbl <table>
-- @return <table>
function TableFlip(tbl)
	dd("TableFlip")
	local flipped = {}
	for key, val in _G.pairs(tbl) do
		flipped[val] = key
	end
	return flipped
end

--- Rounds a number
-- @param num <number> The number to round
-- @param places <number> Number of decimal places to round to
-- @return <number>
function Round(num, places)
	dd("Round")
	local mult = 10^(places or 0)
	return _G.math.floor(num * mult + 0.5) / mult
end

--- Returns a clean menu button
-- Menu buttons have to be created repeatedly. We don't want to pollute memory
-- with old, unused menu button tables. So we reuse the table that is sent to
-- create the menu button. This function cleans out the table so it can be used again.
-- @return <table>
local button = _G.UIDropDownMenu_CreateInfo()
function GetMenuButton()
	button.text = nil
	button.value = nil
	button.arg1 = nil
	button.disabled = false
	button.checked = false
	button.isTitle = false
	button.noClickSound = false
	button.notClickable = false
	button.notCheckable = true
	button.func = nil
	return button
end
