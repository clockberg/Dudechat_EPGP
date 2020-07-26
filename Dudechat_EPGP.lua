local _, addon = ...

local function hook(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Dudechat_EPGP" then
		addon.app = DEPGP:New()
		addon.app:Init()
	end
end

frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", hook)

SLASH_DEPGP1 = "/depgp"
function SlashCmdList.DEPGP(command, editbox)
	if command == "item" then
		addon.app.item_dist_window:Toggle()
	else
		-- show default window
	end
end

DEPGP = {}
DEPGP.__index = DEPGP
function DEPGP:New()
	local self = {}
	setmetatable(self, DEPGP)
	return self
end

function DEPGP:Init()
	-- load constants
	self.specs = self:GetSpecs()
	self.spec_textures = self:GetSpecTextures()
	self.grades = self:GetGrades()

	-- load data
	self.data = {}
	self.data.default_options = self:GetDefaultOptionsData()
	self.data.tmp_options = {}
	self.data.items = self:GetItemsData()

	-- load storage
	if DEPGPStorage == nil then
		DEPGPStorage = {}
	end
	self.storage = DEPGPStorage
	if self.storage.options == nil then
		self.storage.options = {}
	end

	-- load app modules
	self.interface_options = self:BuildInterfaceOptions()
	self.item_tooltip_mod = self:BuildItemTooltipMod()
	self.item_dist_window = self:BuildItemDistWindow()
end

function DEPGP:GetOption(key)
	if self.storage.options[key] ~= nil then
		return self.storage.options[key]
	elseif self.data.default_options[key] ~= nil then
		return self.data.default_options[key]
	end
	return ""
end

function DEPGP:SetOption(key, val)
	self.storage.options[key] = val
end

function DEPGP:SetTmpOption(key, val)
	self.data.tmp_options[key] = val
end

function DEPGP:SetOptionsToDefaults()
	self.storage.options = {}
end

function DEPGP:CommitTmpOptions()
	for key, val in pairs(self.data.tmp_options) do
		self:SetOption(key, val)
	end
end

function DEPGP:DiscardTmpOptions()
	self.data.tmp_options = {}
end

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

--- Returns a table of grades, ordered by highest to lowest
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
-- @param tbl table
-- @return int
function sizeof(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

--- Returns a new table containing the keys of the given table as values.
-- @param tbl table
-- @return table
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
-- @param tbl table
-- @return table
function table_flip(tbl)
	local flipped = {}
	for key, val in pairs(tbl) do
		flipped[val] = key
	end
	return flipped
end

--- Rounds the given number to the given number of decimal places
-- @param num number
-- @return number
function round(num, places)
	local mult = 10^(places or 0)
	return math.floor(num * mult + 0.5) / mult
end
