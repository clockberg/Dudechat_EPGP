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
					["roles"] = {
						self.roles.HUNTER
					}
				},
				[2] = {
					["price"] = 25,
					["roles"] = {
						self.roles.FURY_WAR
					}
				},
				[4] = {
					["price"] = 2,
					["roles"] = {
						self.roles.ROGUE
					}
				}
			}
		},
		[1377] = {
			["name"] = "Frayed Gloves",
			["by_tier"] = {
				[1] = {
					["price"] = 50,
					["roles"] = {
						self.roles.FURY_WAR
					}
				},
				[2] = {
					["price"] = 25,
					["roles"] = {
						self.roles.BOOMKIN,
						self.roles.PROT_WAR,
						self.roles.FURY_WAR,
						self.roles.ROGUE,
						self.roles.RESTO_SHAM,
						self.roles.ELE_SHAM,
						self.roles.BEAR,
						self.roles.RESTO_DRUID,
						self.roles.WARLOCK,
					}
				},
				[3] = {
					["price"] = 10,
					["roles"] = {
						self.roles.PROT_WAR,
						self.roles.FURY_WAR,
						self.roles.ROGUE,
					}
				},
				[4] = {
					["price"] = 5,
					["roles"] = {
						self.roles.BOOMKIN,
						self.roles.ROGUE,
						self.roles.RESTO_SHAM,
					}
				},
				[5] = {
					["price"] = 2,
					["roles"] = {
						self.roles.BEAR,
						self.roles.RESTO_DRUID,
						self.roles.BOOMKIN,
						self.roles.WARLOCK,
					}
				}
			}
		},
		[153] = {
			["name"] = "Primitive Kilt",
			["by_tier"] = {
				[3] = {
					["price"] = 5,
					["roles"] = {
						self.roles.WARLOCK
					}
				}
			}
		}
	}
end
