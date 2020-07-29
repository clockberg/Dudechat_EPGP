--- Dudechat EPGP
-- @author clockberg <clockberg.gaming@gmail.com>
-- @license MIT

local _, addon = ...

--- Hook function for OnEvent
-- We wait to initialize the addon until after the ADDON_LOADED event trigger,
-- so that all our files are loaded and available
-- @param _ self
-- @param event <string> the name of the event that fired
-- @param arg1 <mixed> event arg
local function hook_onevent(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Dudechat_EPGP" then
		addon.app = DEPGP:New()
		addon.app:Init()
	end
end

-- Create a frame just so we can hook OnEvent
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", hook_onevent)

-- Set up chat commands
SLASH_DEPGP1 = "/depgp"
function SlashCmdList.DEPGP(command, editbox)
	if command == "" or command == nil then
		-- show the default window
		print("dEPGP show default")
	end
	if command == "item" or command == "dist" or command == "distribute" then
		addon.app.item_dist_window:Toggle()
	else
		print ("dEPGP usage")
	end
end

-- Create DEPGP class
DEPGP = {}
DEPGP.__index = DEPGP
function DEPGP:New()
	local self = {}
	setmetatable(self, DEPGP)
	return self
end

--- Init the app
-- Loads and builds the addon.
function DEPGP:Init()
	-- Load constants
	self.name = "dEPGP"
	self.name_long = "Dudechat EPGP"
	self.specs = self:GetSpecs()
	self.spec_textures = self:GetSpecTextures()
	self.spec_abbrs = self:GetSpecAbbrs()
	self.grades = self:GetGrades()

	-- Load data
	self.data = {}
	self.data.default_options = self:GetDefaultOptionsData()
	self.data.tmp_options = {}
	self.data.items = self:GetItemsData()

	-- Load storage
	if DEPGPStorage == nil then
		DEPGPStorage = {}
	end
	self.storage = DEPGPStorage
	if self.storage.options == nil then
		self.storage.options = {}
	end

	-- Load roster
	self:LoadRoster()

	-- Load app modules
	self.interface_options = self:BuildInterfaceOptions()
	self.item_tooltip_mod = self:BuildItemTooltipMod()
	self.item_dist_window = self:BuildItemDistWindow()
end

--- Loads player data into the app from the guild roster
-- The only way to get an updated officer note is through GetGuildRosterInfo(<gindex>),
-- and the only way to get `gindex` is by scanning the whole guild roster and saving it
-- for each player.
-- Also the `gindex` changes constantly, based on logins, logouts, sorting, etc. So we
-- have to repeatedly load the guild roster to refresh `gindex`.
function DEPGP:LoadRoster()
	local num_members, _, _ = GetNumGuildMembers()
	if num_members == 0 then
		return
	end
	self.storage.roster = {}
	for i = 1, num_members do
		local data = self:GetPlayerDataByGIndex(i)
		self.storage.roster[data.name] = data
	end
	print("Loaded " .. num_members .. " guild members data")
end

--- Returns guild roster info for a specific player
-- @param gindex <number> The guild roster index of the player. Note: changes frequently.
-- @return <table>
function DEPGP:GetPlayerDataByGIndex(gindex)
	local name, _, _, level, _, _, _, onote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(gindex)
	return {
		["name"] = name,
		["level"] = level,
		["onote"] = onote,
		["class"] = class,
		["guid"] = guid,
		["gindex"] = gindex,
	}
end

--- Returns player data for the given player name
-- If the response from the server doesn't match the local roster cache,
-- we need to reload the whole roster in order to get accurate data.
-- @param name <string> The name of the player to return data for
-- @return <table> or <nil>
function DEPGP:GetPlayerData(name)
	local cached_data = self.storage.roster[name]
	if cached_data == nil then
		-- No record of this player
		-- Maybe not in the guild, maybe another problem
		return nil
	end
	local fresh_data = self:GetPlayerDataByGIndex(cached_data.gindex)
	-- See if the fresh data matches
	if fresh_data.name == name then
		return fresh_data
	end
	-- Local roster cache is dirty, need to refresh
	self:LoadRoster()
	return self.storage.roster[name]
end

--- Returns EP and GP from the parsed officer note
-- @param onote <string> The officer note to parse
-- @return <table> {"ep" = <number>, "gp" = <number>}
function DEPGP:ParseOfficerNote(onote)
	local ep, gp = string.match(onote, "(%d+)%s*,%s*(%d+)")
	if ep == nil then ep = 0 end
	if gp == nil then gp = 0 end
	return {
		["ep"] = ep,
		["gp"] = gp,
	}
end

--- Returns the player name with the server part removed
-- @param name <string>
-- @return <string>
function DEPGP:RemoveServerFromName(name)
	local s, e = string.find(name, "-")
	if s == nil then return name end
	return string.sub(name, 1, s - 1)
end

--- Returns the PR from the given EP and GP
-- @param ep <number>
-- @param gp <number>
-- @return <number>
function DEPGP:GetPR(ep, gp)
	if gp == 0 then return 0 end
	return round(ep / gp, 2)
end

--- Returns the value of an app option
-- @param key <string>
-- @return <mixed>
function DEPGP:GetOption(key)
	if self.storage.options[key] ~= nil then
		return self.storage.options[key]
	elseif self.data.default_options[key] ~= nil then
		return self.data.default_options[key]
	end
	return ""
end

--- Sets an app option
-- @param key <string>
-- @param val <mixed>
function DEPGP:SetOption(key, val)
	self.storage.options[key] = val
end

--- Temporarily set an app option
-- The options menu can be "cancelled", so changed options must be staged
-- @param key <string>
-- @param val <mixed>
function DEPGP:SetTmpOption(key, val)
	self.data.tmp_options[key] = val
end

--- Reset app options to default
-- The `self.storage.options` table is just options that have been changed
function DEPGP:SetOptionsToDefaults()
	self.storage.options = {}
end

--- Commit the temp app options to storage
-- Happens when the options menu is "applied" or "okayed"
function DEPGP:CommitTmpOptions()
	for key, val in pairs(self.data.tmp_options) do
		self:SetOption(key, val)
	end
end

--- Discard the temp app options
-- Happens when the options menu is "cancelled"
function DEPGP:DiscardTmpOptions()
	self.data.tmp_options = {}
end

--- Returns an ordered table of specs
-- @return <table>
function DEPGP:GetSpecs()
	return {
		"PROT_WAR",
		"FURY_WAR",
		"ROGUE",
		"HUNTER",
		"RESTO_SHAM",
		"ELE_SHAM",
		"ENHANCE_SHAM",
		"RESTO_DRUID",
		"BEAR_DRUID",
		"CAT_DRUID",
		"BOOMKIN",
		"MAGE",
		"WARLOCK",
		"HOLY_PRIEST",
		"SHADOW_PRIEST",
		"HOLY_PALADIN",
		"RET_PALADIN",
		"PROT_PALADIN",
	}
end

--- Returns a mapping from spec to texture path for an icon
-- @return <table>
function DEPGP:GetSpecTextures()
	return {
		["PROT_WAR"] = GetSpellTexture(7164),
		["FURY_WAR"] = GetSpellTexture(12303),
		["ROGUE"] = "Interface\\ICONS\\ClassIcon_Rogue.PNG",
		["HUNTER"] = "Interface\\ICONS\\ClassIcon_Hunter.PNG",
		["RESTO_SHAM"] = GetSpellTexture(16367),
		["ELE_SHAM"] = GetSpellTexture(529),
		["ENHANCE_SHAM"] = GetSpellTexture(23881),
		["RESTO_DRUID"] = GetSpellTexture(27527),
		["BEAR_DRUID"] = GetSpellTexture(19030),
		["CAT_DRUID"] = GetSpellTexture(5759),
		["BOOMKIN"] = GetSpellTexture(9835),
		["MAGE"] = "Interface\\ICONS\\ClassIcon_Mage.PNG",
		["WARLOCK"] = "Interface\\ICONS\\ClassIcon_Warlock.PNG",
		["HOLY_PRIEST"] = "Interface\\ICONS\\ClassIcon_Priest.PNG",
		["SHADOW_PRIEST"] = GetSpellTexture(589),
		["HOLY_PALADIN"] = GetSpellTexture(635),
		["RET_PALADIN"] = GetSpellTexture(10300),
		["PROT_PALADIN"] = GetSpellTexture(10292),
	}
end

--- Returns a mapping from spec to spec name
-- @return <table>
function DEPGP:GetSpecAbbrs()
	return {
		["PROT_WAR"] = "ProtWar",
		["FURY_WAR"] = "Fury",
		["ROGUE"] = "Rogue",
		["HUNTER"] = "Hunter",
		["RESTO_SHAM"] = "RSham",
		["ELE_SHAM"] = "Ele",
		["ENHANCE_SHAM"] = "Enh",
		["RESTO_DRUID"] = "RDruid",
		["BEAR_DRUID"] = "Bear",
		["CAT_DRUID"] = "Cat",
		["BOOMKIN"] = "Boomkin",
		["MAGE"] = "Mage",
		["WARLOCK"] = "Lock",
		["HOLY_PRIEST"] = "HPriest",
		["SHADOW_PRIEST"] = "SPriest",
		["HOLY_PALADIN"] = "HPal",
		["RET_PALADIN"] = "Ret",
		["PROT_PALADIN"] = "ProtPal",
	}
end

--- Returns a table of grades, ordered by highest to lowest
-- @return <table>
function DEPGP:GetGrades()
	return {
		"Z",
		"S",
		"A",
		"B",
		"C",
	}
end

--- Returns the size of the given table.
-- @param tbl <table>
-- @return <number>
function sizeof(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

--- Returns a new table containing the keys of the given table as values.
-- @param tbl <table>
-- @return <table>
function table_get_keys(tbl)
	local i = 1
	local keys = {}
	for key, _ in pairs(tbl) do
		keys[i] = key
		i = i + 1
	end
	return keys
end

--- Returns a new table with the key/value pairs flipped.
-- @param tbl <table>
-- @return <table>
function table_flip(tbl)
	local flipped = {}
	for key, val in pairs(tbl) do
		flipped[val] = key
	end
	return flipped
end

--- Rounds a number
-- @param num <number> The number to round
-- @param places <number> Number of decimal places to round to
-- @return <number>
function round(num, places)
	local mult = 10^(places or 0)
	return math.floor(num * mult + 0.5) / mult
end

--- Returns a "clean" menu button
-- Menu buttons have to be created repeatedly. We don't want to pollute memory
-- with old, unused menu button tables. So we reuse the table that is sent to
-- create the menu button. This function cleans out the table so it can be used again.
-- @return <table>
local menu_button = UIDropDownMenu_CreateInfo()
function get_clean_menu_button()
	menu_button.text = nil
	menu_button.value = nil
	menu_button.arg1 = nil
	menu_button.disabled = false
	menu_button.checked = false
	menu_button.isTitle = false
	menu_button.noClickSound = false
	menu_button.notClickable = false
	menu_button.notCheckable = true
	return menu_button
end

--- Returns the item ID from the given itemlink
-- @param itemlink <string>
-- @return <number> or <nil>
function extract_item_id(itemlink)
	if not itemlink or itemlink == nil then
		return nil
	end
	local item_id = string.match(itemlink, "item:(%d+)")
	return tonumber(item_id)
end
