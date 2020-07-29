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
	self.player_index = 1
	self.selected_gp = 0
	self:ClearPlayerSelection()
	for i = 1, sizeof(self.player_frames) do
		self.player_frames[i]:Hide()
	end
	self.sections.top.item_texture:SetTexture(nil)
	self.sections.top.title:SetText(addon.app.name)
	self.sections.details:Hide()
	self.sections.players:Hide()
	self.sections.actions:Hide()
	self.sections.transaction:Hide()
	self:DisableDistributeButton()
	self.panel:SetHeight(self.top_section_height)
	if play_sound == nil or play_sound then
		PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
	end
end

function ItemDistWindow:ClearPlayerSelection()
	self.selected_player = nil
	self.selected_gp = 0
	for i = 1, sizeof(self.player_frames) do
		self.player_frames[i].hili_sel:Hide()
	end
end

function ItemDistWindow:SetItem(item_id)
	self:ClearItem(false)
	self.item_id = item_id
	local _, item_link, _, _, _, _, _, _ = GetItemInfo(item_id);
	self.sections.top.item_texture:SetTexture(GetItemIcon(item_id))
	self.sections.top.title:SetText(item_link)
	self:LoadGPOptions()

	local details = self.sections.details
	details.grade_frame:Update(item_id)
	local dh = details.grade_frame.frame:GetHeight()
	details:SetHeight(dh)
	if dh > 0 then
		details:Show()
	end

	local players = self.sections.players
	local y = self.top_section_height + details:GetHeight()
	players:ClearAllPoints()
	players:SetPoint("TOPLEFT", 0, -1 * y)
	players:SetHeight(self.player_height)
	players:Show()

	local transaction = self.sections.transaction
	transaction:ClearAllPoints()
	transaction:SetPoint("TOPLEFT", 0, -1 * y)

	local actions = self.sections.actions
	y = self.top_section_height + details:GetHeight() + players:GetHeight()
	actions:ClearAllPoints()
	actions:SetPoint("TOPLEFT", 0, -1 * y)
	actions:Show()

	local h = max(self.min_transaction_height, players:GetHeight() + actions:GetHeight())
	transaction:SetHeight(h)

	y = self.top_section_height + details:GetHeight() + players:GetHeight() + actions:GetHeight()
	self.panel:SetHeight(y)

	self:AnnounceItem()
end

function ItemDistWindow:LoadGPOptions()
	self.gp_options = {}
	if self.item_id == nil then
		return
	end

	local item_data = addon.app.data.items[self.item_id]
	if item_data == nil then
		return
	end

	local grades = table_get_keys(item_data.by_grade)
	table.sort(grades)
	for _, grade in pairs(grades) do
		grade_data = item_data.by_grade[grade]
		table.insert(self.gp_options, {
			["text"] = "[" .. addon.app.grades[grade] .. "] " .. grade_data.price .. " GP",
			["value"] = grade_data.price,
		})
	end

	UIDropDownMenu_SetSelectedName(self.sections.transaction.gp_dropdown, "hello world", true)
end

function ItemDistWindow:AnnounceItem()
	if self.item_id == nil then
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
			local str = " [ " .. addon.app.grades[grade] .. " ] "
			str = str .. " [ " .. grade_data.price .. "gp ] "
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
	self.sections.players:Hide()
	self.sections.actions:Hide()
	self.sections.transaction:Show()
end

function ItemDistWindow:CancelTransaction()
	self.sections.players:Show()
	self.sections.actions:Show()
	self.sections.transaction:Hide()
end

function ItemDistWindow:ConfirmTransaction()
	self:ClearItem()
	print("ConfirmTransaction()")
end

function ItemDistWindow:ToggleMenu()
	local menu = self.sections.menu
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	ToggleDropDownMenu(1, nil, menu, "cursor", 3, -3, nil, nil, 2)
end

