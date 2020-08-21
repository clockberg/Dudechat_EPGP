local _, addon = ...

-- Module setup
local M = {}
addon.Core = M
local _G = _G
setfenv(1, M)

activation_prompt = nil -- <Frame>

--- Load this module
function Load()
	if _G.DEPGPStorage.transactions == nil then
		_G.DEPGPStorage.transactions = {}
	end

	addon.Config.Load()
	addon.Options.Load()
	addon.Guild.Load()
	addon.ItemTooltip.Load()
	addon.ItemDistribute.Load()

	ActivationPrompt_Load()
	Boot()
end

function Log(message)
	_G.print(addon.short_name .. " - " .. message)
end

--- Prints an error message
-- @param message <string>
function Error(message)
	Log("Error: " .. message)
end

--- Prints a warning message
-- @param message <string>
function Warning(message)
	Log("Warning: " .. message)
end

function Disable()
	Log("Disabled")
	addon.enabled = false
end

function Enable()
	Log("Enabled")
	addon.enabled = true
end

function Deactivate()
	activation_prompt:Hide()
	if not addon.activated then
		return
	end
	addon.activated = false
	addon.ItemDistribute.Window_Close()
	Log("Deactivated")
end

function Activate()
	activation_prompt:Hide()
	if addon.activated then
		return
	end
	addon.activated = true
	addon.ItemDistribute.Window_Open()
	Log("Activated")
end

