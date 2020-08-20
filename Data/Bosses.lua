local _, addon = ...

-- see https://wow.gamepedia.com/DungeonEncounterID

addon.data = addon.data or {}
addon.data.boss_names = {
	[709] = "The Prophet Skeram",
	[710] = "The Silithid Royalty",
	[711] = "Battleguard Sartura",
	[712] = "Fankriss the Unyielding",
	[713] = "Viscidus",
	[714] = "Princess Huhuran",
	[715] = "The Twin Emperors",
	[716] = "Ouro",
	[717] = "C'Thun",
}
addon.data.boss_awards = {
	[709] = 10,
	[710] = 10,
	[711] = 10,
	[712] = 10,
	[713] = 10,
	[714] = 10,
	[715] = 10,
	[716] = 10,
	[717] = 20,
}
addon.data.boss_zones = {
	["AQ40"] = {
		709, 710, 711, 712, 713, 714, 715, 716, 717
	},
}
