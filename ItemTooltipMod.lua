local _, addon = ...

local ItemTooltipMod = {}
ItemTooltipMod.__index = ItemTooltipMod
function ItemTooltipMod:New()
	local self = {}
	setmetatable(self, ItemTooltipMod)
	return self
end

function DEPGP:InitItemTooltipMod()
	self.item_tooltip_mod = ItemTooltipMod:New()
	self.item_tooltip_mod:Init()
	GameTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		self.item_tooltip_mod:Update(tooltip)
	end)
	ItemRefTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		self.item_tooltip_mod:Update(tooltip)
	end)
end

function ItemTooltipMod:Init()
	self.item_id = nil
	self.icon_size = 20
	self.max_num_rows = 5
	self.max_num_cols = 14
	self.tier_text_width = 15
	self.price_text_width = 25
	self.frame = CreateFrame("Frame")
	self.frame:SetPoint("TOPLEFT", 0, 0)
	self:Resize(0, 0)

	self.textures = {}
	self.tier_texts = {}
	self.price_texts = {}
	for row = 1, self.max_num_rows do
		local y_offset = -1 * ((row - 1) * self.icon_size)
		self.textures[row] = {}
		self.tier_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameTooltipText")
		self.tier_texts[row]:SetPoint("TOPLEFT", 0, y_offset)
		self.tier_texts[row]:SetSize(self.tier_text_width, self.icon_size)
		self.tier_texts[row]:SetText(nil)
		self.tier_texts[row]:SetJustifyH("CENTER")
		self.price_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameTooltipText")
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

function ItemTooltipMod:Clear()
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

function ItemTooltipMod:Resize(rows, cols)
	self.frame:SetSize(self.icon_size * cols + self.tier_text_width + self.price_text_width, self.icon_size * rows)
end

function ItemTooltipMod:Update(tooltip)
	local item_name = select(1, tooltip:GetItem())
	local item_id = select(1, GetItemInfoInstant(item_name))
	if item_id == self.item_id then
		GameTooltip_InsertFrame(tooltip, self.frame)
		return
	end
	self.item_id = item_id

	self:Clear()

	local item_data = addon.app.data.items[item_id]
	if item_data == nil then
		self.frame:Hide()
		return
	end

	self.frame:Show()

	local num_rows = sizeof(item_data.by_tier)
	local num_cols = 0
	for tier, tier_data in pairs(item_data.by_tier) do
		num_cols = max(num_cols, #tier_data.roles)
	end
	self:Resize(num_rows, num_cols)

	local tiers = table_get_keys(item_data.by_tier)
	table.sort(tiers)

	local row = 1
	for _, tier in pairs(tiers) do
		tier_data = item_data.by_tier[tier]
		self.tier_texts[row]:SetText(addon.app.tier_map[tier])
		self.price_texts[row]:SetText(tier_data.price)
		table.sort(tier_data.roles)
		for col, role in pairs(tier_data.roles) do
			self.textures[row][col]:SetTexture(addon.app.role_textures[role])
		end
		row = row + 1
	end

	GameTooltip_InsertFrame(tooltip, self.frame)
end
