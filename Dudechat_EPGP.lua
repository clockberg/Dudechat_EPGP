--- Dudechat EPGP
-- @author clockberg <clockberg.gaming@gmail.com>
-- @license MIT

local _, addon = ...

--- Addon globals
addon.short_name = "dEPGP"
addon.full_name = "Dudechat EPGP"
addon.addon_name = "Dudechat_EPGP"

--- Onevent handler
-- We wait to initialize the addon until after the ADDON_LOADED event triggers,
-- so that all our files are loaded and available
-- @param _ <Frame> self
-- @param event <string> the name of the event that fired
-- @param arg1 <mixed> event arg
local function OnEvent(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addon.addon_name then
		addon.Core.Load()
	end
end

-- Create a frame to hook OnEvent
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)

-- Set up chat command
SLASH_DEPGP1 = "/depgp"

--- Chat command handler
-- @param command <string>
-- @param editbox <Frame>
function SlashCmdList.DEPGP(command, editbox)
	if command == "" or command == nil then
		print(addon.short_name .. ": default")
		addon.ItemDistribute.Window_Toggle()
	elseif command == "item" or command == "dist" or command == "distribute" then
		print(addon.short_name .. ": distribute")
		addon.ItemDistribute.Window_Toggle()
	else
		print(addon.short_name .. ": usage")
	end
end

-- Set up storage
if DEPGPStorage == nil then
	DEPGPStorage = {}
end
