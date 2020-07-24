local _, ns = ...

ns.ROLE_PROT_WAR =      "PROT_WAR"
ns.ROLE_DPS_WAR =       "DPS_WAR"
ns.ROLE_ROGUE =         "ROGUE"
ns.ROLE_HUNTER =        "HUNTER"
ns.ROLE_RESTO_SHAM =    "RESTO_SHAM"
ns.ROLE_ELE_SHAM =      "ELE_SHAM"
ns.ROLE_ENH_SHAM =      "ENH_SHAM"
ns.ROLE_RESTO_DRUID =   "RESTO_DRUID"
ns.ROLE_BEAR_DRUID =    "BEAR_DRUID"
ns.ROLE_CAT_DRUID =     "CAT_DRUID"
ns.ROLE_BOOMKIN_DRUID = "BOOMKIN_DRUID"
ns.ROLE_MAGE =          "MAGE"
ns.ROLE_WARLOCK =       "WARLOCK"
ns.ROLE_HOLY_PRIEST =   "HOLY_PRIEST"
ns.ROLE_SHADOW_PRIEST = "SHADOW_PRIEST"

ns.TIER_Z =             "Z"
ns.TIER_S =             "S"
ns.TIER_A =             "A"
ns.TIER_B =             "B"
ns.TIER_C =             "C"

ns.roleIconTextures = {
    [ns.ROLE_PROT_WAR] = GetSpellTexture(7164),
	[ns.ROLE_DPS_WAR] = GetSpellTexture(12303),
	[ns.ROLE_ROGUE] = GetSpellTexture(27611),
	[ns.ROLE_RESTO_SHAM] = GetSpellTexture(16367),
	[ns.ROLE_ELE_SHAM] = GetSpellTexture(28293),
	[ns.ROLE_ENH_SHAM] = GetSpellTexture(23881),
	[ns.ROLE_RESTO_DRUID] = GetSpellTexture(27527),
	[ns.ROLE_BEAR_DRUID] = GetSpellTexture(19030),
	[ns.ROLE_CAT_DRUID] = GetSpellTexture(5759),
	[ns.ROLE_BOOMKIN_DRUID] = GetSpellTexture(9835),
	[ns.ROLE_MAGE] = GetSpellTexture(20869),
	[ns.ROLE_WARLOCK] = GetSpellTexture(20791),
	[ns.ROLE_HOLY_PRIEST] = GetSpellTexture(17843),
	[ns.ROLE_SHADOW_PRIEST] = GetSpellTexture(22917)
}