function ItemDistWindow:CreateMenu(frame, level, menulist)
	local info

	info = get_clean_menu_button()
	info.text = "Open Options"
	info.func = function ()
		InterfaceOptionsFrame_OpenToCategory(addon.app.interface_options.panel)
		InterfaceOptionsFrame_OpenToCategory(addon.app.interface_options.panel)
	end
	UIDropDownMenu_AddButton(info)

	info = get_clean_menu_button()
	info.disabled = true
	UIDropDownMenu_AddButton(info)

	if addon.app.item_dist_window and addon.app.item_dist_window.item_id ~= nil then
		info = get_clean_menu_button()
		info.text = "Item Options"
		info.isTitle = true
		UIDropDownMenu_AddButton(info)

		info = get_clean_menu_button()
		info.text = "Announce Item"
		info.noClickSound = true
		info.func = function ()
			addon.app.item_dist_window:AnnounceItem()
		end
		UIDropDownMenu_AddButton(info)

		info = get_clean_menu_button()
		info.text = "Clear Item"
		info.noClickSound = true
		info.func = function ()
			addon.app.item_dist_window:ClearItem()
		end
		UIDropDownMenu_AddButton(info)

		info = get_clean_menu_button()
		info.disabled = true
		UIDropDownMenu_AddButton(info)
	end

	info = get_clean_menu_button()
	info.text = "Window Options"
	info.isTitle = true
	UIDropDownMenu_AddButton(info)

	info = get_clean_menu_button()
	info.text = "Close Window"
	info.func = function ()
		addon.app.item_dist_window:Toggle()
	end
	UIDropDownMenu_AddButton(info)

	info = get_clean_menu_button()
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

	info = get_clean_menu_button()
	info.disabled = true
	UIDropDownMenu_AddButton(info)

	info = get_clean_menu_button()
	info.text = "Cancel"
	UIDropDownMenu_AddButton(info)
end

--- Enable dragging and bind to drag events
function ItemDistWindow:Unlock()
	local panel = self.panel
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")

	-- Bind to drag start event
	panel:SetScript("OnDragStart", function ()
		panel:StartMoving()
	end)

	-- Bind to drag stop
	panel:SetScript("OnDragStop", function ()
		_, _, _, x, y = panel:GetPoint()

		-- Clamp top left
		x = max(x, 0)
		y = min(y, 0)

		-- Clamp bottom right
		x = min(x, GetScreenWidth() - panel:GetWidth())
		y = max(y, -1 * GetScreenHeight() + panel:GetHeight())

		-- Save position
		addon.app:SetOption("item_dist_window.x", x)
		addon.app:SetOption("item_dist_window.y", y)

		-- Set position
		panel:StopMovingOrSizing()
		panel:ClearAllPoints()
		panel:SetPoint("TOPLEFT", x, y)
	end)
end

--- Disable dragging
function ItemDistWindow:Lock()
	self.panel:SetMovable(false)
	self.panel:RegisterForDrag(nil)
end

function ItemDistWindow:Build()
	self.item_id = nil

	self.width = 200
	self.top_section_height = 35
	self.min_transaction_height = 60

	self.player_height = 15
	self.player_index = 1
	self.player_frames = {}
	self.selected_player = nil

	self.gp_options = {}
	self.selected_gp = 0
	self.sections = {
		["menu"] = nil,
		["top"] = nil,
		["details"] = nil,
		["players"] = nil,
		["actions"] = nil,
		["transaction"] = nil
	}

	-- Create the window
	self.panel = CreateFrame("Frame")
	local panel = self.panel
	panel:EnableMouse(true)
	panel:SetClampedToScreen(true)

	-- Bind to whisper events
	panel:RegisterEvent("CHAT_MSG_WHISPER")
	panel:SetScript("OnEvent", function (self, event, arg1, arg2)
		if event == "CHAT_MSG_WHISPER" then
			local msg = arg1
			local author = arg2
			local s, e = string.find(msg, "need")
			if s ~= nil then
				addon.app.item_dist_window:AddPlayer(author)
			end
		end
	end)

	-- Set lock state
	if addon.app:GetOption("item_dist_window.lock") then
		self:Lock()
	else
		self:Unlock()
	end

	-- Bind to mouse up event
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
	panel:SetWidth(self.width)
	panel:SetHeight(self.top_section_height)
	-- panel:Hide()

	-- Menu
	self.sections.menu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
	self.sections.menu:SetPoint("CENTER")
	UIDropDownMenu_Initialize(self.sections.menu, self.CreateMenu, "MENU")

	self:CreateTopSection()
	self:CreateDetailsSection()
	self:CreatePlayersSection()
	self:CreateActionsSection()
	self:CreateTransactionSection()
