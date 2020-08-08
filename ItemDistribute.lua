local _, addon = ...

-- Set up module
local M = {}
addon.ItemDistribute = M
local _G = _G
setfenv(1, M)

-- Step 1 - Blank: Window is empty and ready.

-- Step 2 - Ready: Item is placed in the window.
--  Update the header with the item name and icon
--  Show the details section if the item has tier or pricing info
--  Show the players section with an empty players table
--  Show the actions section

-- Step 3 - Distribute: User clicks on a player and then clicks "distribute"
--  Hide the details section
--  Hide the players section
--  Hide the actions section
--  Show the checkout section

-- Window
window = nil -- <Frame>
window_width = 200 -- <number>

-- Step
step = 0

-- Menu
menu = nil -- <Frame>

-- Selected
selected_item_id = nil -- <number>
selected_player_name = nil -- <string>
selected_gp = 0 -- <number>

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
		max_visible = 6, -- <number> (including th)
		offset = 0, -- <number>
		up = nil, -- <Frame>
		down = nil, -- <Frame>
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
		custom_gp = nil, -- <EditBox>
	},
}

--- Load this module
function Load()
	-- Window
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
	window:SetScript("OnMouseWheel", Window_OnMouseWheel)

	--- Hook item link to put into our addon
	-- Normal usage is shift+left click
	local orig_ChatEdit_InsertLink = _G.ChatEdit_InsertLink
	_G.ChatEdit_InsertLink = function (...)
		local text = ...
		local result = orig_ChatEdit_InsertLink(...)
		if not result and text and window:IsVisible() then
			Step2_Activate(addon.Util.GetItemIdFromItemLink(text))
			addon.Util.PlaySoundItemDrop()
		end
		return false
	end

	-- Menu
	menu = _G.CreateFrame("Frame", nil, _G.UIParent, "UIDropDownMenuTemplate")
	menu:SetPoint("CENTER")
	_G.UIDropDownMenu_Initialize(menu, Menu_Create, "MENU")

	-- Load sections
	Header_Load()
	Details_Load()
	Players_Load()
	Actions_Load()
	Checkout_Load()
	Window_Resize()

	-- debug
	Step2_Activate(153)
	Players_Add("Clockberg-Bigglesworth")
	Players_Add("Thinkz-Bigglesworth")
	Players_Add("Dudebank-Bigglesworth")
	Players_Add("Dudeherbs-Bigglesworth")
	Players_Select(sections.players.frames[1])
	Step3_Activate()
end

--- Activate step 1
-- @param play_sound <boolean>
function Step1_Activate(play_sound)
	selected_item_id = nil
	selected_player_name = nil
	Checkout_SetSelectedGP(0)
	gp_options = {}

	Header_Reset()
	Details_Deactivate()
	Players_Deactivate()
	Actions_Deactivate()
	Checkout_Deactivate()
	Window_Resize()

	if play_sound == nil or play_sound then
		addon.Util.PlaySoundItemDrop()
	end

	step = 1
end

--- Activate step 2
-- @param item_id <number>
function Step2_Activate(item_id)
	if not item_id then
		return
	end

	-- Set the selected item
	local item_name, item_link, _, _, _, _, _, _ = _G.GetItemInfo(item_id)
	selected_item_id = item_id
	selected_player_name = nil

	-- Load the item GP data
	Item_LoadGP()

	-- Update the sections
	Header_SetItem(item_id, item_link)
	Details_Activate(item_id)
	Players_Deactivate()
	Players_Activate()
	Actions_Activate()
	Checkout_Deactivate()
	Checkout_UpdateGPDropdown()
	Window_Resize()

	Item_Announce()

	step = 2
end

--- Activate step 3
function Step3_Activate()
	sections.players.frame:Hide()
	sections.actions.frame:Hide()
	Checkout_Activate()
	Window_Resize()
	Checkout_RefreshSelectedGP()

	step = 3
end

--- Back from step 3 to step 2
function Step3_Back()
	Details_Activate(selected_item_id)
	Players_Activate()
	Actions_Activate()
	Checkout_Deactivate()
	Window_Resize()

	step = 2
end

---------
-- Header
---------

function Header_Load()
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
	sections.header.title:SetText(addon.short_name)
	sections.header.icon:SetTexture(nil)
end

