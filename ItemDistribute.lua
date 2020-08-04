local _, addon = ...

-- Set up module
local M = {}
addon.ItemDistribute = M
local _G = _G
local dd = function (msg)
	_G.print("ItemDistribute." .. msg)
end
setfenv(1, M)

-- Window
window = nil -- <Frame>
window_width = 200 -- <number>

-- Menu
menu = nil -- <Frame>

-- Selected
selected_item_id = nil -- <number>
selected_item_name = nil -- <string>
selected_player = nil -- <string>
selected_gp = nil -- <number>

gp_options = {}

-- Sections
sections = {
	header = {
		frame = nil, -- <Frame>
		title = nil, -- <FontString>
		icon = nil, -- <Texture>
		height = 35, -- <number>
	},
	details = {
		frame = nil, -- <Frame>
		item_details_component = nil, -- <ItemDetailsComponent>
	},
	players = {
		frame = nil, -- <Frame>
		height_ea = 15, -- <number>
		th_color = {1, 1, 1, 0.4}, -- <table>
		index = 1, -- <number>
		frames = {}, -- <table of <Frame>>
	},
	actions = {
		frame = nil, -- <Frame>
		height = 23, -- <number>
		btn_dist = nil, -- <Frame>
		btn_dist_text = nil, -- <Frame>
	},
	checkout = {
		frame = nil, -- <Frame>
		min_height = 70, -- <number>
		player = nil, -- <FontString>
		gp_select = {
			dropdown = nil, -- <Frame>
			wrapper = nil, -- <Frame>
			options = {
				max = 0, -- <number> Set dynamically based on Tiers
				height_ea = 15, -- <number>
				frames = {}, -- <table of <Frame>>
			},
		},
	},
}

--- Load this module
function Load()
	dd("Load")

	-- Window frame
	window = _G.CreateFrame("Frame", nil, nil, "BasicFrameTemplate")
	window:EnableMouse(true)
	window:SetClampedToScreen(true)
	window:SetPoint(
		"TOPLEFT",
		addon.Config.GetOption("ItemDistribute.x"),
		addon.Config.GetOption("ItemDistribute.y")
	)
	window:SetPoint("TOP", addon.Config.GetOption("ItemDistribute.y"))
	window:SetWidth(window_width)
	window:SetHeight(sections.header.height)

	-- Window background
	-- To darken the background texture a bit
	local bg = window:CreateTexture(nil, "ARTWORK")
	bg:SetColorTexture(0, 0, 0, 0.6)
	bg:SetPoint("TOPLEFT", 3, -20)
	bg:SetPoint("BOTTOMRIGHT", -3, 3)

	-- Bind window to whisper events
	window:RegisterEvent("CHAT_MSG_WHISPER")
	window:SetScript("OnEvent", Window_OnEvent)

	-- Set initial lock state
	if addon.Config.GetOption("ItemDistribute.lock") then
		Window_Lock()
	else
		Window_Unlock()
	end

	-- Bind to mouse events
	window:SetScript("OnMouseUp", Window_OnMouseUp)

	--- Hook item link to put into our addon
	-- Normal usage is shift+left click
	local orig_ChatEdit_InsertLink = _G.ChatEdit_InsertLink
	_G.ChatEdit_InsertLink = function (...)
		local text = ...
		local result = orig_ChatEdit_InsertLink(...)
		if not result and text and window:IsVisible() then
			Item_Set(addon.Util.GetItemIdFromItemLink(text))
			_G.PlaySound(_G.SOUNDKIT.IG_ABILITY_ICON_DROP)
		end
		return false
	end

	-- Menu
	menu = _G.CreateFrame("Frame", nil, _G.UIParent, "UIDropDownMenuTemplate")
	menu:SetPoint("CENTER")
	_G.UIDropDownMenu_Initialize(menu, Menu_Create, "MENU")

	Header_Load()
	Details_Load()
	Players_Load()
	Actions_Load()
	Checkout_Load()
end

-------
-- Item
-------