end

function ItemDistWindow:CreateTransactionSection()
	local elem, subelem
	self.sections.transaction = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.transaction
	frame:SetPoint("TOPLEFT", 0, -1 * self.top_section_height)
	frame:SetWidth(self.width)
	frame:SetHeight(self.min_transaction_height)
	--frame:Hide()

	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	-- Cancel button
	elem = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(45)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:CancelTransaction()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Back")

	-- Confirm button
	elem = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMRIGHT", -3, 3)
	elem:SetWidth(70)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:ConfirmTransaction()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Confirm")

	-- Give text
	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -3)
	elem:SetJustifyH("LEFT")
	elem:SetText("Give item to: ")

	-- Player name text
	frame.player_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem = frame.player_text
	elem:SetPoint("TOPLEFT", 73, -3)
	elem:SetJustifyH("LEFT")

	-- For text
	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -20)
	elem:SetJustifyH("LEFT")
	elem:SetText("For: ")

	-- GP dropdown select
	frame.gp_dropdown = CreateFrame("BUTTON", nil, frame, "UIDropDownMenuTemplate")
	frame.gp_dropdown:SetPoint("TOPLEFT", 15, -17)
	frame.gp_dropdown:SetScale(0.85)
	UIDropDownMenu_SetWidth(frame.gp_dropdown, 80, 2)
	UIDropDownMenu_Initialize(frame.gp_dropdown, function (frame, level, menulist)
		if addon.app.item_dist_window then
			addon.app.item_dist_window:CreateGPDropdown(frame, level, menulist)
		end
	end)
end

function ItemDistWindow:CreateGPDropdown(frame, level, menulist)
	local info

	for key, option in pairs(addon.app.item_dist_window.gp_options) do
		info = get_clean_menu_button()
		info.text = option.text
		info.value = option.value
		info.notCheckable = false
		info.func = function (self)
			addon.app.item_dist_window:SelectGPValue(self.value)
			UIDropDownMenu_SetSelectedID(frame, self:GetID())
		end
		UIDropDownMenu_AddButton(info)
	end

	info = get_clean_menu_button()
	info.text = "Manual GP"
	info.value = -1
	info.notCheckable = false
	info.func = function (self)
		addon.app.item_dist_window:SelectGPValue(self.value)
		UIDropDownMenu_SetSelectedID(frame, self:GetID())
	end
	UIDropDownMenu_AddButton(info)
end

function ItemDistWindow:SelectGPValue(gp)
	print("SelectGPValue(" .. gp .. ")")
	self.selected_gp = gp
	self.sections.transaction.gp_dropdown:SetText(gp .. " GP")
end