--- Sets the item for the header section
-- @param item_id <number>
-- @param item_link <string>
function Header_SetItem(item_id, item_link)
	sections.header.icon:SetTexture(_G.GetItemIcon(item_id))
	sections.header.title:SetText(item_link)
end

----------
-- Details
----------

--- Load the details section
function Details_Load()
	sections.details.frame = _G.CreateFrame("Frame", nil, window)
	sections.details.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.details.frame:SetWidth(window_width)

	sections.details.item_details_component = addon.ItemDetailsComponent.Create(sections.details.frame)
	sections.details.item_details_component.frame:SetPoint("TOPLEFT", 5, 0)

	Details_Deactivate()
end

--- Deactivate the details section
function Details_Deactivate()
	sections.details.frame:Hide()
end

--- Update the details section with the given item ID
-- @param item_id <number>
function Details_Activate(item_id)
	sections.details.item_details_component:UpdateItem(item_id)
	local h = sections.details.item_details_component.frame:GetHeight()
	sections.details.frame:SetHeight(h)
	if h >= 1 then
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
	-- Create the players frame
	sections.players.frame = _G.CreateFrame("Frame", nil, window)
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.players.frame:SetWidth(window_width)
	sections.players.frame:SetHeight(sections.players.height_ea)

	-- "Player" table header
	local elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 10, 0)
	elem:SetJustifyH("LEFT")
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("Player")

	-- "EP" table header
	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 90, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("EP")

	-- "GP" table header
	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 122, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(35)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("GP")

	-- "PR" table header
	elem = sections.players.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPRIGHT", -3, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(38)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("PR")

	-- up arrow
	sections.players.up = sections.players.frame:CreateTexture(nil, "ARTWORK")
	sections.players.up:SetPoint("TOPLEFT", 3, -12)
	sections.players.up:SetWidth(10)
	sections.players.up:SetHeight(15)

	-- down arrow
	sections.players.down = sections.players.frame:CreateTexture(nil, "ARTWORK")
	sections.players.down:SetPoint("BOTTOMLEFT", 3, -5)
	sections.players.down:SetWidth(10)
	sections.players.down:SetHeight(15)

	Players_Deactivate()
end

--- Deactivate the players section
function Players_Deactivate()
	Players_Deselect()

	-- Hide player rows
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i]:Hide()
	end

	-- Reset players
	sections.players.index = 1
	sections.players.frame:Hide()
	sections.players.offset = 0
	Players_MoreUp(0)
	Players_MoreDown(0)
end

--- Resize and reposition the players section
function Players_Restage()
	sections.players.frame:ClearAllPoints()
	local y = sections.header.frame:GetHeight()
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * y)

	local h = sections.players.height_ea * _G.min(sections.players.max_visible, sections.players.index)
	sections.players.frame:SetHeight(h)
end

--- Activate the players section
function Players_Activate()
	Players_Restage()
	sections.players.frame:Show()
end

--- Announces the selected item
-- @param player_name <string>
-- @param class <string>
-- @param pr <number>
function Players_Announce(player_name, class, pr)
	addon.Util.ChatRaid(player_name .. " (" .. _G.string.lower(class) .. ")" .. " needs ( " .. pr .. " pr )")
end

--- Returns true if the player is already on the list
-- @param player_name <string>
-- @return <boolean>
function Players_IsOnList(player_name)
	local found = false
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		if i < sections.players.index and sections.players.frames[i] ~= nil and sections.players.frames[i].player_name == player_name then
			found = true
		end
	end
	return found
end

