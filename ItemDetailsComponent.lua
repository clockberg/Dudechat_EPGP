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
	self.item_id = nil
	self.max_num_rows = addon.Util.SizeOf(addon.data.tiers) + 1
	self.max_num_cols = addon.Util.SizeOf(addon.data.specs)
	self.row_height = 18
	self.tier_text_width = 13
	self.price_text_width = 30
	self.icons = {}
	self.tier_texts = {}
	self.price_texts = {}

	self.frame = _G.CreateFrame("Frame", nil, parent)
	self.frame:SetPoint("TOPLEFT", 0, 0)

	for row = 1, self.max_num_rows do
		local y_offset = -1 * ((row - 1) * self.row_height + 2)

		self.tier_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
		self.tier_texts[row]:SetPoint("TOPLEFT", 0, y_offset)
		self.tier_texts[row]:SetSize(self.tier_text_width, self.row_height)
		self.tier_texts[row]:SetJustifyH("CENTER")

		self.price_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
		self.price_texts[row]:SetPoint("TOPLEFT", self.tier_text_width, y_offset)
		self.price_texts[row]:SetSize(self.price_text_width, self.row_height)
		self.price_texts[row]:SetJustifyH("CENTER")

		self.icons[row] = {}
		for col = 1, self.max_num_cols do
			local x_offset = (col - 1) * self.row_height + self.tier_text_width + self.price_text_width

			self.icons[row][col] = self.frame:CreateTexture(nil, "OVERLAY")
			self.icons[row][col]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x_offset, y_offset)
			self.icons[row][col]:SetSize(self.row_height - 1, self.row_height - 1)
		end
	end

	self:Clear()
end

--- Clear the frame
-- Remove all the text and icons from the frame, resize, and hide it
function Component:Clear()
	for row = 1, self.max_num_rows do
		self.tier_texts[row]:SetText(nil)
		self.price_texts[row]:SetText(nil)
	end
	for row = 1, self.max_num_rows do
		for col = 1, self.max_num_cols do
			self.icons[row][col]:SetTexture(nil)
		end
	end
	self:Resize(0, 0)
	self.frame:Hide()
end

--- Resize the frame
-- @param rows <number>
-- @param cols <number>
function Component:Resize(rows, cols)
	self.frame:SetSize(
		self.row_height * cols + self.tier_text_width + self.price_text_width,
		self.row_height * rows
	)
end

--- Update the frame with the given item
-- @param item_id <number>
function Component:UpdateItem(item_id)
	if item_id == self.item_id then
		-- Item matches existing item, don't update
		return
	end

	self:Clear()
	self.item_id = item_id

	local item_data = addon.data.items[item_id]
	if item_data == nil then
		-- Item has no data, don't update
		return
	end

	local num_rows = addon.Util.SizeOf(item_data.by_tier)
	if item_data.price ~= nil then
		num_rows = num_rows + 1
	end

	local num_cols = 0
	for _, tier_data in _G.pairs(item_data.by_tier) do
		num_cols = _G.max(num_cols, addon.Util.SizeOf(tier_data.specs))
	end

	local tiers = addon.Util.TableGetKeys(item_data.by_tier)
	_G.table.sort(tiers)

	local row = 1
	for _, tier in _G.pairs(tiers) do
		tier_data = item_data.by_tier[tier]
		self.tier_texts[row]:SetText(addon.data.tiers[tier])
		self.price_texts[row]:SetText(tier_data.price)
		local specs_as_keys = addon.Util.TableFlip(tier_data.specs)
		local col = 1
		for _, spec in _G.pairs(addon.data.specs) do
			if specs_as_keys[spec] ~= nil then
				self.icons[row][col]:SetTexture(addon.data.spec_textures[spec])
				col = col + 1
			end
		end
		row = row + 1
	end

	if item_data.price ~= nil then
		self.tier_texts[row]:SetText(addon.data.tier_base_name)
		self.price_texts[row]:SetText(item_data.price)
	end

	self:Resize(num_rows, num_cols)
	self.frame:Show()
end
