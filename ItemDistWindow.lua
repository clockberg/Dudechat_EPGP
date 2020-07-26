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
	local item = self.panel.item
	item:SetTexture(nil)
	if play_sound == nil or play_sound then
		PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
	end
end

function ItemDistWindow:SetItem(item_id)
	local item = self.panel.item
	item:SetTexture(GetItemIcon(item_id))
end

function ItemDistWindow:ToggleMenu()
	local menu = self.panel.menu
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	ToggleDropDownMenu(1, nil, menu, "cursor", 3, -3, nil, nil, 2)
end

function ItemDistWindow:CreateMenu(frame, level, menulist)
	local info

	info = UIDropDownMenu_CreateInfo()
	info.text = "Frame Options"
	info.notCheckable = true
	info.isTitle = true
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = "Close Frame"
	info.notCheckable = true
	info.func = function ()
		addon.app.item_dist_window:Toggle()
	end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true
	if addon.app:GetOption("item_dist_window.lock") then
		info.text = "Unlock Frame"
		info.func = function ()
			addon.app:SetOption("item_dist_window.lock", false)
			addon.app.item_dist_window:Unlock()
		end
	else
		info.text = "Lock Frame"
		info.func = function ()
			addon.app:SetOption("item_dist_window.lock", true)
			addon.app.item_dist_window:Lock()
		end
	end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.disabled = true
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
	self.panel = CreateFrame("Frame", nil, UIParent)
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
			self:SetItem(item_id)
		elseif button == "RightButton" then
			self:ToggleMenu()
		end
	end)
	panel:SetPoint("TOPLEFT", addon.app:GetOption("item_dist_window.x"), addon.app:GetOption("item_dist_window.y"))
	panel:SetWidth(200)
	panel:SetHeight(43)
	-- panel:Hide()

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(panel)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 10, -3)
	title:SetPoint("TOPRIGHT", -10, -3)
	title:SetJustifyH("LEFT")
	title:SetText("Dudechat EPGP")
	title:SetHeight(25)

	local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", 10, -14)
	subtitle:SetPoint("TOPRIGHT", -10, -14)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetText("Item Distribution")
	subtitle:SetTextColor(1, 1, 1)
	subtitle:SetHeight(25)

	local slot = panel:CreateTexture(nil, "ARTWORK")
	slot:SetPoint("TOPRIGHT", 15, -5)
	slot:SetHeight(55)
	slot:SetWidth(55)
	slot:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	panel.item = panel:CreateTexture(nil, "OVERLAY")
	local item = panel.item
	item:SetPoint("TOPRIGHT", -4, -4)
	item:SetHeight(36)
	item:SetWidth(36)
	item:SetTexture(nil)

	-- ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
	panel.menu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
	local menu = panel.menu
	menu:SetPoint("CENTER")
	UIDropDownMenu_SetWidth(menu, 200)
	UIDropDownMenu_Initialize(menu, self.CreateMenu, "MENU")
end
