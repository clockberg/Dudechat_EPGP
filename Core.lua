local _, addon = ...

-- Module setup
local M = {}
addon.Core = M
local _G = _G
setfenv(1, M)

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
end

function Error(message)
	_G.print("Error: " .. message)
end

function Warning(message)
	_G.print("Warning: " .. message)
end

--- Create a transaction
-- @param player_name <string>
-- @param item_id <number>
-- @param item_name <string>
-- @param amount <number> Can be negative
-- @param is_ep <boolean> If true, EP. If false, GP
-- @param desc <string> Transaction description
-- @param save <boolean> Save the transaction in storage
-- @param announce <boolean> Announce the transaction in guild
function Transact(player_name, item_id, amount, is_ep, desc, save, announce)
	-- Defaults
	if is_ep == nil then
		is_ep = true
	end
	if save == nil then
		save = true
	end
	if announce == nil then
		announce = true
	end

	amount = addon.Util.WholeNumber(amount)

	-- Item info
	local item_name = nil
	local item_link = nil
	if item_id ~= nil then
		item_name, item_link, _, _, _, _, _, _ = _G.GetItemInfo(item_id)
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
		local transaction = {
			["player_name"] = player_name,
			["item_id"] = item_id,
			["item_name"] = item_name,
			["desc"] = desc,
			["ep_change"] = ep_change,
			["gp_change"] = gp_change,
		}
		_G.table.insert(_G.DEPGPStorage.transactions, transaction)
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
		else
		if desc ~= nil and desc then
			msg = msg .. " (" .. desc .. ")"
		end

		addon.Util.ChatGuild(msg)
	end
end
