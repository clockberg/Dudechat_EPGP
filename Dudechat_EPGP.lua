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
	self:InitRoles()
	self:InitTierMap()
	self:InitRoleTextures()
	self:InitItemsData()
	self:InitInterfaceOptions()
	self:InitItemTooltipMod()
end

function DEPGP:InitRoles()
	self.roles = {
		["PROT_WAR"] = "PROT_WAR",
		["FURY_WAR"] = "FURY_WAR",
		["ROGUE"] = "ROGUE",
		["HUNTER"] = "HUNTER",
		["RESTO_SHAM"] = "RESTO_SHAM",
		["ELE_SHAM"] = "ELE_SHAM",
		["ENHANCE_SHAM"] = "ENHANCE_SHAM",
		["RESTO_DRUID"] = "RESTO_DRUID",
		["BEAR"] = "BEAR",
		["CAT"] = "CAT",
		["BOOMKIN"] = "BOOMKIN",
		["MAGE"] = "MAGE",
		["WARLOCK"] = "WARLOCK",
		["HOLY_PRIEST"] = "HOLY_PRIEST",
		["SHADOW_PRIEST"] = "SHADOW_PRIEST",
	}
end

function DEPGP:InitTierMap()
	self.tier_map = {
		[1] = "Z",
		[2] = "S",
		[3] = "A",
		[4] = "B",
		[5] = "C",
	}
end

function DEPGP:InitRoleTextures()
	self.role_textures = {
		[self.roles.PROT_WAR] = GetSpellTexture(7164),
		[self.roles.FURY_WAR] = GetSpellTexture(12303),
		[self.roles.ROGUE] = GetSpellTexture(27611),
		[self.roles.HUNTER] = GetSpellTexture(1510),
		[self.roles.RESTO_SHAM] = GetSpellTexture(16367),
		[self.roles.ELE_SHAM] = GetSpellTexture(28293),
		[self.roles.ENHANCE_SHAM] = GetSpellTexture(23881),
		[self.roles.RESTO_DRUID] = GetSpellTexture(27527),
		[self.roles.BEAR] = GetSpellTexture(19030),
		[self.roles.CAT] = GetSpellTexture(5759),
		[self.roles.BOOMKIN] = GetSpellTexture(9835),
		[self.roles.MAGE] = GetSpellTexture(20869),
		[self.roles.WARLOCK] = GetSpellTexture(20791),
		[self.roles.HOLY_PRIEST] = GetSpellTexture(17843),
		[self.roles.SHADOW_PRIEST] = GetSpellTexture(22917),
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
