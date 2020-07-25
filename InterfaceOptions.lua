local _, addon = ...

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
	interface_options:AddCheckbox("flag", 10, -35, "Label", "This is a description.")
	interface_options:AddCheckbox("flag2", 10, -70, "Label2")
	interface_options:AddCheckbox("flag3", 210, -70, "Label3")
	interface_options:AddCheckbox("flag4", 410, -70, "Label4")
	interface_options:AddEditbox("foo.bar", 10, -105, "Label5", "This is a description.")
	interface_options:AddEditbox("foo.foo", 210, -105, "Labely 6")
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
	self.panel.name = "Dudechat EPGP"
	self.panel:SetPoint("TOPLEFT", 0, 0)
	self.panel:SetPoint("BOTTOMRIGHT", 0, 0)
	self.panel:Hide()

	self.panel.refresh = function () self:OnRefresh() end
	self.panel.okay = function () self:OnOkay() end
	self.panel.cancel = function () self:OnCancel() end
	self.panel.default = function () self:OnDefault() end

	self.checkboxes = {}
	self.editboxes = {}

	self.pad = 10

	local fs_title = self.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	fs_title:SetPoint("TOPLEFT", 10, -10)
	fs_title:SetPoint("TOPRIGHT", -10, -10)
	fs_title:SetJustifyH("LEFT")
	fs_title:SetText("Dudechat EPGP")
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

function InterfaceOptions:AddCheckbox(option_key, x, y, label, desc)
	desc = desc or nil

	local frame = CreateFrame("Frame", nil, self.panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(190)
	frame:SetHeight(30)

	local bg = self.panel:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)
	bg:Show()

	local checkbox = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("BOTTOMLEFT", 3, 2)
	checkbox:SetScript("OnClick", function ()
		addon.app:SetTmpOption(option_key, checkbox:GetChecked())
	end)

	-- Label
	local fs_label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs_label:SetText(label)

	-- Desc
	if desc ~= nil then
		-- Label above desc
		fs_label:SetPoint("BOTTOMLEFT", 30, 14)

		local fs_desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs_desc:SetPoint("BOTTOMLEFT", 30, 4)
		fs_desc:SetTextColor(1, 1, 1)
		fs_desc:SetText(desc)
	else
		-- Label only
		fs_label:SetPoint("BOTTOMLEFT", 30, 8)
	end

	self.checkboxes[option_key] = checkbox
end

function InterfaceOptions:AddEditbox(option_key, x, y, label, desc)
	desc = desc or nil

	local frame = CreateFrame("Frame", nil, self.panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(190)
	if desc ~= nil then
		frame:SetHeight(57)
	else
		frame:SetHeight(45)
	end

	local bg = self.panel:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)
	bg:Show()

	local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetPoint("BOTTOMLEFT", 12, 5)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(5)
	editbox:SetHeight(24)
	editbox:SetWidth(60)
	editbox:SetScript("OnEscapePressed", function()
		editbox:ClearFocus()
	end)

	-- Label
	local fs_label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs_label:SetText(label)

	-- Desc
	if desc ~= nil then
		-- Label above desc above editbox
		fs_label:SetPoint("BOTTOMLEFT", 7, 39)

		local fs_desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs_desc:SetPoint("BOTTOMLEFT", 7, 27)
		fs_desc:SetTextColor(1, 1, 1)
		fs_desc:SetText(desc)
	else
		-- Label only above editbox
		fs_label:SetPoint("BOTTOMLEFT", 7, 27)
	end

	self.editboxes[option_key] = editbox
end

-- local texture = self.panel:CreateTexture(nil, "BACKGROUND")
-- texture:SetColorTexture(1, 0, 0)
-- texture:SetAllPoints(checkbox)
-- texture:Show()
