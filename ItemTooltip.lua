local _, addon = ...

-- Set up module
local M = {}
addon.ItemTooltip = M
local _G = _G
setfenv(1, M)

-- Module vars
item_details_component = nil

--- Load this module
function Load()
	item_details_component = addon.ItemDetailsComponent.Create()
	_G.GameTooltip:HookScript("OnTooltipSetItem", Update)
	_G.ItemRefTooltip:HookScript("OnTooltipSetItem", Update)
end

--- Update the tooltip
-- @param tooltip
function Update(tooltip)
	if not addon.Config.GetOption("ItemTooltip.show") then
		return
	end
	local item_name = _G.select(1, tooltip:GetItem())
	if item_name then
		local item_id = _G.select(1, _G.GetItemInfoInstant(item_name))
		item_details_component:UpdateItem(item_id)
		_G.GameTooltip_InsertFrame(tooltip, item_details_component.frame)
	else
		item_details_component:UpdateItem(nil)
	end
end
