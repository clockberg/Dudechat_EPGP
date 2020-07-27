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
	self.selected_player = nil
	self.player_index = 1
	for i = 1, sizeof(self.player_frames) do
		self.player_frames[i]:Hide()
	end
	self.sections.top.item_texture:SetTexture(nil)
	self.sections.top.title:SetText(addon.app.name)
	self.sections.details:Hide()
	self.sections.players:Hide()
	self.sections.actions:Hide()
	self.panel:SetHeight(self.top_section_height)
	if play_sound == nil or play_sound then
		PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
	end
end

function ItemDistWindow:SetItem(item_id)
	self:ClearItem(false)
	self.item_id = item_id
	local _, item_link, _, _, _, _, _, _ = GetItemInfo(item_id);
	self.sections.top.item_texture:SetTexture(GetItemIcon(item_id))
	self.sections.top.title:SetText(item_link)

	local details = self.sections.details
	details.grade_frame:Update(item_id)
	local dh = details.grade_frame.frame:GetHeight()
	details:SetHeight(dh)
	if dh > 0 then
		details:Show()
	end

	local players = self.sections.players
	local y = self.top_section_height + details:GetHeight()
	players:SetPoint("TOPLEFT", 0, -1 * y)
	players:SetHeight(self.player_height)
	players:Show()

	local actions = self.sections.actions
	y = self.top_section_height + details:GetHeight() + players:GetHeight()
	actions:SetPoint("TOPLEFT", 0, -1 * y)
	actions:Show()

	y = self.top_section_height + details:GetHeight() + players:GetHeight() + actions:GetHeight()
	self.panel:SetHeight(y)

	self:AnnounceItem()
end

function ItemDistWindow:HasItem()
	if self.item_id == nil then
		return false
	end
	return true
end

function ItemDistWindow:AnnounceItem()
	if not self:HasItem() then
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
	print("DistributeItem()")
end

function ItemDistWindow:ToggleMenu()
	local menu = self.sections.menu
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
		panel:SetPoint("TOPLEFT", x, y)
		panel:SetPoint("TOP", x)
	end)
end

function ItemDistWindow:Lock()
	local panel = self.panel
	panel:SetMovable(false)
	panel:RegisterForDrag(nil)
end

function ItemDistWindow:Build()
	self.item_id = nil
	self.width = 200
	self.top_section_height = 43
	self.player_height = 15
	self.selected_player = nil
	self.player_frames = {}
	self.player_index = 1
	self.sections = {
		["menu"] = nil,
		["top"] = nil,
		["details"] = nil,
		["players"] = nil,
		["actions"] = nil,
	}

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

	-- Bind to mouse events
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
end

function ItemDistWindow:CreateTopSection()
	local elem
	self.sections.top = CreateFrame("Frame", nil, self.panel)
	local frame = self.sections.top
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetPoint("TOP", 0)
	frame:SetWidth(self.width)
	frame:SetHeight(self.top_section_height)

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.5)
	elem:SetPoint("TOPLEFT", 0, 0)
	elem:SetPoint("TOPRIGHT", 0, 0)
	elem:SetHeight(self.top_section_height)

	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	elem = frame.title
	elem:SetPoint("TOPLEFT", 45, -4)
	elem:SetPoint("TOPRIGHT", -10, -4)
	elem:SetJustifyH("LEFT")
	elem:SetText(addon.app.name)
	elem:SetHeight(25)

	-- Subtitle
	elem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 45, -16)
	elem:SetPoint("TOPRIGHT", -10, -16)
	elem:SetJustifyH("LEFT")
	elem:SetText("Item Distribution")
	elem:SetTextColor(1, 1, 1)
	elem:SetHeight(25)

	-- Item bag slot
	elem = frame:CreateTexture(nil, "ARTWORK")
	elem:SetPoint("TOPLEFT", 5, -5)
	elem:SetHeight(55)
	elem:SetWidth(55)
	elem:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	-- Item slot
	frame.item_texture = frame:CreateTexture(nil, "OVERLAY")
	elem = frame.item_texture
	elem:SetPoint("TOPLEFT", 5, -5)
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
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetWidth(self.width)
	frame:SetHeight(self.player_height)
	frame:Hide()

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	local color = {255, 255, 255, 0.4}
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
	if not self:HasItem() then
		return
	end

	local elem

	local pdata = addon.app:GetPlayerData(name)
	if pdata == nil then
		return
	end
	pdata = addon.app:GetPlayerDataFresh(pdata.gindex)

	local frame = self.player_frames[self.player_index]
	if frame == nil then
		-- Frame
		frame = CreateFrame("Frame", nil, self.sections.players)
		self.player_frames[self.player_index] = frame
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
	end
	self.player_index = self.player_index + 1

	-- Get player EP and GP
	local onote_data = addon.app:ParseOfficerNote(pdata.onote)
	local ep = onote_data.ep
	local gp = onote_data.gp
	ep = math.random(50,500)
	gp = math.random(10,190)
	frame.pr = addon.app:GetPR(ep, gp)

	-- Set this row text
	local color
	if pdata.class == "SHAMAN" then
		-- #0070DE
		frame.name_text:SetTextColor(0, 0.4375, 0.8706)
	else
		frame.name_text:SetTextColor(GetClassColor(pdata.class))
	end

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

	-- Increase size of panel
	self.panel:SetHeight(y + self.sections.actions:GetHeight())
end

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
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetWidth(self.width)
	frame:SetHeight(23)
	frame:Hide()

	-- Background
	elem = frame:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.7)
	elem:SetAllPoints(frame)

	-- Clear button
	elem = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	elem:SetPoint("TOPLEFT", 3, -2)
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
	elem:SetPoint("TOPRIGHT", -3, -2)
	elem:SetWidth(70)
	elem:SetHeight(18)
	elem:Disable()
	elem:SetScript("OnClick", function (_, button)
		addon.app.item_dist_window:DistributeItem()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetTextColor(255, 255, 255, 0.5)
	subelem:SetText("Distribute")
end
