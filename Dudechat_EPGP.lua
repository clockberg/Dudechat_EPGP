local _, addon = ...

local function init(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Dudechat_EPGP" then
		addon.app = DEPGP:New()
		addon.app:Init()
	end
end

frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", init)

DEPGP = {}
DEPGP.__index = DEPGP
function DEPGP:New()
	local self = {}
	setmetatable(self, DEPGP)
	return self
end

function DEPGP:Init()
	self:InitSpecs()
	self:InitTiers()
	self:InitItemsData()
	self:InitInterfaceOptions()
	self:InitItemTooltipMod()
end

function DEPGP:InitSpecs()
	self.specs = {
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
	self.spec_textures = {
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

function DEPGP:InitTiers()
	self.tiers = {
		"Z",
		"S",
		"A",
		"B",
		"C",
	}
end

function sizeof(tbl)
    local count = 0
    for _ in pairs(tbl) do
    	count = count + 1
    end
    return count
end

function table_get_keys(tbl)
	local i = 1
	local keys = {}
	for key, _ in pairs(tbl) do
		keys[i] = key
		i = i + 1
	end
	return keys
end

function table_flip(tbl)
	local flipped = {}
	for key, val in pairs(tbl) do
		flipped[val] = key
	end
	return flipped
end
