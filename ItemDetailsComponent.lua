local _, addon = ...

-- Module setup
local M = {}
addon.ItemDetailsComponent = M
local _G = _G
setfenv(1, M)

-- Create class
local Component = {}
Component.__index = Component
function Component:New()
	local self = {}
	_G.setmetatable(self, Component)
	return self
end

-- Settings
icon_size = 14
tier_text_width = 20
price_text_width = 35
text_pad_right = 10

--- Create, build, and return a new Component
-- @param parent <Frame>
-- @return <Component>
function Create(parent)
	local frame = Component:New()
	frame:Build(parent)
	return frame
end

--- Build the frame
-- @param parent <Frame>
function Component:Build(parent)
	self.max_num_rows = addon.Util.SizeOf(addon.data.tiers) + 1
	self.max_num_cols = addon.Util.SizeOf(addon.data.specs)
	self.item_id = nil
	self.lines = {}
	self.frame = _G.CreateFrame("Frame", nil, parent)
	self.frame:SetPoint("TOPLEFT", 0, 0)
	self.frame:SetHeight(icon_size * self.max_num_rows)
	self.frame:SetWidth(tier_text_width + price_text_width + self.max_num_cols * icon_size)

	for row = 1, self.max_num_rows do
		local y_offset = -1 * ((row - 1) * icon_size + 2)

		-- Create the line
		self.lines[row] = _G.CreateFrame("Frame", nil, self.frame)
		line = self.lines[row]
		line:SetPoint("TOPLEFT", 0, y_offset)
		line:SetSize(
			icon_size * self.max_num_cols + tier_text_width + price_text_width + text_pad_right,
			icon_size
		)

		-- Create the tier text
		line.tier_text = line:CreateFontString(nil, nil, "GameFontNormal")
		line.tier_text:SetPoint("TOPLEFT", 0, 0)
		line.tier_text:SetSize(tier_text_width, icon_size)
		line.tier_text:SetJustifyH("CENTER")
		line.tier_text:SetJustifyV("CENTER")

		-- Create the price text
		line.price_text = line:CreateFontString(nil, nil, "GameFontNormal")
		line.price_text:SetPoint("TOPLEFT", tier_text_width, 0)
		line.price_text:SetSize(price_text_width, icon_size)
		line.price_text:SetJustifyH("RIGHT")
		line.price_text:SetJustifyV("CENTER")

		-- Create the icons
		line.icons = {}
		for col = 1, self.max_num_cols do
			local x_offset = (col - 1) * icon_size + tier_text_width + price_text_width + text_pad_right
			line.icons[col] = line:CreateTexture(nil)
			line.icons[col]:SetPoint("TOPLEFT", x_offset, 0)
			line.icons[col]:SetSize(icon_size, icon_size)
		end
	end

	self:Clear()
end

--- Clear the frame
-- Remove all the text and icons from the frame, resize, and hide it
function Component:Clear()
	for row = 1, self.max_num_rows do
		self.lines[row].tier_text:SetText(nil)
		self.lines[row].price_text:SetText(nil)
		for col = 1, self.max_num_cols do
			self.lines[row].icons[col]:SetTexture(nil)
		end
		self.lines[row]:Hide()
	end
	self:Resize(0, 0)
	self.frame:Hide()
end

--- Resize the frame
-- @param rows <number>
-- @param cols <number>
function Component:Resize(rows, cols)
	self.frame:SetSize(
		icon_size * cols + tier_text_width + price_text_width + text_pad_right,
		icon_size * rows
	)
end

--- Returns true if the component has an item, false otherwise
-- @return <boolean>
function Component:HasItem()
	if self.item_id then
		return true
	end
	return false
end

--- Update the frame with the given item
-- @param item_id <number>
-- @return <boolean>
function Component:UpdateItem(item_id)
	if item_id == self.item_id then
		-- Item matches existing item, don't update
		if item_id then
			return true
		end
		return false
	end

	self:Clear()
	self.item_id = item_id

	local item_data = addon.Core.GetItemData(item_id)
	if item_data == nil then
		-- Item has no data, don't update
		return false
	end

	local num_rows = addon.Util.SizeOf(item_data.by_tier)
	if item_data.price ~= nil then
		num_rows = num_rows + 1
	end

	local num_cols = 0
	for _, tier_data in _G.pairs(item_data.by_tier) do
		num_cols = _G.max(num_cols, addon.Util.SizeOf(tier_data.specs))
	end

	local tiernums = {}
	if item_data.by_tier then
		tiernums = addon.Util.TableGetKeys(item_data.by_tier)
		_G.table.sort(tiernums)
	end

	local row = 1
	for _, tiernum in _G.pairs(tiernums) do
		tier_data = item_data.by_tier[tiernum]
		self.lines[row].tier_text:SetText(addon.data.tiers[tiernum])
		self.lines[row].price_text:SetText(tier_data.price)
		self.lines[row]:Show()
		local specs_as_keys = addon.Util.TableFlip(tier_data.specs)
		local col = 1
		for _, spec in _G.pairs(addon.data.specs) do
			if specs_as_keys[spec] ~= nil then
				self.lines[row].icons[col]:SetTexture(addon.data.spec_textures[spec])
				col = col + 1
			end
		end
		row = row + 1
	end

	if item_data.price ~= nil then
		self.lines[row].tier_text:SetText(addon.data.tier_base_name)
		self.lines[row].price_text:SetText(item_data.price)
		self.lines[row]:Show()
	end

	self:Resize(num_rows, num_cols)
	self.frame:Show()
end