function ItemDistWindow:CreateTopSection()
	local elem
	self.sections.top = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.top
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetWidth(self.width)
	frame:SetHeight(self.top_section_height)

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.5)
	elem:SetAllPoints(frame)

	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	elem = frame.title
	elem:SetPoint("TOPLEFT", 37, -6)
	elem:SetPoint("BOTTOMRIGHT", -3, 17)
	elem:SetJustifyH("LEFT")
	elem:SetJustifyV("TOP")
	elem:SetText(addon.app.name)

	-- Subtitle
	frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem = frame.subtitle
	elem:SetPoint("TOPLEFT", 37, -12)
	elem:SetJustifyH("LEFT")
	elem:SetText("Item Distribution")
	elem:SetTextColor(1, 1, 1)
	elem:SetHeight(25)

	-- Item bag slot
	elem = frame:CreateTexture(nil, "ARTWORK")
	elem:SetPoint("TOPLEFT", 0, 0)
	elem:SetHeight(55)
	elem:SetWidth(55)
	elem:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	-- Item slot
	frame.item_texture = frame:CreateTexture(nil, "OVERLAY")
	elem = frame.item_texture
	elem:SetPoint("TOPLEFT", 0, 0)
	elem:SetHeight(35)
	elem:SetWidth(35)
	elem:SetTexture(nil)
end

function ItemDistWindow:CreateDetailsSection()
	local elem

	-- Frame
	self.sections.details = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.details
	frame:SetPoint("TOPLEFT", 0, -1 * self.top_section_height)
	frame:SetWidth(self.width)
	frame:Hide()

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	-- Grade frame
	frame.grade_frame = addon.app:BuildGradeFrame(frame)
	frame.grade_frame.frame:SetPoint("TOPLEFT", 5, 0)
end

function ItemDistWindow:CreatePlayersSection()
	local elem

	self.sections.players = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.players
	frame:SetPoint("TOPLEFT", 0, -1 * self.top_section_height)
	frame:SetWidth(self.width)
	frame:SetHeight(self.player_height)
	frame:Hide()

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	local color = {1, 1, 1, 0.4}
	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 5, 0)
	elem:SetJustifyH("LEFT")
	elem:SetTextColor(unpack(color))
	elem:SetHeight(self.player_height)
	elem:SetText("Player")

	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 90, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(unpack(color))
	elem:SetHeight(self.player_height)
	elem:SetText("EP")

	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 122, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(unpack(color))
	elem:SetHeight(self.player_height)
	elem:SetText("GP")

	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPRIGHT", -3, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(38)
	elem:SetTextColor(unpack(color))
	elem:SetHeight(self.player_height)
	elem:SetText("PR")
end

