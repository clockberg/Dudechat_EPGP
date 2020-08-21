--- Dudechat EPGP
-- @author clockberg <clockberg.gaming@gmail.com>
-- @license MIT

-- Items are currently "hardcoded" in Data/Items.lua.
-- Eventually will want to have a way to import item overrides
-- in-game, using a big textarea input that accepts CSV
-- of some sort that saves to DEPGPStorage. Then would need
-- to update the Core.GetItemData function to correctly
-- grab from DEPGPStorage.

local _, addon = ...

--- Addon globals
addon.short_name = "dEPGP"
addon.full_name = "Dudechat EPGP"
addon.addon_name = "Dudechat_EPGP"
addon.enabled = true
addon.activated = false

--- Onevent handler
-- We wait to initialize the addon until after the ADDON_LOADED event triggers,
-- so that all our files are loaded and available
-- @param _ <Frame> self
-- @param event <string> the name of the event that fired
-- @param arg1 <mixed> event arg
local function OnEvent(_, event, arg1, arg2, arg3, arg4, arg5)
	-- ADDON_LOADED: "addOnName"
	if event == "ADDON_LOADED" and arg1 == addon.addon_name then
		addon.Core.Load()
	-- ENCOUNTER_END: encounterID, "encounterName", difficultyID, groupSize, success
	elseif event == "ENCOUNTER_END" then
		addon.Core.HandleEncounterEnd(arg1, arg2, arg3, arg4, arg5)
	elseif event == "PARTY_LOOT_METHOD_CHANGED" then
		addon.Core.Boot()
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		addon.Core.Boot()
	elseif event == "LOOT_OPENED" then
		addon.Core.LootOpened()
	elseif event == "CHAT_MSG_LOOT" then
		-- addon.Core.HandleLoot(arg1, arg2)
	end
end

-- Create a frame to hook OnEvent
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:SetScript("OnEvent", OnEvent)

-- Set up chat command
SLASH_DEPGP1 = "/depgp"

--- Chat command handler
-- @param command <string>
-- @param editbox <Frame>
function SlashCmdList.DEPGP(command, editbox)
	if command == "" or command == nil then
		addon.ItemDistribute.Window_Toggle()
	elseif command == "item" or command == "dist" or command == "distribute" then
		addon.ItemDistribute.Window_Toggle()
	elseif command == "on" then
		addon.Core.Activate()
	elseif command == "off" then
		addon.Core.Deactivate()
	elseif command == "test" then
		--addon.Core.HandleEncounterEnd(123, "The Prophet Skeram", 9, 40, 1)
		--addon.Core.Transact("Clockbergo", nil, 10, true, "RAID BOSS KILL", false, false)
	else
		addon.Core.Log("dist | on | off | test")
	end
end

-- Set up storage
if DEPGPStorage == nil then
	DEPGPStorage = {}
end