--- Sets the selected item
-- @param item_id <number>
function Item_Set(item_id)
	dd("Item_Set(" .. item_id .. ")")

	Item_Clear(false)

	if not item_id then
		return
	end

	-- Set the selected item
	local item_name, item_link, _, _, _, _, _, _ = _G.GetItemInfo(item_id)
	selected_item_id = item_id
	selected_item_name = item_name

	-- Load the item GP data
	Item_LoadGP()

	-- Update the sections
	Header_SetItem(item_id, item_link)
	Details_SetItem(item_id)
	Players_Activate()
	Actions_Activate()
	Checkout_UpdateGPDropdown()
	Window_Resize()
end

--- Loads the GP options for the selected item
function Item_LoadGP()
	gp_options = {}

	local item_data = addon.data.items[selected_item_id]
	if item_data == nil then
		return
	end

	local tiers = addon.Util.TableGetKeys(item_data.by_tier)
	_G.table.sort(tiers)
	for _, tier in _G.pairs(tiers) do
		tier_data = item_data.by_tier[tier]
		_G.table.insert(gp_options, {
			["text"] = addon.data.tiers[tier] .. ": " .. tier_data.price .. "gp",
			["price"] = tier_data.price,
		})
	end

	if item_data.price ~= nil then
		_G.table.insert(gp_options, {
			["text"] = "*: " .. item_data.price .. "gp",
			["price"] = item_data.price,
		})
	end
end

--- Announces the selected item
function Item_Announce()
	dd("Item_Announce")
end

--- Clears the selected item
-- @param is_play_sound <boolean>
function Item_Clear(is_play_sound)
	dd("Item_Clear")

	selected_item_id = nil
	selected_item_name = nil

	Header_Reset()
	Details_Reset()
	Players_Reset()
	Actions_Reset()
	Checkout_Reset()
	Window_Resize()

	if is_play_sound == nil or is_play_sound then
		_G.PlaySound(_G.SOUNDKIT.IG_ABILITY_ICON_DROP)
	end
end

---------
-- Header
---------

function Header_Load()
	dd("Header_Load")

	sections.header.frame = _G.CreateFrame("Frame", nil, window)
	sections.header.frame:SetPoint("TOPLEFT", 0, 0)
	sections.header.frame:SetWidth(window_width)
	sections.header.frame:SetHeight(sections.header.height)

	-- Title
	sections.header.title = sections.header.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sections.header.title:SetPoint("TOPLEFT", 37, -6.5)
	sections.header.title:SetPoint("BOTTOMRIGHT", -3, 17)
	sections.header.title:SetJustifyH("LEFT")
	sections.header.title:SetJustifyV("TOP")

	-- Subtitle
	local elem = sections.header.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", 37, -14.5)
	elem:SetJustifyH("LEFT")
	elem:SetText("Item Distribution")
	elem:SetTextColor(1, 1, 1)
	elem:SetHeight(25)

	-- Item bag slot
	elem = sections.header.frame:CreateTexture(nil, "ARTWORK")
	elem:SetPoint("TOPLEFT", 1, -2)
	elem:SetHeight(51)
	elem:SetWidth(51)
	elem:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	-- Item texture slot
	sections.header.icon = sections.header.frame:CreateTexture(nil, "OVERLAY")
	sections.header.icon:SetPoint("TOPLEFT", 1, -1)
	sections.header.icon:SetHeight(33)
	sections.header.icon:SetWidth(33)

	Header_Reset()
end

--- Reset the header section
function Header_Reset()
	dd("Header_Reset")

	sections.header.title:SetText(addon.short_name)
	sections.header.icon:SetTexture(nil)
end

--- Sets the item for the header section
-- @param item_id <number>
-- @param item_link <string>
function Header_SetItem(item_id, item_link)
	dd("Header_SetItem")

	sections.header.icon:SetTexture(_G.GetItemIcon(item_id))
	sections.header.title:SetText(item_link)
end

----------
-- Details
----------

--- Load the details section
function Details_Load()
	dd("Details_Load")

	sections.details.frame = _G.CreateFrame("Frame", nil, window)
	sections.details.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.details.frame:SetWidth(window_width)

	sections.details.item_details_component = addon.ItemDetailsComponent.Create(sections.details.frame)
	sections.details.item_details_component.frame:SetPoint("TOPLEFT", 5, 0)

	Details_Reset()
end

--- Reset the details section
function Details_Reset()
	dd("Details_Reset")
	sections.details.frame:Hide()