function ItemDistWindow:AddPlayer(name)
	if self.item_id == nil then
		return
	end

	local elem

	local pdata = addon.app:GetPlayerData(name)
	if pdata == nil then
		return
	end

	local frame = self.player_frames[self.player_index]
	if frame == nil then
		-- Frame
		frame = CreateFrame("Frame", nil, self.sections.players)
		self.player_frames[self.player_index] = frame
		frame:EnableMouse(true)
		frame.index = self.player_index
		frame:SetPoint("TOPLEFT", 0, 0)
		frame:SetWidth(self.width)
		frame:SetHeight(self.player_height)

		-- Name
		frame.name_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		elem = frame.name_text
		elem:SetPoint("TOPLEFT", 5, 0)
		elem:SetJustifyH("LEFT")
		elem:SetHeight(self.player_height)

		-- EP
		frame.ep_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		elem = frame.ep_text
		elem:SetPoint("TOPLEFT", 90, 0)
		elem:SetJustifyH("RIGHT")
		elem:SetWidth(35)
		elem:SetHeight(self.player_height)

		-- GP
		frame.gp_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		elem = frame.gp_text
		elem:SetPoint("TOPLEFT", 122, 0)
		elem:SetJustifyH("RIGHT")
		elem:SetWidth(35)
		elem:SetHeight(self.player_height)

		-- PR
		frame.pr_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		elem = frame.pr_text
		elem:SetPoint("TOPRIGHT", -3, 0)
		elem:SetJustifyH("RIGHT")
		elem:SetWidth(38)
		elem:SetHeight(self.player_height)

		elem = frame:CreateTexture(nil, "HIGHLIGHT")
		elem:SetColorTexture(1, 0.82, 0, 0.2)
		elem:SetAllPoints(frame)

		frame.hili_sel = frame:CreateTexture(nil, "ARTWORK")
		elem = frame.hili_sel
		elem:SetColorTexture(1, 0.82, 0, 0.4)
		elem:SetAllPoints(frame)
		elem:Hide()

		-- Bind to click event
		frame:SetScript('OnMouseUp', function()
			local window = addon.app.item_dist_window
			window:ClearPlayerSelection()
			frame.hili_sel:Show()
			window.sections.transaction.player_text:SetTextColor(frame.name_text:GetTextColor())
			window.sections.transaction.player_text:SetText(frame.name_text:GetText())
			window:EnableDistributeButton()
		end)
	end
	self.player_index = self.player_index + 1

	-- Get player EP and GP
	local onote_data = addon.app:ParseOfficerNote(pdata.onote)
	local ep = onote_data.ep
	local gp = onote_data.gp

	-- debug
	ep = math.random(50,500)
	gp = math.random(10,190)

	frame.pr = addon.app:GetPR(ep, gp)

	-- Set class color
	if pdata.class == "SHAMAN" then
		-- Override shaman color to blue
		-- #0070DE
		frame.name_text:SetTextColor(0, 0.4375, 0.8706)
	else
		frame.name_text:SetTextColor(GetClassColor(pdata.class))
	end

	-- Set this row text
	frame.name_text:SetText(addon.app:RemoveServerFromName(name))
	frame.ep_text:SetText(ep)
	frame.gp_text:SetText(gp)
	frame.pr_text:SetText(frame.pr)
	frame:Show()

	-- Order the players section
	self:OrderPlayers()

	-- Resize players section
	self.sections.players:SetHeight(self.player_height * self.player_index)

	-- Move actions section down
	local y = self.sections.top:GetHeight() + self.sections.details:GetHeight() + self.sections.players:GetHeight()
	self.sections.actions:SetPoint("TOPLEFT", 0, -1 * y)

	-- Resize transaction section (it's hidden)
	local h = max(self.min_transaction_height, self.sections.players:GetHeight() + self.sections.actions:GetHeight())
	self.sections.transaction:SetHeight(h)

	-- Increase size of panel
	self.panel:SetHeight(y + self.sections.actions:GetHeight())
end

--- Order the players list by PR
function ItemDistWindow:OrderPlayers()
	local tmp = {}
	for i = 1, (self.player_index - 1) do
		table.insert(tmp, self.player_frames[i])
	end
	table.sort(tmp, function(t1, t2)
		return t1.pr > t2.pr
	end)
	for i = 1, sizeof(tmp) do
		tmp[i]:SetPoint("TOPLEFT", 0, -1 * self.player_height * i)
	end
end

function ItemDistWindow:CreateActionsSection()
	local elem, subelem

	-- Frame
	self.sections.actions = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.actions
	frame:SetPoint("TOPLEFT", 0, -1 * (self.top_section_height + self.player_height))
	frame:SetWidth(self.width)
	frame:SetHeight(23)
	frame:Hide()

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	-- Clear button
	elem = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(45)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:ClearItem()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Clear")

	-- Distribute button
	frame.btn_dist = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	elem = frame.btn_dist
	elem:SetPoint("BOTTOMRIGHT", -3, 3)
	elem:SetWidth(70)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:DistributeItem()
	end)
	frame.btn_dist_text = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem = frame.btn_dist_text
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Distribute")

	self:DisableDistributeButton()
end

function ItemDistWindow:EnableDistributeButton()
	self.sections.actions.btn_dist:Enable()
	self.sections.actions.btn_dist_text:SetTextColor(1, 0.82, 0)
end

function ItemDistWindow:DisableDistributeButton()
	self.sections.actions.btn_dist:Disable()
	self.sections.actions.btn_dist_text:SetTextColor(1, 1, 1, 0.5)
end
