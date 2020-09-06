local _, addon = ...

addon.data = addon.data or {}
addon.data.default_options = {
	["ItemTooltip.show"] = true,
	["ItemDistribute.x"] = 200,
	["ItemDistribute.y"] = -200,
	["ItemDistribute.lock"] = false,
	["ItemDistribute.announce_raid_warning"] = false,
	["ItemDistribute.default_price"] = 1,
	["Tiers.pr_mult.Z"] = 20,
	["Tiers.pr_mult.S"] = 10,
	["Tiers.pr_mult.A"] = 5,
	["Tiers.pr_mult.B"] = 1,
}
