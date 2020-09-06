local _, addon = ...

-- Module setup
local M = {}
addon.Options = M
local _G = _G
setfenv(1, M)

-- Module vars
panel = nil
checkboxes = {}
editboxes = {}

settings = {
	["padding"] = 10,
	["col_width"] = 200,
	["row_height"] = 35,
	["title_height"] = 20,
	["cellspacing"] = 5,
}

--- Interface options on refresh
-- Called when the frame is initially displayed, and after
-- requesting the default values to be restored
function OnRefresh()
	--
end

--- Interface options on okay
-- Called when the player presses the Okay button, indicating
-- that settings should be saved
function OnOkay()
	addon.Config.CommitTmpOptions()
	Sync()
end

--- Interface options on cancel
-- Called when the player presses the Cancel button, indicating
-- that changes made should be discarded
function OnCancel()
	addon.Config:ResetTmpOptions()
	Sync()
end

--- Interface options on default
-- Called when the player presses the Defaults button, indicating
-- that default settings for the addon should be restored
function OnDefault()
	addon.Config:SetOptionsToDefaults()
	Sync()
end

--- Load this module
function Load()
	panel = _G.CreateFrame("Frame")
	panel.name = addon.short_name
	panel:SetPoint("TOPLEFT", 0, 0)
	panel:SetPoint("BOTTOMRIGHT", 0, 0)
	panel:Hide()

	panel.refresh = OnRefresh
	panel.okay = OnOkay
	panel.cancel = OnCancel
	panel.default = OnDefault

	local title = panel:CreateFontString(nil, nil, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", settings.padding, -1 * settings.padding)
	title:SetPoint("TOPRIGHT", -1 * settings.padding, -1 * settings.padding)
	title:SetJustifyH("LEFT")
	title:SetText(addon.full_name)

	AddCheckbox("ItemTooltip.show", 1, 1, "Item Tooltip", "Show prices and tiers on tooltip.")
	AddCheckbox("ItemDistribute.announce_raid_warning", 2, 1, "Item Raid Warning", "Send a raid warning when announcing an item.", 2)
	AddEditbox("ItemDistribute.default_price", 1, 2, "Item Default Price", "The default price for items in the custom GP editbox.", 2)

	Sync()

	_G.InterfaceOptions_AddCategory(panel)
end

--- Returns the X position of the column
-- @param col <number>
-- @return <number>
function ColGetX(col)
	return settings.padding + (col - 1) * settings.col_width
end

--- Returns the Y position of the row (will be negative)
-- @param row <number>
-- @return <number>
function RowGetY(row)
	return -1 * (settings.padding + settings.title_height + settings.row_height * (row - 1))
end

--- Sync the frame elements with the config options
function Sync()
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
-- @param col <number>
-- @param row <number>
-- @param label_text <string>
-- @param desc_text <string>
-- @param colspan <number>
function AddCheckbox(option_key, col, row, label_text, desc_text, colspan)
	desc_text = desc_text or nil
	colspan = colspan or 1

	x = ColGetX(col)
	y = RowGetY(row)

	local frame = _G.CreateFrame("Frame", nil, panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(settings.col_width * colspan - settings.cellspacing)
	frame:SetHeight(settings.row_height - settings.cellspacing)

	local bg = frame:CreateTexture(nil)
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)

	local checkbox = _G.CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("BOTTOMLEFT", 3, 3)
	checkbox.option_key = option_key
	checkbox:SetScript("OnClick", function ()
		addon.Config.SetTmpOption(checkbox.option_key, checkbox:GetChecked())
	end)

	local label = frame:CreateFontString(nil, nil, "GameFontNormal")
	label:SetText(label_text)

	if desc_text ~= nil then
		-- Label above desc
		label:SetPoint("BOTTOMLEFT", 29, 15)

		local desc = frame:CreateFontString(nil, nil, "GameFontNormalSmall")
		desc:SetPoint("BOTTOMLEFT", 29, 5)
		desc:SetTextColor(1, 1, 1)
		desc:SetText(desc_text)
	else
		-- Label only
		label:SetPoint("BOTTOMLEFT", 29, 9)
	end

	checkboxes[option_key] = checkbox
end

--- Add an editbox to the options panel
-- @param option_key <string>
-- @param col <number>
-- @param row <number>
-- @param label_text <string>
-- @param desc_text <string>
-- @param colspan <number>
function AddEditbox(option_key, col, row, label_text, desc_text, colspan)
	desc_text = desc_text or nil
	colspan = colspan or 2

	x = ColGetX(col)
	y = RowGetY(row)

	local frame = _G.CreateFrame("Frame", nil, panel)
	frame:SetPoint("TOPLEFT", x, y)
	frame:SetWidth(settings.col_width * colspan - settings.cellspacing)
	frame:SetHeight(settings.row_height - settings.cellspacing)

	local bg = frame:CreateTexture(nil)
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)

	local editbox = _G.CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetPoint("BOTTOMLEFT", 10, 3)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(5)
	editbox:SetHeight(24)
	editbox:SetWidth(55)
	editbox:SetScript("OnEscapePressed", function()
		editbox:ClearFocus()
	end)
	editbox.option_key = option_key
	editbox:SetScript("OnTextChanged", function()
		local val = editbox:GetText()
		val = addon.Util.AddonNumber(val)
		addon.Config.SetTmpOption(editbox.option_key, val)
	end)

	local label = frame:CreateFontString(nil, nil, "GameFontNormal")
	label:SetText(label_text)
	if desc_text ~= nil then
		-- Label above desc
		label:SetPoint("BOTTOMLEFT", 69, 15)

		-- Desc
		local desc = frame:CreateFontString(nil, nil, "GameFontNormalSmall")
		desc:SetTextColor(1, 1, 1)
		desc:SetText(desc_text)
		desc:SetPoint("BOTTOMLEFT", 69, 5)
	else
		-- Label only
		label:SetPoint("BOTTOMLEFT", 69, 9)
	end

	editboxes[option_key] = editbox
end
