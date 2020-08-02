local _, addon = ...

-- Structure:
-- {
-- 	[<number> item_id] = {
-- 		["name"] = "<item name>" -- This is just for reference, not actually needed
-- 		["price"] = <number> gp_price, -- The base GP price of the item for anything not explicitly defined below
-- 		["by_tier"] = {
-- 			[<number> tier_num] = { -- 1 is the "best" tier, and 5 is the worst
-- 				["price"] = <number> gp_price, -- The GP price of the item for this tier
-- 				["specs"] = { -- The names of the specs that fall under this tier for this item
-- 					"ROGUE",
-- 					"FURY_WAR",
-- 					-- ..
-- 				}
-- 			},
-- 			-- ..
-- 		}
-- 	},
-- 	-- ..
-- }
addon.data = addon.data or {}
addon.data.items = {
	[3363] = {
		["name"] = "Frayed Belt",
		["price"] = 1,
		["by_tier"] = {
			[1] = {
				["price"] = 555,
				["specs"] = {
					"ROGUE",
				}
			},
			[2] = {
				["price"] = 25,
				["specs"] = {
					"SHADOW_PRIEST",
				}
			},
			[4] = {
				["price"] = 2,
				["specs"] = {
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
			}
		}
	},
	[1377] = {
		["name"] = "Frayed Gloves",
		["price"] = 1,
		["by_tier"] = {
			[1] = {
				["price"] = 50,
				["specs"] = {
					"HUNTER",
				}
			},
			[2] = {
				["price"] = 25,
				["specs"] = {
					"ELE_SHAM",
					"BOOMKIN",
					"MAGE",
					"WARLOCK",
				}
			},
			[3] = {
				["price"] = 10,
				["specs"] = {
					"PROT_WAR",
				}
			},
			[4] = {
				["price"] = 5,
				["specs"] = {
					"PROT_WAR",
					"FURY_WAR",
					"ROGUE",
				}
			},
			[5] = {
				["price"] = 2,
				["specs"] = {
					"RESTO_SHAM",
					"RESTO_DRUID",
					"HOLY_PRIEST",
				}
			}
		}
	},
	[153] = {
		["name"] = "Primitive Kilt",
		["price"] = 1,
		["by_tier"] = {
			[3] = {
				["price"] = 5,
				["specs"] = {
					"WARLOCK",
				}
			}
		}
	},
	[1368] = {
		["name"] = "Ragged Leather Gloves",
		["price"] = 1,
		["by_tier"] = {
			[3] = {
				["price"] = 5,
				["specs"] = {
					"ROGUE",
				}
			}
		}
	},
	[1370] = {
		["name"] = "Ragged Leather Bracers",
		["price"] = 1,
		["by_tier"] = {
			[1] = {
				["price"] = 22,
				["specs"] = {
					"PROT_WAR",
				}
			},
			[2] = {
				["price"] = 12,
				["specs"] = {
					"FURY_WAR",
				}
			}
		}
	},
	[139] = {
		["name"] = "Brawler's Pants",
		["price"] = 1,
		["by_tier"] = {
			[1] = {
				["price"] = 50,
				["specs"] = {
					"PROT_WAR",
					"FURY_WAR",
					"ROGUE",
				}
			},
			[2] = {
				["price"] = 28,
				["specs"] = {
					"HUNTER",
					"ENH_SHAM",
				}
			}
		}
	},
	[2654] = {
		["name"] = "Brawler's Pants",
		["price"] = 1,
		["by_tier"] = {
			[1] = {
				["price"] = 50,
				["specs"] = {
					"PROT_WAR",
					"FURY_WAR",
					"ROGUE",
				}
			},
			[2] = {
				["price"] = 28,
				["specs"] = {
					"HUNTER",
					"ENH_SHAM",
				}
			}
		}
	}
}
