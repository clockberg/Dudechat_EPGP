local _, addon = ...

-- Set up module
local M = {}
addon.ItemTooltip = M
local _G = _G
local dd = function (msg) addon.debug("ItemTooltip." .. msg) end
setfenv(1, M)

-- Module vars
details_frame = nil

--- Load this module
function Load()
	dd("Load")
	details_frame = addon.ItemDetails.NewFrame()
	_G.GameTooltip:HookScript("OnTooltipSetItem", Update)
	_G.ItemRefTooltip:HookScript("OnTooltipSetItem", Update)
end

--- Update the tooltip
-- @param tooltip
function Update(tooltip)
	dd("Update")
	if not addon.Config.GetOption("item_tooltip_mod.show") then
		return
	end
	local item_name = _G.select(1, tooltip:GetItem())
	local item_id = _G.select(1, _G.GetItemInfoInstant(item_name))
	details_frame:UpdateItem(item_id)
	_G.GameTooltip_InsertFrame(tooltip, details_frame.frame)
end
