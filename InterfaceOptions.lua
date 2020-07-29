local _, addon = ...

-- Create InterfaceOptions class
local InterfaceOptions = {}
InterfaceOptions.__index = InterfaceOptions
function InterfaceOptions:New()
	local self = {}
	setmetatable(self, InterfaceOptions)
	return self
end

function DEPGP:BuildInterfaceOptions()
	local interface_options = InterfaceOptions:New()
	interface_options:Build()
	interface_options:AddCheckbox("item_tooltip_mod.show", 10, -35, "Item Tooltip", "Show grades on tooltip.")
	-- interface_options:AddCheckbox("flag2", 10, -70, "Label2")
	-- interface_options:AddCheckbox("flag3", 210, -70, "Label3")
	-- interface_options:AddCheckbox("flag4", 410, -70, "Label4")
	-- interface_options:AddEditbox("foo.bar", 10, -105, "Label5", "This is a description.")
	-- interface_options:AddEditbox("foo.foo", 210, -105, "Labely 6")
	interface_options:Sync()
	interface_options:Connect()
	return interface_options
end

-- called when the frame is initially displayed, and after requesting the default values to be restored
function InterfaceOptions:OnRefresh()
	-- noop
end

-- called when the player presses the Okay button, indicating that settings should be saved
function InterfaceOptions:OnOkay()
	addon.app:CommitTmpOptions()
	self:Sync()
end

-- called when the player presses the Cancel button, indicating that changes made should be discarded
function InterfaceOptions:OnCancel()
	addon.app:DiscardTmpOptions()
	self:Sync()
end

-- called when the player presses the Defaults button, indicating that default settings for the addon should be restored
function InterfaceOptions:OnDefault()
	addon.app:SetOptionsToDefaults()
	self:Sync()
end

function InterfaceOptions:Build()
	self.panel = CreateFrame("Frame")
	self.panel.name = addon.app.name_long
	self.panel:SetPoint("TOPLEFT", 0, 0)
	self.panel:SetPoint("BOTTOMRIGHT", 0, 0)
	self.panel:Hide()

	self.panel.refresh = function () self:OnRefresh() end
	self.panel.okay = function () self:OnOkay() end
	self.panel.cancel = function () self:OnCancel() end
	self.panel.default = function () self:OnDefault() end

	self.checkboxes = {}
	self.editboxes = {}

	local fs_title = self.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	fs_title:SetPoint("TOPLEFT", 10, -10)
	fs_title:SetPoint("TOPRIGHT", -10, -10)
	fs_title:SetJustifyH("LEFT")
	fs_title:SetText(addon.app.name_long)
	fs_title:SetHeight(fs_title:GetStringHeight())
end

function InterfaceOptions:Sync()
	for option_key, checkbox in pairs(self.checkboxes) do
		checkbox:SetChecked(addon.app:GetOption(option_key))
	end
	for option_key, editbox in pairs(self.editboxes) do
		editbox:SetText("")
		editbox:Insert(tostring(addon.app:GetOption(option_key)))
	end
end

function InterfaceOptions:Connect()
	InterfaceOptions_AddCategory(self.panel)
end

function InterfaceOptions:AddCheckbox(option_key, x, y, label_text, desc_text)
	desc_text = desc_text or nil

	local frame = CreateFrame("Frame", nil, self.panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(190)
	frame:SetHeight(31)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)

	local checkbox = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("BOTTOMLEFT", 3, 3)
	checkbox:SetScript("OnClick", function ()
		addon.app:SetTmpOption(option_key, checkbox:GetChecked())
	end)

	-- Label
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(label_text)

	-- Desc
	if desc_text ~= nil then
		-- Label above desc
		label:SetPoint("BOTTOMLEFT", 30, 15)

		local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		desc:SetPoint("BOTTOMLEFT", 30, 5)
		desc:SetTextColor(1, 1, 1)
		desc:SetText(desc_text)
	else
		-- Label only
		label:SetPoint("BOTTOMLEFT", 30, 8)
	end

	self.checkboxes[option_key] = checkbox
end

function InterfaceOptions:AddEditbox(option_key, x, y, label_text, desc_text)
	desc_text = desc_text or nil

	local frame = CreateFrame("Frame", nil, self.panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(190)
	if desc_text ~= nil then
		frame:SetHeight(57)
	else
		frame:SetHeight(45)
	end

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)

	local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetPoint("BOTTOMLEFT", 12, 5)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(5)
	editbox:SetHeight(24)
	editbox:SetWidth(60)
	editbox:SetScript("OnEscapePressed", function()
		editbox:ClearFocus()
	end)
	editbox:SetScript("OnTextChanged", function()
		print("textchanged")
		addon.app:SetTmpOption(option_key, editbox:GetText())
	end)

	-- Label
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(label_text)

	-- Desc
	if desc_text ~= nil then
		-- Label above desc above editbox
		label:SetPoint("BOTTOMLEFT", 7, 39)

		local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		desc:SetPoint("BOTTOMLEFT", 7, 27)
		desc:SetTextColor(1, 1, 1)
		desc:SetText(desc_text)
	else
		-- Label only above editbox
		label:SetPoint("BOTTOMLEFT", 7, 27)
	end

	self.editboxes[option_key] = editbox
end
