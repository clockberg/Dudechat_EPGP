local _, ns = ...

ns.dbItems = {
    [8925] = {
        ["Name"] = "Crystal Vial",
        ["Priority"] = "hello world",
        ["Rankings"] = {
            [ns.TIER_Z] = {
                ["Value"] = 50,
                ["Roles"] = {
                    ns.ROLE_PROT_WAR
                }
            },
            [ns.TIER_S] = {
                ["Value"] = 25,
                ["Roles"] = {
                    ns.ROLE_DPS_WAR
                }
            },
            [ns.TIER_B] = {
                ["Value"] = 2,
                ["Roles"] = {
                    ns.ROLE_ROGUE
                }
            }
        }
    },
    [13463] = {
        ["Name"] = "Dreamfoil",
        ["Priority"] = "hello world",
        ["Rankings"] = {
            [ns.TIER_Z] = {
                ["Value"] = 50,
                ["Roles"] = {
                    ns.ROLE_DPS_WAR
                }
            },
            [ns.TIER_S] = {
                ["Value"] = 25,
                ["Roles"] = {
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_PROT_WAR,
                    ns.ROLE_DPS_WAR,
                    ns.ROLE_ROGUE,
                    ns.ROLE_RESTO_SHAM,
                    ns.ROLE_ELE_SHAM,
                    ns.ROLE_ENH_SHAM,
                    ns.ROLE_BEAR_DRUID,
                    ns.ROLE_RESTO_DRUID,
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_WARLOCK,
                }
            },
            [ns.TIER_A] = {
                ["Value"] = 10,
                ["Roles"] = {
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_PROT_WAR,
                    ns.ROLE_DPS_WAR,
                    ns.ROLE_ROGUE,
                }
            },
            [ns.TIER_B] = {
                ["Value"] = 5,
                ["Roles"] = {
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_ROGUE,
                    ns.ROLE_RESTO_SHAM,
                }
            },
            [ns.TIER_C] = {
                ["Value"] = 2,
                ["Roles"] = {
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_BEAR_DRUID,
                    ns.ROLE_RESTO_DRUID,
                    ns.ROLE_BOOMKIN_DRUID,
                    ns.ROLE_WARLOCK,
                }
            }
        }
    },
    [13465] = {
        ["Name"] = "Mountain Silversage",
        ["Priority"] = "awefawef",
        ["Rankings"] = {
            [ns.TIER_A] = {
                ["Value"] = 5,
                ["Roles"] = {
                    ns.ROLE_ENH_SHAM
                }
            }
        }
    }
}
