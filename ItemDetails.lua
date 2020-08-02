local _, addon = ...

-- Set up module
local M = {}
addon.ItemDetails = M
local _G = _G
local dd = function (msg) addon.debug("ItemDetails." .. msg) end
setfenv(1, M)

local ItemDetailsFrame = {}
ItemDetailsFrame.__index = ItemDetailsFrame
function ItemDetailsFrame:New()
	local self = {}
	_G.setmetatable(self, ItemDetailsFrame)
	return self
end

function NewFrame()
	dd("NewFrame")
	local frame = ItemDetailsFrame:New()
	frame:Build()
	return frame
end

function ItemDetailsFrame:Build(parent)
	self.item_id = nil
	self.icon_size = 18
	self.max_num_rows = 6
	self.max_num_cols = 18
	self.tier_text_width = 13
	self.price_text_width = 30
	self.frame = _G.CreateFrame("Frame", nil, parent)
	self.frame:SetPoint("TOPLEFT", 0, 0)
	self:Resize(0, 0)

	self.textures = {}
	self.tier_texts = {}
	self.price_texts = {}
	for row = 1, self.max_num_rows do
		local y_offset = -1 * ((row - 1) * self.icon_size + 2)
		self.textures[row] = {}
		self.tier_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
		self.tier_texts[row]:SetPoint("TOPLEFT", 0, y_offset)
		self.tier_texts[row]:SetSize(self.tier_text_width, self.icon_size)
		self.tier_texts[row]:SetText(nil)
		self.tier_texts[row]:SetJustifyH("CENTER")
		self.price_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
		self.price_texts[row]:SetPoint("TOPLEFT", self.tier_text_width, y_offset)
		self.price_texts[row]:SetSize(self.price_text_width, self.icon_size)
		self.price_texts[row]:SetText(nil)
		self.price_texts[row]:SetJustifyH("CENTER")
		local text_width = self.tier_text_width + self.price_text_width
		for col = 1, self.max_num_cols do
			local x_offset = (col - 1) * self.icon_size + text_width
			self.textures[row][col] = self.frame:CreateTexture(nil, "OVERLAY")
			self.textures[row][col]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x_offset, y_offset)
			self.textures[row][col]:SetSize(self.icon_size - 1, self.icon_size - 1)
		end
	end
end

function ItemDetailsFrame:Clear()
	for row = 1, self.max_num_rows do
		self.tier_texts[row]:SetText(nil)
		self.price_texts[row]:SetText(nil)
	end
	for row = 1, self.max_num_rows do
		for col = 1, self.max_num_cols do
			self.textures[row][col]:SetTexture(nil)
		end
	end
	self:Resize(0, 0)
end

function ItemDetailsFrame:Resize(rows, cols)
	self.frame:SetSize(self.icon_size * cols + self.tier_text_width + self.price_text_width, self.icon_size * rows)
end

function ItemDetailsFrame:UpdateItem(item_id)
	if item_id == self.item_id then
		return
	end
	self.item_id = item_id

	self:Clear()

	local item_data = addon.data.items[item_id]
	if item_data == nil then
		self.frame:Hide()
		return
	end

	self.frame:Show()

	local num_rows = addon.Util.SizeOf(item_data.by_tier)
	if item_data.price ~= nil then
		num_rows = num_rows + 1
	end
	local num_cols = 0
	for tier, tier_data in _G.pairs(item_data.by_tier) do
		num_cols = _G.max(num_cols, addon.Util.SizeOf(tier_data.specs))
	end
	self:Resize(num_rows, num_cols)

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
				self.textures[row][col]:SetTexture(addon.data.spec_textures[spec])
				col = col + 1
			end
		end
		row = row + 1
	end

	if item_data.price ~= nil then
		self.tier_texts[row]:SetText("*")
		self.price_texts[row]:SetText(item_data.price)
	end
end