end

--- Update the details section with the given item ID
-- @param item_id <number>
function Details_SetItem(item_id)
	dd("Details_SetItem")
	sections.details.item_details_component:UpdateItem(item_id)
	local h = sections.details.item_details_component.frame:GetHeight()
	sections.details.frame:SetHeight(h)
	if h > 0 then
		sections.details.frame:Show()
	else
		sections.details.frame:Hide()
	end
end

---------
-- Player
---------

--- Load the players section
function Players_Load()
	dd("Players_Load")

	sections.players.frame = _G.CreateFrame("Frame", nil, window)
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.players.frame:SetWidth(window_width)
	sections.players.frame:SetHeight(sections.players.height_ea)

	local elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 5, 0)
	elem:SetJustifyH("LEFT")
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("Player")

	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 90, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("EP")

	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 122, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("GP")

	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPRIGHT", -3, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(38)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("PR")

	Players_Reset()
end

--- Reset the players section
function Players_Reset()
	dd("Players_Reset")
	Players_Deselect()
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i]:Hide()
	end
	sections.players.index = 1
	sections.players.frame:Hide()
end

--- Reposition the players section
function Players_Reposition()
	dd("Players_Reposition")
	sections.players.frame:ClearAllPoints()
	local y = sections.header.frame:GetHeight()
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * y)
	sections.players.frame:SetHeight(sections.players.height_ea)
end

--- Activate the players section
function Players_Activate()
	Players_Reposition()
	sections.players.frame:Show()
end

--- A player needs the selected item
-- @param name <string>
function Players_Need(name)
	dd("Players_Need")
end

--- Deselect all players
function Players_Deselect()
	dd("Players_Deselect")
	selected_player = nil
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i].highlight:Hide()
	end
end

----------
-- Actions
----------

--- Load the actions section
function Actions_Load()
	dd("Actions_Load")

	-- Frame
	sections.actions.frame = _G.CreateFrame("Frame", nil, window)
	sections.actions.frame:SetWidth(window_width)
	sections.actions.frame:SetHeight(sections.actions.height)

	-- Cancel button
	local elem = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(45)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		Item_Clear()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Cancel")

	-- Distribute button
	sections.actions.btn_dist = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	sections.actions.btn_dist:SetPoint("BOTTOMRIGHT", -3, 3)
	sections.actions.btn_dist:SetWidth(70)
	sections.actions.btn_dist:SetHeight(18)
	sections.actions.btn_dist:SetScript("OnClick", function (_, button)
		Checkout_Activate()
	end)
	sections.actions.btn_dist_text = sections.actions.btn_dist:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sections.actions.btn_dist_text:SetPoint("TOPLEFT", 5, 0)
	sections.actions.btn_dist_text:SetPoint("TOPRIGHT", -5, 0)
	sections.actions.btn_dist_text:SetJustifyH("CENTER")
	sections.actions.btn_dist_text:SetHeight(18)
	sections.actions.btn_dist_text:SetText("Distribute")

	Actions_Reset()
end

--- Reset the actions section
function Actions_Reset()
	dd("Actions_Reset")
	sections.actions.frame:Hide()
	Actions_DisableDistributeButton()
end

--- Reposition the actions section
function Actions_Reposition()
	dd("Actions_Reposition")
	local y = sections.header.height
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	y = y + sections.players.frame:GetHeight()
	sections.actions.frame:SetPoint("TOPLEFT", 0, -1 * y)
end

--- Activate the actions section
function Actions_Activate()
	dd("Actions_Activate")
	Actions_Reposition()
	sections.actions.frame:Show()
end

--- Disable the distribute button
function Actions_DisableDistributeButton()
	dd("Actions_DisableDistributeButton")
	sections.actions.btn_dist:Disable()
	sections.actions.btn_dist_text:SetTextColor(1, 1, 1, 0.5)
end

--- Enable the distribute button
function Actions_EnableDistributeButton()
	dd("Actions_EnableDistributeButton")
	sections.actions.btn_dist:Enable()
	sections.actions.btn_dist_text:SetTextColor(1, 0.82, 0)
end

-----------
-- Checkout
-----------

