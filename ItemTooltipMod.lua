local _, addon = ...

local ItemTooltipMod = {}
ItemTooltipMod.__index = ItemTooltipMod
function ItemTooltipMod:New()
	local self = {}
	setmetatable(self, ItemTooltipMod)
	return self
end

function DEPGP:BuildItemTooltipMod()
	local item_tooltip_mod = ItemTooltipMod:New()
	item_tooltip_mod:Build()
	GameTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		item_tooltip_mod:Update(tooltip)
	end)
	ItemRefTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		item_tooltip_mod:Update(tooltip)
	end)
	return item_tooltip_mod
end

function ItemTooltipMod:Build()
	self.item_id = nil
	self.icon_size = 18
	self.max_num_rows = 5
	self.max_num_cols = 18
	self.grade_text_width = 13
	self.price_text_width = 30
	self.frame = CreateFrame("Frame")
	self.frame:SetPoint("TOPLEFT", 0, 0)
	self:Resize(0, 0)

	self.textures = {}
	self.grade_texts = {}
	self.price_texts = {}
	for row = 1, self.max_num_rows do
		local y_offset = -1 * ((row - 1) * self.icon_size + 2)
		self.textures[row] = {}
		self.grade_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameTooltipText")
		self.grade_texts[row]:SetPoint("TOPLEFT", 0, y_offset)
		self.grade_texts[row]:SetSize(self.grade_text_width, self.icon_size)
		self.grade_texts[row]:SetText(nil)
		self.grade_texts[row]:SetJustifyH("CENTER")
		self.price_texts[row] = self.frame:CreateFontString(self.frame, "OVERLAY", "GameTooltipText")
		self.price_texts[row]:SetPoint("TOPLEFT", self.grade_text_width, y_offset)
		self.price_texts[row]:SetSize(self.price_text_width, self.icon_size)
		self.price_texts[row]:SetText(nil)
		self.price_texts[row]:SetJustifyH("CENTER")
		local text_width = self.grade_text_width + self.price_text_width
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
		self.grade_texts[row]:SetText(nil)
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
	self.frame:SetSize(self.icon_size * cols + self.grade_text_width + self.price_text_width, self.icon_size * rows)
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

	local num_rows = sizeof(item_data.by_grade)
	local num_cols = 0
	for grade, grade_data in pairs(item_data.by_grade) do
		num_cols = max(num_cols, #grade_data.specs)
	end
	self:Resize(num_rows, num_cols)

	local grades = table_get_keys(item_data.by_grade)
	table.sort(grades)

	local row = 1
	for _, grade in pairs(grades) do
		grade_data = item_data.by_grade[grade]
		self.grade_texts[row]:SetText(addon.app.grades[grade])
		self.price_texts[row]:SetText(grade_data.price)
		local specs_as_keys = table_flip(grade_data.specs)
		local col = 1
		for _, spec in pairs(addon.app.specs) do
			if specs_as_keys[spec] ~= nil then
				self.textures[row][col]:SetTexture(addon.app.spec_textures[spec])
				col = col + 1
			end
		end
		row = row + 1
	end

	GameTooltip_InsertFrame(tooltip, self.frame)
end
