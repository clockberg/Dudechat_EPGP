local _, addon = ...

-- Set up module
local M = {}
addon.Options = M
local _G = _G
local dd = function (msg) addon.debug("Options." .. msg) end
setfenv(1, M)

panel = nil
checkboxes = {}
editboxes = {}

-- called when the frame is initially displayed, and after requesting the default values to be restored
function OnRefresh()
	dd("OnRefresh")
end

-- called when the player presses the Okay button, indicating that settings should be saved
function OnOkay()
	dd("OnOkay")
	addon.Config.CommitTmpOptions()
	Sync()
end

-- called when the player presses the Cancel button, indicating that changes made should be discarded
function OnCancel()
	dd("OnCancel")
	addon.Config:ResetTmpOptions()
	Sync()
end

-- called when the player presses the Defaults button, indicating that default settings for the addon should be restored
function OnDefault()
	dd("OnDefault")
	addon.Config:SetOptionsToDefaults()
	Sync()
end

function Load()
	dd("Load")
	panel = _G.CreateFrame("Frame")
	panel.name = addon.short_name
	panel:SetPoint("TOPLEFT", 0, 0)
	panel:SetPoint("BOTTOMRIGHT", 0, 0)
	panel:Hide()

	panel.refresh = OnRefresh
	panel.okay = OnOkay
	panel.cancel = OnCancel
	panel.default = OnDefault

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetPoint("TOPRIGHT", -10, -10)
	title:SetJustifyH("LEFT")
	title:SetText(addon.full_name)

	AddCheckbox("item_tooltip_mod.show", 10, -35, "Item Tooltip", "Show grades on tooltip.")
	AddCheckbox("flag2", 10, -70, "Label2", "checkbox with a desc")
	AddCheckbox("flag3", 210, -70, "Label3")
	AddCheckbox("flag4", 410, -70, "Label4")
	AddEditbox("foo.bar", 10, -105, "Label5", "This is a description.")
	AddEditbox("foo.foo", 210, -105, "Labely 6")

	Sync()

	_G.InterfaceOptions_AddCategory(panel)
end

function Sync()
	dd("Sync")
	for option_key, checkbox in _G.pairs(checkboxes) do
		checkbox:SetChecked(addon.Config.GetOption(option_key))
	end
	for option_key, editbox in _G.pairs(editboxes) do
		editbox:SetText("")
		editbox:Insert(_G.tostring(addon.Config.GetOption(option_key)))
	end
end

--- Add a checkbox to the options panel
-- @param option_key <string>
-- @param x <number>
-- @param y <number>
-- @param label_text <string>
-- @param desc_text <string>
function AddCheckbox(option_key, x, y, label_text, desc_text)
	dd("AddCheckbox")
	desc_text = desc_text or nil

	local frame = _G.CreateFrame("Frame", nil, panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(190)
	frame:SetHeight(31)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)

	local checkbox = _G.CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("BOTTOMLEFT", 3, 3)
	checkbox.option_key = option_key
	checkbox:SetScript("OnClick", function ()
		addon.Config.SetTmpOption(checkbox.option_key, checkbox:GetChecked())
	end)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(label_text)

	if desc_text ~= nil then
		-- Label above desc
		label:SetPoint("BOTTOMLEFT", 30, 15)

		local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		desc:SetPoint("BOTTOMLEFT", 30, 5)
		desc:SetTextColor(1, 1, 1)
		desc:SetText(desc_text)
	else
		-- Label only
		label:SetPoint("BOTTOMLEFT", 30, 9)
	end

	checkboxes[option_key] = checkbox
end

--- Add an editbox to the options panel
-- @param option_key <string>
-- @param x <number>
-- @param y <number>
-- @param label_text <string>
-- @param desc_text <string>
function AddEditbox(option_key, x, y, label_text, desc_text)
	dd("AddEditbox")
	desc_text = desc_text or nil

	local frame = _G.CreateFrame("Frame", nil, panel)
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

	local editbox = _G.CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetPoint("BOTTOMLEFT", 12, 5)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(5)
	editbox:SetHeight(24)
	editbox:SetWidth(60)
	editbox:SetScript("OnEscapePressed", function()
		editbox:ClearFocus()
	end)
	editbox.option_key = option_key
	editbox:SetScript("OnTextChanged", function()
		addon.Config.SetTmpOption(editbox.option_key, editbox:GetText())
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

	editboxes[option_key] = editbox
end