function ActivationPrompt_Load()
	activation_prompt = _G.CreateFrame("Frame", nil, nil, "TooltipBorderedFrameTemplate")
	activation_prompt:EnableMouse(true)
	activation_prompt:SetPoint("CENTER", 0, 0)
	activation_prompt:SetWidth(200)
	activation_prompt:SetHeight(50)
	activation_prompt:Hide()

	-- Title
	local title = activation_prompt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 0, -10)
	title:SetPoint("BOTTOMRIGHT", 0, 0)
	title:SetJustifyV("TOP")
	title:SetJustifyH("CENTER")
	title:SetText(addon.short_name)

	-- Activate button
	local elem = _G.CreateFrame("Button", nil, activation_prompt, "OptionsButtonTemplate")
	elem:SetPoint("TOPLEFT", 10, -25)
	elem:SetWidth(90)
	elem:SetHeight(20)
	elem:SetScript("OnClick", function (_, button)
		activation_prompt:Hide()
		Activate()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetAllPoints(elem)
	subelem:SetJustifyH("CENTER")
	subelem:SetJustifyV("CENTER")
	subelem:SetText("Activate")

	-- Deactivate button
	local elem = _G.CreateFrame("Button", nil, activation_prompt, "OptionsButtonTemplate")
	elem:SetPoint("TOPLEFT", 100, -25)
	elem:SetWidth(90)
	elem:SetHeight(20)
	elem:SetScript("OnClick", function (_, button)
		activation_prompt:Hide()
		Deactivate()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetAllPoints(elem)
	subelem:SetJustifyH("CENTER")
	subelem:SetJustifyV("CENTER")
	subelem:SetText("Deactivate")
end

function PromptActivation()
	activation_prompt:Show()
end

--- Returns true if we are the master looter, false otherwise
-- @return <boolean>
function IsMasterLooter()
	local loot_method, master_looter_party_id, _ = _G.GetLootMethod()

	-- One of 'freeforall', 'roundrobin', 'master', 'group', 'needbeforegreed', 'personalloot'
	if loot_method ~= "master" then
		return false
	end

	-- Returns 0 if player is the mater looter
	-- 1-4 if party member is master looter (corresponding to party1-4)
	-- and nil if the master looter isn't in the player's party or master looting is not used
	if master_looter_party_id ~= 0 then
		return false
	end

	return true
end

function LootOpened()
	_G.print("LootOpened")
	if not addon.enabled then
		return
	end

	-- Determine if any items are at or above the loot threshold
	local threshold = _G.GetLootThreshold()
	local slot_num = 0
	local any_above = false
	for slot = 1, _G.GetNumLootItems() do
		if (_G.LootSlotHasItem(slot)) then
			_, _, _, _, rarity = _G.GetLootSlotInfo(slot)
			if rarity >= threshold then
				any_above = true
			end
		end
	end

	if not any_above then
		return
	end

	if addon.activated and not addon.ItemDistribute.window:IsVisible() then
		addon.ItemDistribute.Window_Open()
	end
end

function HandleLoot(text, player_name)
	if not text then
		return
	end

	local item_link = _G.string.match(text, "(|.*|r)")
	if not item_link then
		return
	end

	-- 0 Poor (grey)
	-- 1 Standard (white)
	-- 2 Good (green)
	-- 3 Superior (blue)
	-- 4 Epic (purple)
	-- 5 Legendary (orange)
	local threshold = _G.GetLootThreshold()

	local _, _, item_rarity = _G.GetItemInfo(item_link)
	if item_rarity < threshold then
		-- normal item loot, not master looted
		return
	end

	-- See if this item is in the history
	if addon.ItemDistribute.History_HasItem(item_link) then
		_G.print("history has item")
		return
	else
		_G.print("history does not have item")
	end

	_G.print("HandleLoot(" .. text .. ", " .. player_name)
	_G.print(item_link)
	_G.print(threshold)
end

function Boot()
	if not addon.enabled then
		return
	end

	if not IsMasterLooter() then
		Deactivate()
		return
	end

	if addon.activated then
		return
	end

	PromptActivation()
end

-- ENCOUNTER_END: encounterID, "encounterName", difficultyID, groupSize, success
function HandleEncounterEnd(encounter_id, encounter_name, difficulty_id, group_size, success)
	if not addon.activated then
		return
	end
	if not success or success == false or success == 0 then
		return
	end
	local boss_name = addon.data.boss_names[encounter_id]
	if not boss_name then
		Log("Boss not found. Encounter ID = " .. encounter_id)
		return
	end
	local boss_ep_award = addon.data.boss_awards[encounter_id]
	if not boss_ep_award then
		Log("Boss EP Award not found. Encounter ID = " .. encounter_id)
		return
	end
	local zone_name = nil
	for tmp_zone_name, boss_ids in _G.pairs(addon.data.boss_zones) do
		for i = 1, addon.Util.SizeOf(boss_ids) do
			if boss_ids[i] == encounter_id then
				zone_name = tmp_zone_name
			end
		end
	end
	local boss_str = boss_name
	if zone_name then
		boss_str = boss_str .. " (" .. zone_name .. ")"
	end
	AddRaidEP(boss_ep_award, boss_str)

	local msg = boss_str .. " defeated! " .. boss_ep_award .. " EP awarded to the raid."
	addon.Util.ChatGuild(msg)
end

--- Adds EP to the entire raid
-- @param ep <number>
-- @param desc <string>
function AddRaidEP(ep, desc)
	AddTransaction("RAID", nil, nil, ep, 0, desc)
	for i = 1, _G.GetNumGroupMembers() do
		local name, _, _, _, _, _, _, _, _, _, _, _ = _G.GetRaidRosterInfo(i)
		Transact(name, nil, ep, true, desc, false, false)
	end
end

--- Get data for an item
-- Returns item data for the given item ID
-- @param item_id <number>
-- @return <table>
-- Return table structure:
-- 	{
-- 		["price"] = <number> gp_price, -- The base GP price of the item for anything not explicitly defined below
-- 		["by_tier"] = {
-- 			[<number> tier_num] = { -- 1 is the "best" tier, descending gets worse
-- 				["price"] = <number> gp_price, -- The GP price of the item for this tier
-- 				["specs"] = { -- The names of the specs that fall under this tier for this item
-- 					"ROGUE",
-- 					"FURY_WAR",
-- 					-- ..
-- 				}
-- 			},
-- 			-- ..
-- 		}
-- 	}
function GetItemData(item_id)
	local item_data = addon.data.items[item_id]
	if item_data and not item_data.by_tier then
		item_data.by_tier = {}
	end
	return item_data
end

--- Add a transaction to storage
-- @param player_name <string>
-- @param item_id <number>
-- @param item_name <string>
-- @param ep_change <number>
-- @param gp_change <number>
-- @param desc <string>
function AddTransaction(player_name, item_id, item_name, ep_change, gp_change, desc)
	local transaction = {
		["player_name"] = player_name,
		["item_id"] = item_id,
		["item_name"] = item_name,
		["ep_change"] = ep_change,
		["gp_change"] = gp_change,
		["desc"] = desc,
		["at"] = _G.date("%y-%m-%d %H:%M:%S"),
	}
	_G.table.insert(_G.DEPGPStorage.transactions, transaction)
end

--- Create a transaction
-- The transaction can either be for EP or GP, not both. The transaction
-- is performed by getting the current EPGP of the player from the officer
-- note and adding or subtracting the amount given to the appropriate field.
-- Then the new EPGP is put into the officer note.
-- If the save parameter is true, the transaction is also added to the saved
-- list of transactions in the addon's storage.
-- @param player_name <string>
-- @param item_id <number>
-- @param amount <number> (default: 0) Can be negative
-- @param is_ep <boolean> (default: true) If true, EP. If false, GP
-- @param desc <string> Transaction description
-- @param save <boolean> (default: true) Save the transaction in storage
-- @param announce <boolean> (default: true) Announce the transaction in guild
function Transact(player_name, item_id, amount, is_ep, desc, save, announce)
	-- Defaults
	if amount == nil then
		amount = 0
	end
	if is_ep == nil then
		is_ep = true
	end
	if save == nil then
		save = true
	end
	if announce == nil then
		announce = true
	end

	amount = addon.Util.AddonNumber(amount)

	-- Item info
	local item_name = nil
	local item_link = nil
	if item_id ~= nil then
		item_name, item_link = _G.GetItemInfo(item_id)
	end

	local ep_change = 0
	local gp_change = 0
	if is_ep then
		ep_change = amount
	else
		gp_change = amount
	end

	-- Save in transaction table
	if save then
		AddTransaction(player_name, item_id, item_name, ep_change, gp_change, desc)
	end

	-- Update guild officer note
	addon.Guild.UpdateEPGP(player_name, ep_change, gp_change)

	if announce then
		local msg = ""
		if item_id then
			-- Item transaction
			if item_link ~= nil then
				msg = item_link
			elseif item_name ~= nil then
				msg = item_name
			elseif item_id ~= nil then
				msg = "Item #" .. item_id
			end
			msg = msg .. " to " .. player_name .. " for "
			if ep_change ~= 0 then
				msg = msg .. ep_change .. " EP"
			elseif gp_change ~= 0 then
				msg = msg .. gp_change .. " GP"
			else
				msg = "FREE"
			end
		else
			-- Not an item transaction
			if ep_change ~= 0 then
				-- EP only
				if ep_change > 0 then
					msg = ep_change .. " EP given to "
				else
					msg = _G.math.abs(ep_change) .. " EP taken from "
				end
			elseif gp_change ~= 0 then
				-- GP only
				if gp_change > 0 then
					msg = gp_change .. " GP given to "
				else
					msg = _G.math.abs(gp_change) .. " GP taken from "
				end
			else
				msg = "No change for "
			end
			msg = msg .. player_name
		end
		if desc ~= nil and desc then
			msg = msg .. " (" .. desc .. ")"
		end

		addon.Util.ChatGuild(msg)
	end
end
