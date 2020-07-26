local _, addon = ...

local ItemDistWindow = {}
ItemDistWindow.__index = ItemDistWindow
function ItemDistWindow:New()
	local self = {}
	setmetatable(self, ItemDistWindow)
	return self
end

function DEPGP:BuildItemDistWindow()
	local window = ItemDistWindow:New()
	window:Build()
	return window
end

function ItemDistWindow:Toggle()
	if self.panel:IsVisible() then
		PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		self.panel:Hide()
		self:ClearItem(false)
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
		self.panel:Show()
	end
end

function ItemDistWindow:ClearItem(play_sound)
	self.item_id = nil
	self.panel.item:SetTexture(nil)
	self.panel.details:Hide()
	self.panel.actions:Hide()
	if play_sound == nil or play_sound then
		PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
	end
end

function ItemDistWindow:SetItem(item_id)
	self.item_id = item_id
	local _, item_link, _, _, _, _, _, _ = GetItemInfo(item_id);
	self.panel.item:SetTexture(GetItemIcon(item_id))
	local details = self.panel.details
	details.itemname:SetText(item_link)
	details.grade_frame:Update(item_id)
	details:SetHeight(26 + details.grade_frame.frame:GetHeight())
	self.panel:SetHeight(43 + details:GetHeight())
	details:Show()

	local actions = self.panel.actions
	actions:SetPoint("TOPLEFT", 0, -1 * self.panel:GetHeight())
	actions:SetPoint("TOP", 0, -1 * self.panel:GetHeight())
	actions:Show()

	self:AnnounceItem()
end

function ItemDistWindow:AnnounceItem()
	if self.item_id == nil then
		print("noitem")
		return
	end
	local _, item_link, _, _, _, _, _, _ = GetItemInfo(self.item_id);
	SendChatMessage("{SQUARE} Now Distributing: " .. item_link .. "{SQUARE}", "RAID_WARNING")
	local item_data = addon.app.data.items[self.item_id]
	local total = 0
	if item_data ~= nil then
		local grades = table_get_keys(item_data.by_grade)
		table.sort(grades)
		for _, grade in pairs(grades) do
			grade_data = item_data.by_grade[grade]
			local str = " " .. addon.app.grades[grade] .. ": "
			str = str .. " " .. grade_data.price .. "GP - "
			local specs_as_keys = table_flip(grade_data.specs)
			local count = 0
			for i, spec in pairs(addon.app.specs) do
				if specs_as_keys[spec] ~= nil then
					if count > 0 then
						str = str .. ", "
					end
					count = count + 1
					str = str .. addon.app.spec_abbrs[spec]
				end
			end
			SendChatMessage("{SQUARE}" .. str, "RAID")
			total = total + 1
		end
	end
	if total == 0 then
		SendChatMessage("{SQUARE} No prices set", "RAID")
	end
	SendChatMessage("{SQUARE} DM \"need\" to " .. UnitName("player"), "RAID")
end

function ItemDistWindow:DistributeItem()
	print("DistributeItem()")
end

function ItemDistWindow:ToggleMenu()
	local menu = self.panel.menu
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	ToggleDropDownMenu(1, nil, menu, "cursor", 3, -3, nil, nil, 2)
end

function ItemDistWindow:CreateMenu(frame, level, menulist)
	local info

	info = UIDropDownMenu_CreateInfo()
	info.text = "Open Options"
	info.notCheckable = true
	info.func = function ()
		InterfaceOptionsFrame_OpenToCategory(addon.app.interface_options.panel)
		InterfaceOptionsFrame_OpenToCategory(addon.app.interface_options.panel)
	end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.disabled = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	if addon.app.item_dist_window and addon.app.item_dist_window.item_id ~= nil then
		info = UIDropDownMenu_CreateInfo()
		info.text = "Item Options"
		info.notCheckable = true
		info.isTitle = true
		UIDropDownMenu_AddButton(info)

		info = UIDropDownMenu_CreateInfo()
		info.text = "Announce Item"
		info.noClickSound = true
		info.notCheckable = true
		info.func = function ()
			addon.app.item_dist_window:AnnounceItem()
		end
		UIDropDownMenu_AddButton(info)

		info = UIDropDownMenu_CreateInfo()
		info.text = "Clear Item"
		info.noClickSound = true
		info.notCheckable = true
		info.func = function ()
			addon.app.item_dist_window:ClearItem()
		end
		UIDropDownMenu_AddButton(info)

		info = UIDropDownMenu_CreateInfo()
		info.disabled = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
	end

	info = UIDropDownMenu_CreateInfo()
	info.text = "Window Options"
	info.notCheckable = true
	info.isTitle = true
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = "Close Window"
	info.notCheckable = true
	info.func = function ()
		addon.app.item_dist_window:Toggle()
	end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true
	if addon.app:GetOption("item_dist_window.lock") then
		info.text = "Unlock Window"
		info.func = function ()
			addon.app:SetOption("item_dist_window.lock", false)
			addon.app.item_dist_window:Unlock()
		end
	else
		info.text = "Lock Window"
		info.func = function ()
			addon.app:SetOption("item_dist_window.lock", true)
			addon.app.item_dist_window:Lock()
		end
	end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.disabled = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = "Cancel"
	info.notCheckable = true
	info.func = function ()
		-- noop
	end
	UIDropDownMenu_AddButton(info)