--- Adds a new player frame to the list
-- @return <Frame>
function Players_NewFrame()
	-- Frame
	local frame = _G.CreateFrame("Frame", nil, sections.players.frame)
	sections.players.frames[sections.players.index] = frame

	-- Frame vars
	frame.player_name = nil
	frame.pr = nil
	frame.index = sections.players.index

	-- Frame settings
	frame:EnableMouse(true)
	frame:SetPoint("TOPLEFT", 2, 0)
	frame:SetWidth(window_width - 6)
	frame:SetHeight(sections.players.height_ea)

	-- Name
	frame.name_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.name_text:SetPoint("TOPLEFT", 10, 0)
	frame.name_text:SetJustifyH("LEFT")
	frame.name_text:SetHeight(sections.players.height_ea)

	-- EP
	frame.ep_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.ep_text:SetPoint("TOPLEFT", 90, 0)
	frame.ep_text:SetJustifyH("RIGHT")
	frame.ep_text:SetWidth(35)
	frame.ep_text:SetHeight(sections.players.height_ea)

	-- GP
	frame.gp_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.gp_text:SetPoint("TOPLEFT", 122, 0)
	frame.gp_text:SetJustifyH("RIGHT")
	frame.gp_text:SetWidth(35)
	frame.gp_text:SetHeight(sections.players.height_ea)

	-- PR
	frame.pr_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.pr_text:SetPoint("TOPRIGHT", -3, 0)
	frame.pr_text:SetJustifyH("RIGHT")
	frame.pr_text:SetWidth(38)
	frame.pr_text:SetHeight(sections.players.height_ea)

	-- Row highlight (automatic on mouseover)
	elem = frame:CreateTexture(nil, "HIGHLIGHT")
	elem:SetColorTexture(1, 0.82, 0, 0.1)
	elem:SetAllPoints(frame)

	-- Row select (hidden until clicked)
	frame.select = frame:CreateTexture(nil, "ARTWORK")
	frame.select:SetColorTexture(1, 0.82, 0, 0.3)
	frame.select:SetAllPoints(frame)
	frame.select:Hide()

	-- Bind to click event
	frame:SetScript('OnMouseUp', Players_Select)

	return frame
end

--- Select the clicked player row
-- @param frame <Frame> the clicked player row frame
function Players_Select(frame)
	Players_Deselect()
	selected_player_name = frame.name_text:GetText()
	frame.select:Show()
	sections.checkout.player_text:SetTextColor(frame.name_text:GetTextColor())
	sections.checkout.player_text:SetText(frame.name_text:GetText())
	Actions_EnableDistributeButton()
	addon.Util.PlaySoundNext()
end

--- Deselect all players rows
function Players_Deselect()
	selected_player_name = nil
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i].select:Hide()
	end
	if sections.checkout.player_text then
		sections.checkout.player_text:SetText(nil)
	end
	Actions_DisableDistributeButton()
end

--- A player needs the selected item
-- @param player_fullname <string>
function Players_Add(player_fullname)
	-- Must be on step 2
	if step ~= 2 or not window:IsVisible() then
		return
	end

	-- Player must exist in the guild data
	local player_data = addon.Guild.GetPlayerData(player_fullname)
	if player_data == nil then
		addon.Core.Warning("Need disregarded for player '" .. player_fullname .. "'. Guild data not found.")
		return
	end

	local player_name = addon.Util.RemoveServerFromPlayerName(player_fullname)

	-- See if the player is already on the list
	if Players_IsOnList(player_name) then
		--return
	end

	local frame = sections.players.frames[sections.players.index]
	if frame == nil then
		frame = Players_NewFrame()
	end
	sections.players.index = sections.players.index + 1

	-- Get player EP and GP
	local epgp = addon.Guild.DecodeOfficerNote(player_data.officer_note)

	epgp.ep = _G.math.random(1,100) -- debug

	frame.pr = addon.Util.GetPR(epgp.ep, epgp.gp)
	frame.player_name = player_name

	-- Set class color
	if player_data.class == "SHAMAN" then
		-- Override shaman color to blue
		-- #0070DE
		frame.name_text:SetTextColor(0, 0.4375, 0.8706)
	else
		frame.name_text:SetTextColor(_G.GetClassColor(player_data.class))
	end

	-- Set this row text
	frame.name_text:SetText(player_name)
	frame.ep_text:SetText(epgp.ep)
	frame.gp_text:SetText(epgp.gp)
	frame.pr_text:SetText(_G.string.format("%.2f", frame.pr))
	frame:Show()

	Players_Sort()
	Players_Restage()
	Actions_Restage()
	Checkout_Restage()
	Window_Resize()
	Players_Announce(player_name, player_data.class, frame.pr)
end

--- Sorts the players list by PR
function Players_Sort()
	local tmp = {}
	for i = 1, (sections.players.index - 1) do
		_G.table.insert(tmp, sections.players.frames[i])
	end
	_G.table.sort(tmp, function(t1, t2)
		if t1.pr == t2.pr then
			return t1.player_name > t2.player_name
		end
		return t1.pr > t2.pr
	end)
	sections.players.frames = {}
	for i = 1, addon.Util.SizeOf(tmp) do
		sections.players.frames[i] = tmp[i]
	end
	Players_Reposition()
