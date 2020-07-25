local _, addon = ...

function DEPGP:InitItemsData()
	if self.data == nil then
		self.data = {}
	end
	self.data.items = {
		[3363] = {
			["name"] = "Frayed Belt",
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
			["by_tier"] = {
				[3] = {
					["price"] = 5,
					["specs"] = {
						"WARLOCK",
					}
				}
			}
		}
	}
end