end

function ItemDistWindow:Unlock()
	local panel = self.panel
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", function ()
		panel:StartMoving()
	end)
	panel:SetScript("OnDragStop", function ()
		_, _, _, x, y = panel:GetPoint()
		addon.app:SetOption("item_dist_window.x", x)
		addon.app:SetOption("item_dist_window.y", y)
		panel:StopMovingOrSizing()
	end)
end

function ItemDistWindow:Lock()
	local panel = self.panel
	panel:SetMovable(false)
	panel:RegisterForDrag(nil)
end

function ItemDistWindow:Build()
	self.item_id = nil
	local width = 200
	local top_section_height = 43

	self.panel = CreateFrame("Frame")
	local panel = self.panel
	panel:EnableMouse(true)
	if addon.app:GetOption("item_dist_window.lock") then
		self:Lock()
	else
		self:Unlock()
	end
	panel:SetScript("OnMouseUp", function (_, button)
		if button == "LeftButton" then
			local info_type, item_id, item_link = GetCursorInfo()
			if (info_type ~= "item") then
				return
			end
			ClearCursor()
			addon.app.item_dist_window:SetItem(item_id)
		elseif button == "RightButton" then
			addon.app.item_dist_window:ToggleMenu()
		end
	end)
	panel:SetPoint("TOPLEFT", addon.app:GetOption("item_dist_window.x"), addon.app:GetOption("item_dist_window.y"))
	panel:SetPoint("TOP", addon.app:GetOption("item_dist_window.y"))
	panel:SetWidth(width)
	panel:SetHeight(top_section_height)
	-- panel:Hide()

	local bg

	bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetPoint("TOPLEFT", 0, 0)
	bg:SetPoint("TOPRIGHT", 0, 0)
	bg:SetHeight(top_section_height)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 45, -4)
	title:SetPoint("TOPRIGHT", -10, -4)
	title:SetJustifyH("LEFT")
	title:SetText(addon.app.name)
	title:SetHeight(25)

	local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", 45, -16)
	subtitle:SetPoint("TOPRIGHT", -10, -16)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetText("Item Distribution")
	subtitle:SetTextColor(1, 1, 1)
	subtitle:SetHeight(25)

	local slot = panel:CreateTexture(nil, "ARTWORK")
	slot:SetPoint("TOPLEFT", 5, -5)
	slot:SetHeight(55)
	slot:SetWidth(55)
	slot:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	panel.item = panel:CreateTexture(nil, "OVERLAY")
	local item = panel.item
	item:SetPoint("TOPLEFT", 5, -5)
	item:SetHeight(35)
	item:SetWidth(35)
	item:SetTexture(nil)

	panel.menu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
	local menu = panel.menu
	menu:SetPoint("CENTER")
	UIDropDownMenu_Initialize(menu, self.CreateMenu, "MENU")

	panel.details = CreateFrame("Frame", nil, panel)
	local details = panel.details
	details:SetPoint("TOPLEFT", 0, -1 * top_section_height)
	details:SetWidth(width)
	details:Hide()

	bg = details:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.7)
	bg:SetAllPoints(details)

	details.itemname = details:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	local itemname = details.itemname
	itemname:SetPoint("TOPLEFT", 5, 0)
	itemname:SetPoint("TOPRIGHT", -5, 0)
	itemname:SetJustifyH("LEFT")
	itemname:SetHeight(25)

	details.grade_frame = addon.app:BuildGradeFrame(details)
	details.grade_frame.frame:SetPoint("TOPLEFT", 5, -20)

	panel.actions = CreateFrame("Frame", nil, panel)
	local actions = panel.actions
	actions:SetPoint("TOPLEFT", 0, -1 *panel:GetHeight())
	actions:SetWidth(width)
	actions:SetHeight(23)
	--actions:Hide()

	bg = actions:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.7)
	bg:SetAllPoints(actions)

	local btn, btn_text

	actions.btn_clear = CreateFrame("Button", nil, actions, "OptionsButtonTemplate")
	btn = actions.btn_clear
	btn:SetPoint("TOPLEFT", 3, -2)
	btn:SetWidth(45)
	btn:SetHeight(18)
	btn:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:ClearItem()
	end)

	btn_text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	btn_text:SetPoint("TOPLEFT", 5, 0)
	btn_text:SetPoint("TOPRIGHT", -5, 0)
	btn_text:SetJustifyH("CENTER")
	btn_text:SetHeight(18)
	btn_text:SetText("Clear")

	actions.btn_dist = CreateFrame("Button", nil, actions, "OptionsButtonTemplate")
	btn = actions.btn_dist
	btn:SetPoint("TOPRIGHT", -3, -2)
	btn:SetWidth(70)
	btn:SetHeight(18)
	btn:Disable()
	btn:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:DistributeItem()
	end)

	btn_text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	btn_text:SetPoint("TOPLEFT", 5, 0)
	btn_text:SetPoint("TOPRIGHT", -5, 0)
	btn_text:SetJustifyH("CENTER")
	btn_text:SetHeight(18)
	btn_text:SetTextColor(255, 255, 255, 0.5)
	btn_text:SetText("Distribute")
end
