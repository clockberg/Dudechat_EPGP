local _, addon = ...

-- Module setup
local M = {}
addon.Util = M
local _G = _G
setfenv(1, M)

--- Send a guild message
-- @param msg <string>
function ChatGuild(msg)
	_G.SendChatMessage("{SQUARE} " .. msg, "GUILD")
end

--- Send a group message
-- @param msg <string>
-- @param is_alert <boolean>
function ChatGroup(msg, is_alert)
	if _G.IsInRaid() then
		if is_alert then
			_G.SendChatMessage("{SQUARE} " .. msg, "RAID_WARNING")
		else
			_G.SendChatMessage("{SQUARE} " .. msg, "RAID")
		end
	else
		_G.SendChatMessage("{SQUARE} " .. msg, "PARTY")
	end
end

function PlaySoundItemDrop()
	_G.PlaySound(_G.SOUNDKIT.IG_ABILITY_ICON_DROP)
end
function PlaySoundOpen()
	_G.PlaySound(_G.SOUNDKIT.IG_MAINMENU_OPEN)
end
function PlaySoundClose()
	_G.PlaySound(_G.SOUNDKIT.IG_MAINMENU_CLOSE)
end
function PlaySoundBack()
	_G.PlaySound(_G.SOUNDKIT.IG_CHAT_SCROLL_UP)
end
function PlaySoundNext()
	_G.PlaySound(_G.SOUNDKIT.IG_CHAT_SCROLL_UP)
end

--- Returns the PR from the given EP and GP
-- @param ep <number>
-- @param gp <number>
-- @return <number>
function GetPR(ep, gp)
	if gp == nil or gp == 0 then
		return 0
	end
	return Round(ep / gp, 2)
end

--- Returns the player name with the server part removed
-- @param player_name <string>
-- @return <string>
function RemoveServerFromPlayerName(player_name)
	if not player_name or player_name == nil then
		return ""
	end
	local s, e = _G.string.find(player_name, "-")
	if s == nil then return player_name end
	return _G.string.sub(player_name, 1, s - 1)
end

--- Returns the item ID from the given itemlink
-- @param itemlink <string>
-- @return <number>
function GetItemIdFromItemLink(itemlink)
	if not itemlink or itemlink == nil then
		return 0
	end
	local item_id = _G.string.match(itemlink, "item:(%d+)")
	return _G.tonumber(item_id)
end

--- Returns a number appropriate for the addon
-- Rounds to a number of places. Also limits to a range.
-- @param val <number>
-- @param places <number> (default: 1)
-- @return <number>
function AddonNumber(val, places, min, max)
	places = places or 1
	min = min or -99999
	max = max or 99999
	val = _G.tonumber(val) or 0
	val = Round(val, places)
	val = _G.min(max, _G.max(min, val))
	return val
end

--- Returns the size of the given table
-- @param tbl <table>
-- @return <number>
function SizeOf(tbl)
	if not tbl then
		return 0
	end
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
	if not tbl then
		return {}
	end
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

--- Returns the class color for the given class
-- @param player_class <string>
-- @return <table>
function GetClassColor(player_class)
	if not player_class or player_class == nil then
		return {1, 1, 1}
	end
	if player_class == "SHAMAN" then
		-- Override shaman color to blue
		-- #0070DE
		return {0, 0.4375, 0.8706}
	end
	return {_G.GetClassColor(player_class)}
end