--- Load the checkout section
function Checkout_Load()
	dd("Checkout_Load")

	sections.checkout.frame = _G.CreateFrame("Frame", nil, window)
	sections.checkout.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.checkout.frame:SetWidth(window_width)
	sections.checkout.frame:SetHeight(sections.checkout.min_height)

	-- Back button
	local elem = _G.CreateFrame("Button", nil, sections.checkout.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(45)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		Checkout_Cancel()
	end)
	local subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Back")

	-- Confirm button
	elem = _G.CreateFrame("Button", nil, sections.checkout.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMRIGHT", -3, 3)
	elem:SetWidth(70)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		Checkout_Confirm()
	end)
	subelem = elem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Confirm")

	-- "Give item to.." text
	elem = sections.checkout.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -3)
	elem:SetJustifyH("LEFT")
	elem:SetText("Give item to: ")

	-- Player name text
	sections.checkout.player = sections.checkout.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sections.checkout.player:SetPoint("TOPLEFT", 73, -3)
	sections.checkout.player:SetJustifyH("LEFT")

	-- "For.." text
	elem = sections.checkout.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -23)
	elem:SetJustifyH("LEFT")
	elem:SetText("For: ")

	-- GP select dropdown
	local sel = sections.checkout.gp_select
	sel.options.max = addon.Util.SizeOf(addon.data.tiers) + 1
	sel.dropdown = _G.CreateFrame("FRAME", nil, sections.checkout.frame, "OptionsDropdownTemplate")
	sel.dropdown:SetPoint("TOPLEFT", 10, -15)
	sel.dropdown.Text:SetText("N/A")
	sel.dropdown.Middle:SetWidth(65)
	sel.dropdown.Button:SetScript("OnClick", function (_, button)
		Checkout_ShowGPOptions()
	end)

	-- GP select wrapper
	sel.wrapper = _G.CreateFrame("FRAME", nil, sel.dropdown)
	sel.wrapper:SetPoint("TOPLEFT", 18, -27)
	sel.wrapper:SetHeight(sel.options.height_ea * sel.options.max)
	sel.wrapper:SetWidth(15 + sel.dropdown.Middle:GetWidth())

	-- GP select wrapper background
	elem = sel.wrapper:CreateTexture(nil, "BACKGROUND")
	elem:SetColorTexture(0, 0, 0, 0.6)
	elem:SetAllPoints(sel.wrapper)

	-- GP select options
	for i = 1, sel.options.max do
		-- Option button
		sel.options.frames[i] = _G.CreateFrame("BUTTON", nil, sel.wrapper)
		sel.options.frames[i]:SetPoint("TOPLEFT", 0, -1 * (i - 1) * sel.options.height_ea)
		sel.options.frames[i]:SetWidth(sel.wrapper:GetWidth())
		sel.options.frames[i]:SetHeight(sel.options.height_ea)
		sel.options.frames[i].value = 0
		sel.options.frames[i]:SetScript("OnClick", function (option)
			Checkout_ChooseGPOption(option)
		end)

		-- Option highlight
		elem = sel.options.frames[i]:CreateTexture(nil, "HIGHLIGHT")
		elem:SetColorTexture(1, 0.82, 0, 0.2)
		elem:SetAllPoints(sel.options.frames[i])

		-- Option text
		sel.options.frames[i].text = sel.options.frames[i]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		sel.options.frames[i].text:SetPoint("TOPLEFT", 3, -3)
		sel.options.frames[i].text:SetTextColor(1, 1, 1)
		sel.options.frames[i].text:SetPoint("BOTTOMRIGHT", -3, 3)
		sel.options.frames[i].text:SetJustifyH("LEFT")
		sel.options.frames[i].text:SetJustifyV("MIDDLE")
		sel.options.frames[i].text:SetText("Option #" .. i)
	end

	Checkout_Reset()
end

--- Reset the checkout section
function Checkout_Reset()
	selected_gp = nil
	sections.checkout.frame:Hide()
	sections.checkout.gp_select.wrapper:Hide()
end

