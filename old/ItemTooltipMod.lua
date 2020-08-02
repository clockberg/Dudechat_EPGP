local _, addon = ...

-- Create ItemTooltipMod class
local ItemTooltipMod = {}
ItemTooltipMod.__index = ItemTooltipMod
function ItemTooltipMod:New()
	local self = {}
	setmetatable(self, ItemTooltipMod)
	return self
end

--- App function to build this class
-- @return <ItemTooltipMod>
function DEPGP:BuildItemTooltipMod()
	local item_tooltip_mod = ItemTooltipMod:New()
	item_tooltip_mod:Build()
	GameTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		if addon.app:GetOption("item_tooltip_mod.show") then
			local item_name = select(1, tooltip:GetItem())
			local item_id = select(1, GetItemInfoInstant(item_name))
			item_tooltip_mod.grade_frame:UpdateItem(item_id)
			GameTooltip_InsertFrame(tooltip, item_tooltip_mod.grade_frame.frame)
		end
	end)
	ItemRefTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		if addon.app:GetOption("item_tooltip_mod.show") then
			local item_name = select(1, tooltip:GetItem())
			local item_id = select(1, GetItemInfoInstant(item_name))
			item_tooltip_mod.grade_frame:UpdateItem(item_id)
			GameTooltip_InsertFrame(tooltip, item_tooltip_mod.grade_frame.frame)
		end
	end)
	return item_tooltip_mod
end

function ItemTooltipMod:Build(parent)
	self.grade_frame = addon.app:BuildGradeFrame(UIParent)
end
