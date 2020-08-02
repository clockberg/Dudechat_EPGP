local _, addon = ...

addon.data = addon.data or {}
addon.data.specs = {
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
addon.data.spec_textures = {
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