--- Reposition the checkout section
function Checkout_Reposition()
	dd("Checkout_Reposition")
	sections.checkout.frame:ClearAllPoints()
	local y = sections.header.frame:GetHeight()
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	sections.checkout.frame:SetPoint("TOPLEFT", 0, -1 * y)
	local h = _G.max(
		sections.checkout.min_height,
		sections.players.frame:GetHeight() + sections.actions.frame:GetHeight()
	)
	sections.checkout.frame:SetHeight(h)
end

--- Activate the checkout section
function Checkout_Activate()
	dd("Checkout_Activate")
end

--- Cancel the checkout (go back)
function Checkout_Cancel()
	dd("Checkout_Cancel")
end

--- Confirm the checkout
function Checkout_Confirm()
	dd("Checkout_Confirm")
	dd("player => " .. selected_player)
	dd("item => " .. item_name .. " #" .. selected_item_id)
	dd("gp => " .. selected_gp)
	Item_Clear()
end

--- Update the GP dropdown
function Checkout_UpdateGPDropdown()
	dd("Checkout_UpdateGPDropdown")

	local sel = sections.checkout.gp_select

	local i = 1
	for key, option in _G.pairs(gp_options) do
		sel.options.frames[i].value = option.price
		sel.options.frames[i].text:SetText(option.text)
		sel.options.frames[i]:Show()
		i = i + 1
	end

	sel.options.frames[i].value = 0
	sel.options.frames[i].text:SetText("Custom")
	sel.options.frames[i]:Show()

	sel.wrapper:SetHeight(i * sel.options.height_ea)
	sel.dropdown.Text:SetText(sel.options.frames[1].text:GetText())
	selected_gp = sel.options.frames[1].value

	for j = i + 1, sel.options.max do
		sel.options.frames[j]:Hide()
	end
end

--- When the user clicks on the GP dropdown
function Checkout_ShowGPOptions()
	dd("Checkout_ShowGPOptions")
	sections.checkout.gp_select.wrapper:Show()
end

--- When an option is selected on the GP dropdown
-- @param option <Frame>
function Checkout_ChooseGPOption(option)
	dd("Checkout_ChooseGPOption")
	sections.checkout.gp_select.wrapper:Hide()
	sections.checkout.gp_select.dropdown.Text:SetText(option.text:GetText())
	if option.value <= 0 then
		Checkout_ShowCustomGPInput()
		selected_gp = 0
	else
		Checkout_HideCustomGPInput()
		selected_gp = option.value
	end
end

function Checkout_ShowCustomGPInput()
	dd("Checkout_ShowCustomGPInput")
end

function Checkout_HideCustomGPInput()
	dd("Checkout_HideCustomGPInput")
end

-------
-- Menu
-------

--- This function is called every time the context menu is opened
-- @param frame <Frame>
-- @param level <number>
-- @param menulist
function Menu_Create(frame, level, menulist)
	dd("Menu_Create")
	local GetMenuButton = addon.Util.GetMenuButton

	local button = GetMenuButton()
	button.text = "Open Options"
	button.func = function ()
		_G.InterfaceOptionsFrame_OpenToCategory(addon.Options.panel)
		_G.InterfaceOptionsFrame_OpenToCategory(addon.Options.panel)
	end
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	button.disabled = true
	_G.UIDropDownMenu_AddButton(button)

	if window and selected_item_id then
		button = GetMenuButton()
		button.text = "Item Options"
		button.isTitle = true
		_G.UIDropDownMenu_AddButton(button)

		button = GetMenuButton()
		button.text = "Announce Item"
		button.noClickSound = true
		button.func = function ()
			Item_Announce()
		end
		_G.UIDropDownMenu_AddButton(button)

		button = GetMenuButton()
		button.text = "Clear Item"
		button.noClickSound = true
		button.func = function ()
			Item_Clear()
		end
		_G.UIDropDownMenu_AddButton(button)

		button = GetMenuButton()
		button.disabled = true
		_G.UIDropDownMenu_AddButton(button)
	end

	button = GetMenuButton()
	button.text = "Window Options"
	button.isTitle = true
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	button.text = "Close Window"
	button.func = function ()
		Window_Close()
	end
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	if addon.Config.GetOption("ItemDistribute.lock") then
		button.text = "Unlock Window"
		button.func = function ()
			addon.Config.SetOption("ItemDistribute.lock", false)
			Window_Unlock()
		end
	else
		button.text = "Lock Window"
		button.func = function ()
			addon.Config.SetOption("ItemDistribute.lock", true)
			Window_Lock()
		end
	end
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	button.disabled = true
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	button.text = "Cancel"
	_G.UIDropDownMenu_AddButton(button)