end

--- Repositions the players list based on the offset
function Players_Reposition()
	local offset = sections.players.offset
	for i = 1, (sections.players.index - 1) do
		if i <= offset then
			sections.players.frames[i]:Hide()
		elseif i > offset + sections.players.max_visible - 1 then
			sections.players.frames[i]:Hide()
		else
			sections.players.frames[i]:Show()
			local row = i - offset
			sections.players.frames[i]:SetPoint("TOPLEFT", 2, -1 * sections.players.height_ea * row)
		end
	end
	if offset > 0 then
		Players_MoreUp(1)
	elseif sections.players.index >= sections.players.max_visible then
		Players_MoreUp(-1)
	else
		Players_MoreUp(0)
	end
	if sections.players.index > offset + sections.players.max_visible then
		Players_MoreDown(1)
	elseif sections.players.index >= sections.players.max_visible then
		Players_MoreDown(-1)
	else
		Players_MoreDown(0)
	end
end

--- Sets the arrow texture if there are more players up the list
-- @param flag <number> 1 if enable, 0 if hide, -1 if disable
function Players_MoreUp(flag)
	if flag == 1 then
		sections.players.up:SetTexture("Interface\\Buttons\\Arrow-Up-Up.PNG")
		sections.players.up:Show()
	elseif flag == -1 then
		sections.players.up:SetTexture("Interface\\Buttons\\Arrow-Up-Disabled.PNG")
		sections.players.up:Show()
	else
		sections.players.up:Hide()
	end
end

--- Sets the arrow texture if there are more players down the list
-- @param flag <number> 1 if enable, 0 if hide, -1 if disable
function Players_MoreDown(flag)
	if flag == 1 then
		sections.players.down:SetTexture("Interface\\Buttons\\Arrow-Down-Up.PNG")
		sections.players.down:Show()
	elseif flag == -1 then
		sections.players.down:SetTexture("Interface\\Buttons\\Arrow-Down-Disabled.PNG")
		sections.players.down:Show()
	else
		sections.players.down:Hide()
	end
end

----------
-- Actions
----------

--- Load the actions section
function Actions_Load()
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
		addon.Util.PlaySoundClose()
		Step1_Activate()
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
		addon.Util.PlaySoundNext()
		Step3_Activate()
	end)
	sections.actions.btn_dist_text = sections.actions.btn_dist:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sections.actions.btn_dist_text:SetPoint("TOPLEFT", 5, 0)
	sections.actions.btn_dist_text:SetPoint("TOPRIGHT", -5, 0)
	sections.actions.btn_dist_text:SetJustifyH("CENTER")
	sections.actions.btn_dist_text:SetHeight(18)
	sections.actions.btn_dist_text:SetText("Distribute")

	Actions_Deactivate()
end

--- Deactivate the actions section
function Actions_Deactivate()
	sections.actions.frame:Hide()
	Actions_DisableDistributeButton()
end

--- Resize and reposition the actions section
function Actions_Restage()
	local y = sections.header.height
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	y = y + sections.players.frame:GetHeight()
	sections.actions.frame:SetPoint("TOPLEFT", 0, -1 * y)
end

--- Activate the actions section
function Actions_Activate()
	Actions_Restage()
	sections.actions.frame:Show()
end

--- Disable the distribute button
function Actions_DisableDistributeButton()
	if sections.actions.btn_dist then
		sections.actions.btn_dist:Disable()
		sections.actions.btn_dist_text:SetTextColor(1, 1, 1, 0.5)
	end
end

--- Enable the distribute button
function Actions_EnableDistributeButton()
	sections.actions.btn_dist:Enable()
	sections.actions.btn_dist_text:SetTextColor(1, 0.82, 0)
end

-----------
-- Checkout
-----------