end

--- Toggle the context menu (right click)
function Menu_Toggle()
	dd("Menu_Toggle")
	_G.PlaySound(_G.SOUNDKIT.IG_MAINMENU_OPEN)
	_G.ToggleDropDownMenu(1, nil, menu, "cursor", 3, -3, nil, nil, 2)
end

---------
-- Window
---------

--- Hook window events
-- For when we receive a whisper for "need"
-- @param window <Frame>
-- @param event <string>
-- @param arg1 <string> message
-- @param arg2 <string> author
function Window_OnEvent(window, event, arg1, arg2)
	if event == "CHAT_MSG_WHISPER" then
		dd("Window_OnEvent CHAT_MSG_WHISPER")
		local msg = arg1
		local author = arg2
		local s, e = _G.string.find(msg, "need")
		if s ~= nil then
			Players_Need(author)
		end
	end
end

--- When clicking the window
-- @param window <Frame>
-- @param button <string> the mouse button that was pressed
function Window_OnMouseUp(window, button)
	dd("Window_OnMouseUp " .. button)
	if button == "LeftButton" then
		-- Occurs when the player drops the item onto the window
		local info_type, item_id, item_link = _G.GetCursorInfo()
		if info_type == nil or info_type ~= "item" then
			return
		end

		-- Return held item to where it came from
		_G.ClearCursor()

		Item_Set(item_id)
	elseif button == "RightButton" then
		Menu_Toggle()
	end
end

--- Resize the window
function Window_Resize()
	dd("Window_Resize")
	local h = sections.header.height
	if sections.details.frame:IsVisible() then
		h = h + sections.details.frame:GetHeight()
	end
	if sections.players.frame:IsVisible() then
		h = h + sections.players.frame:GetHeight()
	end
	if sections.actions.frame:IsVisible() then
		h = h + sections.actions.frame:GetHeight()
	end
	if sections.checkout.frame:IsVisible() then
		h = h + sections.checkout.frame:GetHeight()
	end
	window:SetHeight(h)
end

--- Unlock the window
-- Enable dragging and bind to drag events
function Window_Unlock()
	dd("Window_Unlock")
	window:SetMovable(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", Window_OnDragStart)
	window:SetScript("OnDragStop", Window_OnDragStop)
end

--- When starting window drag
function Window_OnDragStart()
	dd("Window_OnDragStart")
	window:StartMoving()
end

--- When stopping window drag
function Window_OnDragStop()
	dd("Window_OnDragStop")

	local _, _, _, x, y = window:GetPoint()

	-- Clamp top left
	x = _G.max(x, 0)
	y = _G.min(y, 0)

	-- Clamp bottom right
	x = _G.min(x, _G.GetScreenWidth() - window:GetWidth())
	y = _G.max(y, -1 * _G.GetScreenHeight() + window:GetHeight())

	-- Save position
	addon.Config.SetOption("ItemDistribute.x", x)
	addon.Config.SetOption("ItemDistribute.y", y)

	-- Set position
	window:StopMovingOrSizing()
	window:ClearAllPoints()
	window:SetPoint("TOPLEFT", x, y)
end

--- Lock the window
-- Disable dragging events and set unmovable
function Window_Lock()
	dd("Window_Lock")
	window:SetMovable(false)
	window:RegisterForDrag(nil)
	window:SetScript("OnDragStart", nil)
	window:SetScript("OnDragStop", nil)
end

--- Toggle display of the window
function Window_Toggle()
	dd("Window_Toggle")
	if window:IsVisible() then
		Window_Close()
	else
		Window_Open()
	end
end

--- Close the window
function Window_Close()
	dd("Window_Close")
	_G.PlaySound(_G.SOUNDKIT.IG_MAINMENU_CLOSE)
	window:Hide()
	Item_Clear(false)
end

--- Open the window
function Window_Open()
	dd("Window_Open")
	_G.PlaySound(_G.SOUNDKIT.IG_MAINMENU_OPEN)
	window:Show()
end