--- Load the checkout section
function Checkout_Load()
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
		addon.Util.PlaySoundBack()
		Step3_Back()
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
	sections.checkout.player_text = sections.checkout.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sections.checkout.player_text:SetPoint("TOPLEFT", 73, -3)
	sections.checkout.player_text:SetJustifyH("LEFT")

	-- "For.." text
	elem = sections.checkout.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -23)
	elem:SetJustifyH("LEFT")
	elem:SetText("For: ")

	-- GP select dropdown
	local sel = sections.checkout.gp_select
	sel.options.max = addon.Util.SizeOf(addon.data.tiers) + 2
	sel.dropdown = _G.CreateFrame("FRAME", nil, sections.checkout.frame, "OptionsDropdownTemplate")
	sel.dropdown:SetPoint("TOPLEFT", 10, -15)
	sel.dropdown.Text:SetText("N/A")
	sel.dropdown.Middle:SetWidth(65)
	sel.dropdown.Button:SetScript("OnClick", function (_, button)
		Checkout_ToggleGPOptions()
		addon.Util.PlaySoundBack()
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

	-- Custom GP Input
	sections.checkout.custom_gp = _G.CreateFrame("EditBox", nil, sections.checkout.frame, "InputBoxTemplate")
	sections.checkout.custom_gp:SetPoint("TOPRIGHT", -10, -16)
	sections.checkout.custom_gp:SetAutoFocus(false)
	sections.checkout.custom_gp:SetMaxLetters(5)
	sections.checkout.custom_gp:SetHeight(24)
	sections.checkout.custom_gp:SetWidth(55)
	sections.checkout.custom_gp:SetScript("OnEscapePressed", function()
		sections.checkout.custom_gp:ClearFocus()
	end)
	sections.checkout.custom_gp:SetScript("OnTextChanged", function()
		local val = sections.checkout.custom_gp:GetText()
		Checkout_SetSelectedGP(val)
	end)

	Checkout_Deactivate()
end

--- Deactivate the checkout section
function Checkout_Deactivate()
	Checkout_SetSelectedGP(0)
	sections.checkout.frame:Hide()
	sections.checkout.gp_select.wrapper:Hide()
end

--- Resize and reposition the checkout section
function Checkout_Restage()
	-- Reposition
	sections.checkout.frame:ClearAllPoints()
	local y = sections.header.frame:GetHeight()
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	sections.checkout.frame:SetPoint("TOPLEFT", 0, -1 * y)

	-- Resize
	local h = _G.max(
		sections.checkout.min_height,
		sections.players.frame:GetHeight() + sections.actions.frame:GetHeight()
	)
	sections.checkout.frame:SetHeight(h)
end

--- Activate the checkout section
function Checkout_Activate()
	Checkout_Restage()
	sections.checkout.frame:Show()
end

--- Confirm the checkout
function Checkout_Confirm()
	addon.Core.Transact(selected_player_name, selected_item_id, selected_gp, false, "Item Distribute", true, true)
	Step1_Activate()
end

--- Update the GP dropdown
function Checkout_UpdateGPDropdown()
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
	sel.dropdown.value = sel.options.frames[1].value

	Checkout_SetSelectedGP(sel.options.frames[1].value)

	for j = i + 1, sel.options.max do
		sel.options.frames[j]:Hide()
	end
end

--- When the user clicks on the GP dropdown
function Checkout_ToggleGPOptions()
	if sections.checkout.gp_select.wrapper:IsVisible() then
		sections.checkout.gp_select.wrapper:Hide()
	else
		sections.checkout.gp_select.wrapper:Show()
	end
end

--- When an option is selected on the GP dropdown
-- @param option <Frame>
function Checkout_ChooseGPOption(option)
	sections.checkout.gp_select.wrapper:Hide()
	sections.checkout.gp_select.dropdown.Text:SetText(option.text:GetText())
	sections.checkout.gp_select.dropdown.value = option.value
	if option.value <= 0 then
		Checkout_ShowCustomGPInput()
	else
		Checkout_HideCustomGPInput()
		Checkout_SetSelectedGP(option.value)
	end
	addon.Util.PlaySoundNext()
end

--- Show the custom GP input
function Checkout_ShowCustomGPInput()
	sections.checkout.custom_gp:Show()
end

--- Hide the custom GP input
function Checkout_HideCustomGPInput()
	sections.checkout.custom_gp:Hide()
end

--- Sets the currently selected GP
-- @param gp <number>
function Checkout_SetSelectedGP(gp)
	gp = addon.Util.WholeNumber(gp)
	selected_gp = gp
end

--- Automatically refresh the selected GP
function Checkout_RefreshSelectedGP()
	if sections.checkout.custom_gp:IsVisible() then
		Checkout_SetSelectedGP(addon.Util.WholeNumber(sections.checkout.custom_gp:GetText()))
	else
		Checkout_SetSelectedGP(sections.checkout.gp_select.dropdown.value)
	end
end

-------
-- Item
-------

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

	sections.checkout.custom_gp:SetText(addon.Config.GetOption("ItemDistribute.default_price"))

	if addon.Util.SizeOf(gp_options) then
		Checkout_HideCustomGPInput()
	else
		Checkout_ShowCustomGPInput()
	end
end

--- Announces the selected item
function Item_Announce()
	if selected_item_id == nil then
		return
	end

	local _, item_link, _, _, _, _, _, _ = _G.GetItemInfo(selected_item_id)
	local msg = "Now Distributing: " .. item_link
	if addon.Config.GetOption("ItemDistribute.announce_raid_warning") then
		addon.Util.ChatRaidWarning(msg)
	else
		addon.Util.ChatRaid(msg)
	end
	local item_data = addon.data.items[selected_item_id]
	local total = 0
	if item_data ~= nil then
		local tiers = addon.Util.TableGetKeys(item_data.by_tier)
		_G.table.sort(tiers)
		for _, tier in _G.pairs(tiers) do
			tier_data = item_data.by_tier[tier]
			local str = " ( " .. addon.data.tiers[tier] .. ": " .. tier_data.price .. "gp ) "
			local specs_as_keys = addon.Util.TableFlip(tier_data.specs)
			local count = 0
			for i, spec in _G.pairs(addon.data.specs) do
				if specs_as_keys[spec] ~= nil then
					if count > 0 then
						str = str .. ", "
					end
					count = count + 1
					str = str .. addon.data.spec_abbrs[spec]
				end
			end
			addon.Util.ChatRaid(str)
			total = total + 1
		end
		if item_data.price then
			addon.Util.ChatRaid(" ( *: " .. item_data.price .. "gp )")
		end
	end
	if total == 0 then
		addon.Util.ChatRaid("No prices set")
	end
	addon.Util.ChatRaid("DM \"need\" to " .. _G.UnitName("player"))
end

-------
-- Menu
-------

--- This function is called every time the context menu is opened
-- @param frame <Frame>
-- @param level <number>
-- @param menulist
function Menu_Create(frame, level, menulist)
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
			Step1_Activate()
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
	addon.Util.PlaySoundOpen()
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
		local msg = arg1
		local author = arg2
		local s, e = _G.string.find(msg, "need")
		if s ~= nil then
			Players_Add(author)
		end
	end
end

--- When clicking the window
-- @param window <Frame>
-- @param button <string> the mouse button that was pressed
function Window_OnMouseUp(window, button)
	if button == "LeftButton" then
		-- Occurs when the player drops the item onto the window
		local info_type, item_id, item_link = _G.GetCursorInfo()
		if info_type == nil or info_type ~= "item" then
			return
		end

		-- Return held item to where it came from
		_G.ClearCursor()

		Step2_Activate(item_id)
	elseif button == "RightButton" then
		Menu_Toggle()
	end
end

--- When scrolling the window
-- @param window <Frame>
-- @param dir <number> 1 for up, -1 for down
function Window_OnMouseWheel(window, dir)
	if step == 2 then
		local min = 0
		local max = sections.players.index - sections.players.max_visible
		local diff = -1 * dir
		local new_offset = sections.players.offset + diff
		sections.players.offset = _G.max(min, _G.min(max, new_offset))
		Players_Reposition()
	end
end

--- Resize the window
function Window_Resize()
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
	window:SetMovable(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", Window_OnDragStart)
	window:SetScript("OnDragStop", Window_OnDragStop)
end

--- When starting window drag
function Window_OnDragStart()
	window:StartMoving()
end

--- When stopping window drag
function Window_OnDragStop()
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
	window:SetMovable(false)
	window:RegisterForDrag(nil)
	window:SetScript("OnDragStart", nil)
	window:SetScript("OnDragStop", nil)
end

--- Toggle display of the window
function Window_Toggle()
	if window:IsVisible() then
		Window_Close()
	else
		Window_Open()
	end
end

--- Close the window
function Window_Close()
	addon.Util.PlaySoundClose()
	window:Hide()
	Step1_Activate(false)
end

--- Open the window
function Window_Open()
	addon.Util.PlaySoundOpen()
	window:Show()
	Step1_Activate(false)
end
