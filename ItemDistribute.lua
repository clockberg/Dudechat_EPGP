local _, addon = ...

-- Set up module
local M = {}
addon.ItemDistribute = M
local _G = _G
setfenv(1, M)

-- Step 1 - Blank: Window is empty and ready.
--  Can be in a minimized or maximized state
--  Can only accept items in the maximized state

-- Step 2 - Cart: Item is placed in the window.
--  Update the header with the item name and icon
--  Show the details section with the item tier and pricing info
--  Show the players section with an empty players table
--  Show the actions section

-- Step 3 - Checkout: User clicks on a player and then clicks "distribute"
--  Hide the details section
--  Hide the players section
--  Hide the actions section
--  Show the checkout section

-- Current Step
cur_step = 0

-- Selected Player
selected_player = {
	name = nil, -- <string>
	class = nil, -- <string>
	spec = nil, -- <string>
}

-- Current Item
current_item = {
	id = nil, -- <string>
	gp_options = {}, -- <table array of table>
	-- e.g. [{ "tiernum" = <number>, "text" = <string>, "price" = <number> }, ..]
	spec_to_tiernum = {}, -- <table map spec <string> to tiernum <number>>
	-- e.g. { "PROT_WAR" = <number>, "RESTO_SHAM" = <number>, .. }
}

-- GP that will be transacted
gp_cost = 0 -- <number>

-- Sections data
sections = {
	menu = {
		frame = nil, -- <Frame>
	},
	window = {
		frame = nil, -- <Frame>
		width = 310, -- <number>
		width_minimized = 100, -- <number>
		is_minimized = false -- <boolean>
	},
	spec_prompt = {
		frame = nil, -- <Frame>
		player_name = nil, -- <FontString>
		buttons = {
			[1] = nil, -- <Frame>
			[2] = nil, -- <Frame>
			[3] = nil, -- <Frame>
			[4] = nil, -- <Frame>
		},
		button_height_ea = 15, -- <number>
		buttons_offset = 0, -- <number>
	},
	header = {
		frame = nil, -- <Frame>
		title = nil, -- <FontString>
		subtitle = nil, -- <FontString>
		slot = nil, -- <Texture>
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
		frames = {}, -- <table array of <Frame>>
		max_visible = 6, -- <number> (including th)
		offset = 0, -- <number>
		up = nil, -- <Frame>
		down = nil, -- <Frame>
		spec_icon_size = 14, -- <number>
		col_widths = {
			player = 60,
			ep = 40,
			gp = 40,
			pr = 40,
			spec = 28,
			mult = 30,
			score = 50,
		}
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
	history = {
		frame = nil, -- <Frame>
		frames = {}, -- <table array of <Frame>>
		height_ea = 12, -- <number>
		index = 1, -- <number>
	},
}

--- Load this module
function Load()
	Window_Create()

	-- Bind window to whisper events
	sections.window.frame:RegisterEvent("CHAT_MSG_WHISPER")
	sections.window.frame:SetScript("OnEvent", Window_OnEvent)

	-- Set initial lock state
	if addon.Config.GetOption("ItemDistribute.lock") then
		Window_Lock()
	else
		Window_Unlock()
	end

	-- Bind to mouse events
	sections.window.frame:SetScript("OnMouseUp", Window_OnMouseUp)
	sections.window.frame:SetScript("OnMouseWheel", Window_OnMouseWheel)

	HookItemLink()

	Menu_Create()
	Header_Create()
	Details_Create()
	Players_Create()
	Actions_Create()
	Checkout_Create()
	History_Create()
	SpecPrompt_Create()

	Window_Resize()
	Window_Hide()
	Window_Minimize()
end

--- Hook shift+click item from loot frame so that it appears in our window
function HookItemLink()
	-- Save reference to original func
	local orig_ChatEdit_InsertLink = _G.ChatEdit_InsertLink

	-- Override func
	_G.ChatEdit_InsertLink = function (...)
		local text = ...
		-- Call the original func
		local result = orig_ChatEdit_InsertLink(...)
		if result then
			-- A successful result means achat link was inserted - that was probably the
			-- desired action, so don't do anything
			return result
		end
		if not text then
			-- No text in the item link, nothing to do
			return false
		end

		-- Check for looting
		local loot_info = _G.GetLootInfo()
		if not loot_info or addon.Util.SizeOf(loot_info) == 0 then
			-- We are not looting
			return false
		end

		-- Make sure window is in the right state to receive an item
		if not Window_IsReady() then
			return false
		end

		local item_id = addon.Util.GetItemIdFromItemLink(text)
		if not item_id then
			-- No item found from link text
			return false
		end

		-- Show the item in our window and transition to the "cart" step
		Transition_to2(item_id)
		addon.Util.PlaySoundItemDrop()

		return false
	end
end

--- Transition to step 1 - "Blank"
-- @param play_sound <boolean> default true
function Transition_to1(play_sound)
	Players_ResetSelection()
	Item_Reset()

	Checkout_SetGPCost(0)

	Header_Transition_to1()
	Details_Transition_to1()
	Players_Transition_to1()
	Actions_Transition_to1()
	Checkout_Hide()
	History_Restage()
	Window_Resize()
	SpecPrompt_Hide()

	if play_sound == nil or play_sound then
		addon.Util.PlaySoundItemDrop()
	end

	cur_step = 1
end

--- Transition to step 2
-- @param item_id <number>
function Transition_to2(item_id)
	if not item_id then
		return
	end

	-- Reset the selected player
	Players_ResetSelection()

	-- Set the current item
	local item_name, item_link = _G.GetItemInfo(item_id)
	current_item.id = item_id
	Item_LoadGP()

	-- Update the sections
	Header_Transition_to2(item_id, item_link)
	Details_Transition_to2(item_id)
	Players_Transition_to2()
	Actions_Show()
	Checkout_Hide()
	Checkout_UpdateGPDropdown()
	History_Restage()
	Window_Resize()
	SpecPrompt_Hide()

	-- Announce item
	Item_Announce()

	cur_step = 2
end

--- Transition from step 2 to 3
function Transition_2to3()
	sections.actions.frame:Hide()
	Players_Transition_to3()
	Checkout_Show()
	History_Restage()
	Window_Resize()
	Checkout_UpdateGPSelection()
	Checkout_RefreshSelectedGP()
	SpecPrompt_Hide()
	cur_step = 3
end

--- Back from step 3 to step 2
function Transition_3to2()
	Details_Transition_to2(current_item.id)
	Players_Transition_3to2()
	Actions_Show()
	Checkout_Hide()
	History_Restage()
	Window_Resize()
	SpecPrompt_Hide()
	cur_step = 2
end

---------
-- Header
---------

--- Create and init the header section
function Header_Create()
	-- Header frame
	sections.header.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.header.frame:SetPoint("TOPLEFT", 0, 0)
	sections.header.frame:SetWidth(sections.window.width)
	sections.header.frame:SetHeight(sections.header.height)

	-- Title
	sections.header.title = sections.header.frame:CreateFontString(nil, nil, "GameFontNormal")
	sections.header.title:SetJustifyH("LEFT")
	sections.header.title:SetJustifyV("TOP")
	sections.header.title:SetPoint("BOTTOMRIGHT", -3, 17)

	-- Subtitle
	sections.header.subtitle = sections.header.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	sections.header.subtitle:SetJustifyH("LEFT")
	sections.header.subtitle:SetTextColor(1, 1, 1)
	sections.header.subtitle:SetHeight(25)

	-- Item bag slot
	sections.header.slot = sections.header.frame:CreateTexture(nil, "BACKGROUND")
	sections.header.slot:SetPoint("TOPLEFT", 1, -2)
	sections.header.slot:SetHeight(51)
	sections.header.slot:SetWidth(51)
	sections.header.slot:SetTexture("Interface\\Buttons\\UI-Slot-Background.PNG")

	-- Item texture slot
	sections.header.icon = sections.header.frame:CreateTexture(nil, "ARTWORK")
	sections.header.icon:SetPoint("TOPLEFT", 1, -1)
	sections.header.icon:SetHeight(33)
	sections.header.icon:SetWidth(33)

	-- Init
	Header_SetMaximized()
	Header_Transition_to1()
end

--- Set the header to the maximized state
function Header_SetMaximized()
	sections.header.title:SetPoint("TOPLEFT", 35, -6)
	sections.header.subtitle:SetPoint("TOPLEFT", 37, -14.5)
	sections.header.subtitle:SetText("Item Distribution")
	sections.header.frame:SetWidth(sections.window.width)
	sections.header.slot:Show()
end

--- Set the header to the minimized state
function Header_SetMinimized()
	sections.header.title:SetPoint("TOPLEFT", 5, -6)
	sections.header.subtitle:SetPoint("TOPLEFT", 4, -14.5)
	sections.header.subtitle:SetText("Active (minimized)")
	sections.header.frame:SetWidth(sections.window.width_minimized)
	sections.header.slot:Hide()
end

--- Transitions the header section to step 1
function Header_Transition_to1()
	sections.header.title:SetText(addon.short_name)
	sections.header.icon:SetTexture(nil)
end

--- Transitions the header section to step 2
-- Sets the item shown
-- @param item_id <number>
-- @param item_link <string>
function Header_Transition_to2(item_id, item_link)
	sections.header.title:SetText(item_link)
	sections.header.icon:SetTexture(_G.GetItemIcon(item_id))
end

----------
-- Details
----------

--- Create and init the details section
function Details_Create()
	-- Details frame
	sections.details.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.details.frame:SetWidth(sections.window.width)

	-- Item component
	sections.details.item_details_component = addon.ItemDetailsComponent.Create(sections.details.frame)
	sections.details.item_details_component.frame:SetPoint("TOPLEFT", 5, 0)
	sections.details.item_details_component.frame:SetScale(0.9)

	Details_Transition_to1()
end

--- Transitions the details section to step 1
function Details_Transition_to1()
	Details_Hide()
end

--- Transitions the details section to step 2
-- Update the details section with the given item ID
-- @param item_id <number>
function Details_Transition_to2(item_id)
	sections.details.item_details_component:UpdateItem(item_id)
	Details_ShowIfItem()
end

--- Resize and reposition the details section
function Details_Restage()
	-- Determine y offset
	sections.details.frame:ClearAllPoints()
	local y = sections.header.frame:GetHeight()
	sections.details.frame:SetPoint("TOPLEFT", 0, -1 * y)

	-- Set frame height based on item details component
	local h = sections.details.item_details_component.frame:GetHeight()
	sections.details.frame:SetHeight(h)
end

function Details_ShowIfItem()
	if sections.details.item_details_component:HasItem() then
		Details_Show()
	else
		Details_Hide()
	end
end

function Details_Show()
	sections.details.frame:Show()
	Details_Restage()
end

function Details_Hide()
	sections.details.frame:Hide()
end

---------
-- Player
---------

--- Create the players section
function Players_Create()
	-- Players frame
	sections.players.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.players.frame:SetWidth(sections.window.width)
	sections.players.frame:SetHeight(sections.players.height_ea)

	local x = 13

	-- "Player" table header
	local elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", 13, 0)
	elem:SetJustifyH("LEFT")
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetWidth(sections.players.col_widths.player)
	elem:SetHeight(sections.players.height_ea)
	elem:SetText("Player")

	x = x + elem:GetWidth()

	-- "EP" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(sections.players.col_widths.ep)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("EP")

	x = x + elem:GetWidth()

	-- "GP" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(sections.players.col_widths.gp)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("GP")

	x = x + elem:GetWidth()

	-- "PR" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(sections.players.col_widths.pr)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("PR")

	x = x + elem:GetWidth()

	-- "Spec" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("CENTER")
	elem:SetWidth(sections.players.col_widths.spec)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("Spec")

	x = x + elem:GetWidth()

	-- "Mult" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(sections.players.col_widths.mult)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("Mult")

	x = x + elem:GetWidth()

	-- "Score" table header
	elem = sections.players.frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	elem:SetPoint("TOPLEFT", x, 0)
	elem:SetJustifyH("RIGHT")
	elem:SetWidth(sections.players.col_widths.score)
	elem:SetHeight(sections.players.height_ea)
	elem:SetTextColor(_G.unpack(sections.players.th_color))
	elem:SetText("Score")

	-- Up arrow
	sections.players.up = sections.players.frame:CreateTexture(nil)
	sections.players.up:SetPoint("TOPLEFT", 3, -12)
	sections.players.up:SetWidth(10)
	sections.players.up:SetHeight(15)

	-- Down arrow
	sections.players.down = sections.players.frame:CreateTexture(nil)
	sections.players.down:SetPoint("BOTTOMLEFT", 3, -5)
	sections.players.down:SetWidth(10)
	sections.players.down:SetHeight(15)

	Players_Transition_to1()
end

--- Transitions the players section to step 1
function Players_Transition_to1()
	Players_Deselect()

	-- Hide player rows
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i]:Hide()
	end

	-- Reset players
	sections.players.index = 1
	sections.players.frame:Hide()
	sections.players.offset = 0
	Players_SetHasMoreUp(0)
	Players_SetHasMoreDown(0)
end

--- Transitions the players section to step 2
function Players_Transition_to2()
	Players_Transition_to1()
	Players_Show()
end

--- Transitions the players section to step 3
function Players_Transition_to3()
	Players_Hide()
end

--- Transitions the players section from step 3 to 2
function Players_Transition_3to2()
	Players_Show()
end

--- Show the players section
function Players_Show()
	sections.players.frame:Show()
	Players_Restage()
end

--- Hide the players section
function Players_Hide()
	sections.players.frame:Hide()
end

--- Resize and reposition the players section
function Players_Restage()
	sections.players.frame:ClearAllPoints()

	-- Determine y offset
	local y = sections.header.frame:GetHeight()
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	sections.players.frame:SetPoint("TOPLEFT", 0, -1 * y)

	-- Set frame height
	local h = sections.players.height_ea * _G.min(sections.players.max_visible, sections.players.index)
	sections.players.frame:SetHeight(h)
end

--- Announces the selected item
-- @param player_name <string>
-- @param class <string>
-- @param spec <string>
-- @param pr <number>
-- @param mult <number>
-- @param score <number>
function Players_Announce(player_name, class, spec, pr, mult, score)
	local desc = _G.string.lower(class)
	if spec then
		desc = _G.string.lower(spec)
	end
	local str = player_name .. " (" .. desc .. ") ("  .. pr
	if mult then
		str = str .. "x" .. mult
	end
	str = str .. " pr)"
	if score then
		str = "[" .. score .. " pts] " .. str
	else
		str = "[? pts] " .. str
	end
	addon.Util.ChatGroup(str)
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
	frame.player_class = nil
	frame.player_spec = nil
	frame.pr = nil
	frame.mult = nil
	frame.score = nil
	frame.index = sections.players.index

	-- Frame settings
	frame:EnableMouse(true)
	frame:SetPoint("TOPLEFT", 2, 0)
	frame:SetWidth(sections.window.width - 6)
	frame:SetHeight(sections.players.height_ea)

	x = 10

	-- Name
	frame.name_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.name_text:SetPoint("TOPLEFT", x, 0)
	frame.name_text:SetJustifyH("LEFT")
	frame.name_text:SetHeight(sections.players.height_ea)
	frame.name_text:SetWidth(sections.players.col_widths.player)

	x = x + frame.name_text:GetWidth()

	-- EP
	frame.ep_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.ep_text:SetPoint("TOPLEFT", x, 0)
	frame.ep_text:SetJustifyH("RIGHT")
	frame.ep_text:SetWidth(sections.players.col_widths.ep)
	frame.ep_text:SetHeight(sections.players.height_ea)

	x = x + frame.ep_text:GetWidth()

	-- GP
	frame.gp_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.gp_text:SetPoint("TOPLEFT", x, 0)
	frame.gp_text:SetJustifyH("RIGHT")
	frame.gp_text:SetWidth(sections.players.col_widths.gp)
	frame.gp_text:SetHeight(sections.players.height_ea)

	x = x + frame.gp_text:GetWidth()

	-- PR
	frame.pr_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.pr_text:SetPoint("TOPLEFT", x, 0)
	frame.pr_text:SetJustifyH("RIGHT")
	frame.pr_text:SetWidth(sections.players.col_widths.pr)
	frame.pr_text:SetHeight(sections.players.height_ea)

	x = x + frame.pr_text:GetWidth()

	-- Spec icon
	frame.spec_icon = frame:CreateTexture(nil)
	local x_tmp = x
	x_tmp = x_tmp + addon.Util.Round(sections.players.col_widths.spec / 2)
	x_tmp = x_tmp - addon.Util.Round(sections.players.spec_icon_size / 2)
	frame.spec_icon:SetPoint("TOPLEFT", x_tmp, 0)
	frame.spec_icon:SetSize(sections.players.spec_icon_size, sections.players.spec_icon_size)

	x = x + sections.players.col_widths.spec

	-- Mult
	frame.mult_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.mult_text:SetPoint("TOPLEFT", x, 0)
	frame.mult_text:SetJustifyH("RIGHT")
	frame.mult_text:SetWidth(sections.players.col_widths.mult)
	frame.mult_text:SetHeight(sections.players.height_ea)

	x = x + frame.mult_text:GetWidth()

	-- Score
	frame.score_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.score_text:SetPoint("TOPLEFT", x, 0)
	frame.score_text:SetJustifyH("RIGHT")
	frame.score_text:SetWidth(sections.players.col_widths.score)
	frame.score_text:SetHeight(sections.players.height_ea)
	frame.score_text:SetTextColor(1, 1, 1)

	-- Row highlight (automatic on mouseover)
	elem = frame:CreateTexture(nil, "HIGHLIGHT")
	elem:SetColorTexture(1, 0.82, 0, 0.1)
	elem:SetAllPoints(frame)

	-- Row select (hidden until clicked)
	frame.select = frame:CreateTexture(nil)
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
	selected_player.name = frame.name_text:GetText()
	selected_player.class = frame.player_class
	selected_player.spec = frame.player_spec
	frame.select:Show()
	sections.checkout.player_text:SetTextColor(frame.name_text:GetTextColor())
	sections.checkout.player_text:SetText(frame.name_text:GetText())
	Actions_EnableDistributeButton()
	Actions_EnableSetSpecButton()
	SpecPrompt_Hide()
	addon.Util.PlaySoundNext()
end

--- Reset the vars associated with the selected player
function Players_ResetSelection()
	selected_player.name = nil
	selected_player.class = nil
	selected_player.spec = nil
end

--- Deselect all players rows
function Players_Deselect()
	Players_ResetSelection()
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		sections.players.frames[i].select:Hide()
	end
	if sections.checkout.player_text then
		sections.checkout.player_text:SetText(nil)
	end
	Actions_DisableDistributeButton()
	Actions_DisableSetSpecButton()
	SpecPrompt_Hide()
end

--- A player needs the selected item
-- @param player_fullname <string>
function Players_Add(player_fullname)
	if not Window_IsReady() then
		return
	end
	if cur_step ~= 2 and cur_step ~= 3 then
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
		return
	end

	local frame = sections.players.frames[sections.players.index]
	if frame == nil then
		frame = Players_NewFrame()
	end
	sections.players.index = sections.players.index + 1

	-- Determine player EP, GP and PR
	local epgp = addon.Guild.DecodeOfficerNote(player_data.officer_note)
	frame.pr = addon.Util.GetPR(epgp.ep, epgp.gp)

	-- Save frame vars
	frame.player_name = player_name
	frame.player_class = player_data.class
	frame.player_spec = player_data.spec
	frame.tier = nil
	frame.mult = nil
	frame.score = nil

	-- Set class color
	frame.name_text:SetTextColor(_G.unpack(addon.Util.GetClassColor(player_data.class)))

	-- Set this row text
	frame.name_text:SetText(player_name)
	frame.ep_text:SetText(epgp.ep)
	frame.gp_text:SetText(epgp.gp)
	frame.pr_text:SetText(_G.string.format("%.2f", frame.pr))

	frame:Show()

	Players_SetScore(player_name, player_data.class, player_data.spec, false)
	Players_Restage()
	Actions_Restage()
	Checkout_Restage()
	History_Restage()
	Window_Resize()
end

--- Update the spec of the given player
-- @param player_name <string>
-- @param player_class <string>
-- @param player_spec <string>
-- @param save <boolean>
function Players_SetScore(player_name, player_class, player_spec, save)
	local score = nil
	local pr = 0
	local mult = nil
	for i = 1, addon.Util.SizeOf(sections.players.frames) do
		local frame = sections.players.frames[i]
		if frame.player_name == player_name then
			frame.player_spec = player_spec
			if player_spec then
				frame.spec_icon:SetTexture(addon.data.spec_textures[player_spec])

				mult = Item_GetMultFromSpec(player_spec)
				pr = frame.pr
				score = addon.Util.AddonNumber(pr * mult)

				frame.mult = mult
				frame.score = score

				frame.mult_text:SetText(frame.mult .. "x")
				frame.score_text:SetText(_G.string.format("%.2f", score))
			else
				frame.spec_icon:SetTexture(addon.data.spec_unknown_texture)
				frame.score_text:SetText("?")
			end
		end
	end
	if save then
		addon.Guild.SetPlayerSpec(player_name, player_spec)
	end
	Players_Announce(player_name, player_class, player_spec, pr, mult, score)
	Players_Sort()
	return score
end

--- Sorts the players list by PR
function Players_Sort()
	local tmp = {}
	for i = 1, (sections.players.index - 1) do
		_G.table.insert(tmp, sections.players.frames[i])
	end
	_G.table.sort(tmp, function(t1, t2)
		if t1.score == nil and t2.score == nil then
			return false
		elseif t1.score == nil then
			return false
		elseif t2.score == nil then
			return true
		end
		if t1.score == t2.score then
			return t1.player_name > t2.player_name
		end
		return t1.score > t2.score
	end)
	sections.players.frames = {}
	for i = 1, addon.Util.SizeOf(tmp) do
		sections.players.frames[i] = tmp[i]
	end
	Players_ScrollReposition()
end

--- Repositions the players list based on the offset
function Players_ScrollReposition()
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
		Players_SetHasMoreUp(1)
	elseif sections.players.index >= sections.players.max_visible then
		Players_SetHasMoreUp(-1)
	else
		Players_SetHasMoreUp(0)
	end
	if sections.players.index > offset + sections.players.max_visible then
		Players_SetHasMoreDown(1)
	elseif sections.players.index >= sections.players.max_visible then
		Players_SetHasMoreDown(-1)
	else
		Players_SetHasMoreDown(0)
	end
end

--- Sets the arrow texture if there are more players up the list
-- @param flag <number> 1 if enable, 0 if hide, -1 if disable
function Players_SetHasMoreUp(flag)
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
function Players_SetHasMoreDown(flag)
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

--------------
-- Spec Prompt
--------------

--- Create and init the spec prompt
function SpecPrompt_Create()
	sections.spec_prompt.frame = _G.CreateFrame("Frame", nil, nil, "TooltipBorderedFrameTemplate")
	sections.spec_prompt.frame:EnableMouse(true)
	sections.spec_prompt.frame:SetPoint("CENTER", 0, 0)
	sections.spec_prompt.frame:SetWidth(100)
	sections.spec_prompt.frame:SetHeight(110)
	sections.spec_prompt.frame:SetFrameStrata("DIALOG")

	sections.spec_prompt.str_player_name = nil
	sections.spec_prompt.str_player_class = nil

	local y = -8

	-- Title
	local title = sections.spec_prompt.frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 0, y)
	title:SetHeight(12)
	title:SetWidth(sections.spec_prompt.frame:GetWidth())
	title:SetJustifyV("TOP")
	title:SetJustifyH("CENTER")
	title:SetText("Choose spec for")

	y = y - title:GetHeight()

	-- Player name
	sections.spec_prompt.player_name = sections.spec_prompt.frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	sections.spec_prompt.player_name:SetPoint("TOPLEFT", 0, y)
	sections.spec_prompt.player_name:SetHeight(12)
	sections.spec_prompt.player_name:SetWidth(sections.spec_prompt.frame:GetWidth())
	sections.spec_prompt.player_name:SetJustifyV("TOP")
	sections.spec_prompt.player_name:SetJustifyH("CENTER")
	sections.spec_prompt.player_name:SetText("(player)")

	y = y - sections.spec_prompt.player_name:GetHeight()

	sections.spec_prompt.buttons_offset = 8 + title:GetHeight() + sections.spec_prompt.player_name:GetHeight()

	-- Spec buttons
	for i = 1, 4 do
		sections.spec_prompt.buttons[i] = _G.CreateFrame("Button", nil, sections.spec_prompt.frame, "OptionsButtonTemplate")
		local btn = sections.spec_prompt.buttons[i]
		btn.spec = nil
		btn:SetPoint("TOPLEFT", 10, y)
		btn:SetPoint("BOTTOMRIGHT", sections.spec_prompt.frame, "TOPRIGHT", -10, y - 15)
		btn:SetHeight(sections.spec_prompt.button_height_ea)
		btn:SetScript("OnClick", function (self, button)
			Players_SetScore(sections.spec_prompt.str_player_name, sections.spec_prompt.str_player_class, self.spec, true)
			SpecPrompt_Hide()
			selected_player.spec = self.spec
		end)
		btn.btn_text = btn:CreateFontString(nil, nil, "GameFontNormalSmall")
		btn.btn_text:SetAllPoints(btn)
		btn.btn_text:SetJustifyH("CENTER")
		btn.btn_text:SetJustifyV("CENTER")
		btn.btn_text:SetText("Spec #" .. i)

		y = y - btn:GetHeight() - 2
	end
end

--- Show the spec prompt
-- @param player_name <string>
-- @param player_class <string>
function SpecPrompt_Show(player_name, player_class)
	sections.spec_prompt.player_name:SetText(player_name)
	sections.spec_prompt.player_name:SetTextColor(_G.unpack(addon.Util.GetClassColor(player_class)))

	sections.spec_prompt.str_player_name = player_name
	sections.spec_prompt.str_player_class = player_class

	sections.spec_prompt.buttons[2]:Hide()
	sections.spec_prompt.buttons[3]:Hide()
	sections.spec_prompt.buttons[4]:Hide()

	local num_buttons = 1

	if player_class == "WARRIOR" then
		SpecPrompt_SetButton(1, "PROT_WAR")
		SpecPrompt_SetButton(2, "FURY_WAR")
		num_buttons = 2
	elseif player_class == "SHAMAN" then
		SpecPrompt_SetButton(1, "RESTO_SHAM")
		SpecPrompt_SetButton(2, "ELE_SHAM")
		SpecPrompt_SetButton(3, "ENHANCE_SHAM")
		num_buttons = 3
	elseif player_class == "DRUID" then
		SpecPrompt_SetButton(1, "RESTO_DRUID")
		SpecPrompt_SetButton(2, "BEAR_DRUID")
		SpecPrompt_SetButton(3, "CAT_DRUID")
		SpecPrompt_SetButton(4, "BOOMKIN")
		num_buttons = 4
	elseif player_class == "PRIEST" then
		SpecPrompt_SetButton(1, "HOLY_PRIEST")
		SpecPrompt_SetButton(2, "SHADOW_PRIEST")
		num_buttons = 2
	elseif player_class == "PALADIN" then
		SpecPrompt_SetButton(1, "HOLY_PALADIN")
		SpecPrompt_SetButton(2, "RET_PALADIN")
		SpecPrompt_SetButton(3, "PROT_PALADIN")
		num_buttons = 3
	else
		SpecPrompt_SetButton(1, player_class)
	end
	local height = sections.spec_prompt.buttons_offset + (num_buttons * (sections.spec_prompt.button_height_ea + 2)) + 6
	sections.spec_prompt.frame:SetHeight(height);
	sections.spec_prompt.frame:Show()
end

--- Sets a spec button in the spec prompt
-- @param index <number>
-- @param spec <string>
function SpecPrompt_SetButton(index, spec)
	sections.spec_prompt.buttons[index].spec = spec
	sections.spec_prompt.buttons[index].btn_text:SetText(addon.data.spec_abbrs[spec])
	sections.spec_prompt.buttons[index]:Show()
end

--- Hide the spec prompt
function SpecPrompt_Hide()
	if sections.spec_prompt.frame then
		sections.spec_prompt.frame:Hide()
	end
end

----------
-- Actions
----------

--- Create and init the actions section
function Actions_Create()
	-- Frame
	sections.actions.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.actions.frame:SetWidth(sections.window.width)
	sections.actions.frame:SetHeight(sections.actions.height)

	-- Cancel button
	local elem = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(55)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.Util.PlaySoundClose()
		Transition_to1()
	end)
	subelem = elem:CreateFontString(nil, nil, "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Cancel")

	-- Need button
	local elem = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 57, 3)
	elem:SetWidth(55)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		Players_Add(_G.UnitFullName("player"))
	end)
	subelem = elem:CreateFontString(nil, nil, "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Need")

	-- Set spec button
	sections.actions.btn_set_spec = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	sections.actions.btn_set_spec:SetPoint("BOTTOMRIGHT", -77, 3)
	sections.actions.btn_set_spec:SetWidth(75)
	sections.actions.btn_set_spec:SetHeight(18)
	sections.actions.btn_set_spec:SetScript("OnClick", function (_, button)
		SpecPrompt_Show(selected_player.name, selected_player.class)
	end)
	sections.actions.btn_set_spec_text = sections.actions.btn_set_spec:CreateFontString(nil, nil, "GameFontNormalSmall")
	sections.actions.btn_set_spec_text:SetPoint("TOPLEFT", 5, 0)
	sections.actions.btn_set_spec_text:SetPoint("TOPRIGHT", -5, 0)
	sections.actions.btn_set_spec_text:SetJustifyH("CENTER")
	sections.actions.btn_set_spec_text:SetHeight(18)
	sections.actions.btn_set_spec_text:SetText("Set Spec")

	-- Distribute button
	sections.actions.btn_dist = _G.CreateFrame("Button", nil, sections.actions.frame, "OptionsButtonTemplate")
	sections.actions.btn_dist:SetPoint("BOTTOMRIGHT", -3, 3)
	sections.actions.btn_dist:SetWidth(75)
	sections.actions.btn_dist:SetHeight(18)
	sections.actions.btn_dist:SetScript("OnClick", function (_, button)
		addon.Util.PlaySoundNext()
		Transition_2to3()
	end)
	sections.actions.btn_dist_text = sections.actions.btn_dist:CreateFontString(nil, nil, "GameFontNormalSmall")
	sections.actions.btn_dist_text:SetPoint("TOPLEFT", 5, 0)
	sections.actions.btn_dist_text:SetPoint("TOPRIGHT", -5, 0)
	sections.actions.btn_dist_text:SetJustifyH("CENTER")
	sections.actions.btn_dist_text:SetHeight(18)
	sections.actions.btn_dist_text:SetText("Distribute")

	Actions_Transition_to1()
end

--- Transition the actions section to step 1
function Actions_Transition_to1()
	sections.actions.frame:Hide()
	Actions_DisableDistributeButton()
	Actions_DisableSetSpecButton()
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

--- Show the actions section
function Actions_Show()
	Actions_Restage()
	sections.actions.frame:Show()
end

--- Hide the actions section
function Actions_Hide()
	sections.actions.frame:Hide()
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

--- Disable the set spec button
function Actions_DisableSetSpecButton()
	if sections.actions.btn_set_spec then
		sections.actions.btn_set_spec:Disable()
		sections.actions.btn_set_spec_text:SetTextColor(1, 1, 1, 0.5)
	end
end

--- Enable the set spec button
function Actions_EnableSetSpecButton()
	sections.actions.btn_set_spec:Enable()
	sections.actions.btn_set_spec_text:SetTextColor(1, 0.82, 0)
end

-----------
-- Checkout
-----------

--- Create and init the checkout section
function Checkout_Create()
	-- Checkout frame
	sections.checkout.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.checkout.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.checkout.frame:SetWidth(sections.window.width)
	sections.checkout.frame:SetHeight(sections.checkout.min_height)

	-- Back button
	local elem = _G.CreateFrame("Button", nil, sections.checkout.frame, "OptionsButtonTemplate")
	elem:SetPoint("BOTTOMLEFT", 3, 3)
	elem:SetWidth(45)
	elem:SetHeight(18)
	elem:SetScript("OnClick", function (_, button)
		addon.Util.PlaySoundBack()
		Transition_3to2()
	end)
	local subelem = elem:CreateFontString(nil, nil, "GameFontNormalSmall")
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
	subelem = elem:CreateFontString(nil, nil, "GameFontNormalSmall")
	subelem:SetPoint("TOPLEFT", 5, 0)
	subelem:SetPoint("TOPRIGHT", -5, 0)
	subelem:SetJustifyH("CENTER")
	subelem:SetHeight(18)
	subelem:SetText("Confirm")

	-- "Give item to.." text
	elem = sections.checkout.frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -3)
	elem:SetJustifyH("LEFT")
	elem:SetText("Give item to: ")

	-- Player name text
	sections.checkout.player_text = sections.checkout.frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	sections.checkout.player_text:SetPoint("TOPLEFT", 73, -3)
	sections.checkout.player_text:SetJustifyH("LEFT")

	-- "For.." text
	elem = sections.checkout.frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	elem:SetPoint("TOPLEFT", 3, -23)
	elem:SetJustifyH("LEFT")
	elem:SetText("For: ")

	-- GP select dropdown
	local sel = sections.checkout.gp_select
	-- add 1 for base tier option and 1 for custom option
	sel.options.max = addon.Util.SizeOf(addon.data.tiers) + 2
	sel.dropdown = _G.CreateFrame("FRAME", nil, sections.checkout.frame, "OptionsDropdownTemplate")
	sel.dropdown:SetPoint("TOPLEFT", 10, -15)
	sel.dropdown.Text:SetText("N/A")
	sel.dropdown.Middle:SetWidth(80)
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
	elem = sel.wrapper:CreateTexture(nil)
	elem:SetColorTexture(0, 0, 0, 0.8)
	elem:SetAllPoints(sel.wrapper)

	-- GP select options
	for i = 1, sel.options.max do
		-- Option button
		sel.options.frames[i] = _G.CreateFrame("BUTTON", nil, sel.wrapper)
		sel.options.frames[i]:SetPoint("TOPLEFT", 0, -1 * (i - 1) * sel.options.height_ea)
		sel.options.frames[i]:SetWidth(sel.wrapper:GetWidth())
		sel.options.frames[i]:SetHeight(sel.options.height_ea)
		sel.options.frames[i].value = 0
		sel.options.frames[i].tiernum = 0
		sel.options.frames[i]:SetScript("OnClick", function (option_frame)
			Checkout_ChooseGPOptionByFrame(option_frame)
		end)

		-- Option highlight
		elem = sel.options.frames[i]:CreateTexture(nil, "HIGHLIGHT")
		elem:SetColorTexture(1, 0.82, 0, 0.2)
		elem:SetAllPoints(sel.options.frames[i])

		-- Option text
		sel.options.frames[i].text = sel.options.frames[i]:CreateFontString(nil, nil, "GameFontNormalSmall")
		sel.options.frames[i].text:SetPoint("TOPLEFT", 15, -3)
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
		Checkout_SetGPCost(val)
	end)

	Checkout_Hide()
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

--- Show the checkout section
function Checkout_Show()
	sections.checkout.frame:Show()
	Checkout_Restage()
end

--- Hide the checkout section
function Checkout_Hide()
	Checkout_SetGPCost(0)
	sections.checkout.frame:Hide()
	sections.checkout.gp_select.wrapper:Hide()
end

--- Confirm the checkout
function Checkout_Confirm()
	addon.Core.Transact(selected_player.name, current_item.id, gp_cost, false, "Item Distribute", true, true)
	History_Add(selected_player.name, current_item.id, gp_cost)
	Transition_to1()
end

--- Update the GP dropdown
function Checkout_UpdateGPDropdown()
	local sel = sections.checkout.gp_select

	local i = 1
	for key, option in _G.pairs(current_item.gp_options) do
		sel.options.frames[i].tiernum = option.tiernum
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

	Checkout_SetGPCost(sel.options.frames[1].value)

	for j = i + 1, sel.options.max do
		sel.options.frames[j].tiernum = 0
		sel.options.frames[j].value = 0
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
-- @param option_frame <Frame>
function Checkout_ChooseGPOptionByFrame(option_frame)
	sections.checkout.gp_select.wrapper:Hide()
	sections.checkout.gp_select.dropdown.Text:SetText(option_frame.text:GetText())
	sections.checkout.gp_select.dropdown.value = option_frame.value
	if option_frame.value <= 0 then
		Checkout_ShowCustomGPInput()
	else
		Checkout_HideCustomGPInput()
		Checkout_SetGPCost(option_frame.value)
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

--- Sets the GP cost
-- @param gp <number>
function Checkout_SetGPCost(gp)
	gp = addon.Util.AddonNumber(gp)
	gp_cost = gp
end

--- Automatically refresh the selected GP
function Checkout_RefreshSelectedGP()
	if sections.checkout.custom_gp:IsVisible() then
		Checkout_SetGPCost(addon.Util.AddonNumber(sections.checkout.custom_gp:GetText()))
	else
		Checkout_SetGPCost(sections.checkout.gp_select.dropdown.value)
	end
end

--- Selects the appropriate option in the GP dropdown
-- Based on the selected player and spec
function Checkout_UpdateGPSelection()
	if not selected_player.spec then
		return
	end
	local tiernum = current_item.spec_to_tiernum[selected_player.spec]
	if not tiernum then
		tiernum = addon.Util.SizeOf(addon.data.tiers) + 1
	end
	for i, option_frame in _G.pairs(sections.checkout.gp_select.options.frames) do
		if option_frame.tiernum == tiernum then
			Checkout_ChooseGPOptionByFrame(option_frame)
			return
		end
	end

end

----------
-- History
----------

--- Create and init the history section
function History_Create()
	sections.history.frame = _G.CreateFrame("Frame", nil, sections.window.frame)
	sections.history.frame:SetPoint("TOPLEFT", 0, -1 * sections.header.height)
	sections.history.frame:SetWidth(sections.window.width)
	sections.history.frame:SetHeight(0)
end

--- Resize and reposition the history section
function History_Restage()
	-- Reposition
	sections.history.frame:ClearAllPoints()
	local y = sections.header.height
	if sections.details.frame:IsVisible() then
		y = y + sections.details.frame:GetHeight()
	end
	if sections.players.frame:IsVisible() then
		y = y + sections.players.frame:GetHeight()
	end
	if sections.actions.frame:IsVisible() then
		y = y + sections.actions.frame:GetHeight()
	end
	if sections.checkout.frame:IsVisible() then
		y = y + sections.checkout.frame:GetHeight()
	end
	sections.history.frame:SetPoint("TOPLEFT", 0, -1 * y)

	local h = 0
	if sections.history.index > 1 then
		h = (sections.history.index - 1) * sections.history.height_ea + 3
	end
	sections.history.frame:SetHeight(h)
end

--- Returns true if the history contains the given item, false otherwise
-- @param item_link <string>
-- @return <boolean>
function History_HasItem(item_link)
	for i = 1, addon.Util.SizeOf(sections.history.frames) do
		if sections.history.frames[i].item_text:GetText() == item_link then
			return true
		end
	end
	return false
end

--- Clear the history rows
function History_Clear()
	-- Hide history rows
	for i = 1, addon.Util.SizeOf(sections.history.frames) do
		sections.history.frames[i]:Hide()
	end

	-- Reset history
	sections.history.index = 1

	History_Restage()
	Window_Resize()
end

--- Add an entry into the history list
-- @param player_name <string>
-- @param item_id <number>
-- @param gp <number>
function History_Add(player_name, item_id, gp)
	local frame = sections.history.frames[sections.history.index]
	if frame == nil then
		frame = History_NewFrame()
	end
	sections.history.index = sections.history.index + 1

	local _, item_link = _G.GetItemInfo(item_id)

	frame:Show()
	frame.item_id = item_id
	frame.item_text:SetText(item_link)
	frame.name_text:SetText(player_name)
	frame.name_text:SetTextColor(_G.unpack(addon.Util.GetClassColor(addon.Guild.GetPlayerClass(player_name))))
	frame.gp_text:SetText(gp)

	History_Restage()
	Window_Resize()
end

--- Create a new history frame and return it
-- @return <Frame>
function History_NewFrame()
	-- Frame
	local frame = _G.CreateFrame("Frame", nil, sections.history.frame)
	sections.history.frames[sections.history.index] = frame

	-- Frame vars
	frame.player_name = nil
	frame.gp = nil
	frame.item_id = nil
	frame.index = sections.history.index

	-- Frame settings
	frame:SetPoint("TOPLEFT", 0, -1 * sections.history.height_ea * (sections.history.index - 1))
	frame:SetWidth(sections.window.width)
	frame:SetHeight(sections.history.height_ea)

	-- Item
	frame.item_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.item_text:SetPoint("TOPLEFT", 2, 0)
	frame.item_text:SetJustifyH("LEFT")
	frame.item_text:SetWidth(92)
	frame.item_text:SetHeight(sections.history.height_ea)

	-- Player Name
	frame.name_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.name_text:SetPoint("TOPRIGHT", -36, 0)
	frame.name_text:SetJustifyH("LEFT")
	frame.name_text:SetWidth(70)
	frame.name_text:SetHeight(sections.history.height_ea)

	-- GP
	frame.gp_text = frame:CreateFontString(nil, nil, "GameFontNormalTiny")
	frame.gp_text:SetPoint("TOPRIGHT", -5, 0)
	frame.gp_text:SetJustifyH("RIGHT")
	frame.gp_text:SetWidth(35)
	frame.gp_text:SetHeight(sections.history.height_ea)

	return frame
end

-------
-- Item
-------

--- Loads the GP options for the selected item into current_item.gp_options
function Item_LoadGP()
	current_item.gp_options = {}
	current_item.spec_to_tiernum = {}

	-- Reset the custom GP input to the default price
	sections.checkout.custom_gp:SetText(addon.Config.GetOption("ItemDistribute.default_price"))

	-- Get the item data
	local item_data = addon.Core.GetItemData(current_item.id)
	if item_data == nil then
		Checkout_ShowCustomGPInput()
		return
	end

	-- Get a sorted list of tiers
	local tiernums = {}
	if item_data.by_tier then
		tiernums = addon.Util.TableGetKeys(item_data.by_tier)
		_G.table.sort(tiernums)
	end

	-- Insert the tier GP options
	for _, tiernum in _G.pairs(tiernums) do
		tier_data = item_data.by_tier[tiernum]
		_G.table.insert(current_item.gp_options, {
			["tiernum"] = tiernum,
			["text"] = "(" .. tiernum .. ") " .. addon.data.tiers[tiernum] .. ": " .. tier_data.price .. "gp",
			["price"] = tier_data.price,
		})
	end

	-- Insert the final base GP option
	if item_data.price ~= nil then
		local base_tiernum = addon.Util.SizeOf(addon.data.tiers) + 1
		_G.table.insert(current_item.gp_options, {
			["tiernum"] = base_tiernum,
			["text"] = "(" .. base_tiernum .. ") " .. addon.data.tier_base_name .. ": " .. item_data.price .. "gp",
			["price"] = item_data.price,
		})
	end

	for _, tiernum in _G.pairs(tiernums) do
		tier_data = item_data.by_tier[tiernum]
		if tier_data.specs ~= nil then
			for _, spec in _G.pairs(tier_data.specs) do
				if not current_item.spec_to_tiernum[spec] then
					current_item.spec_to_tiernum[spec] = tiernum
				end
			end
		end
	end

	if addon.Util.SizeOf(current_item.gp_options) then
		Checkout_HideCustomGPInput()
	else
		Checkout_ShowCustomGPInput()
	end
end

--- Reset the vars associated with the current item
function Item_Reset()
	current_item.id = nil
	current_item.gp_options = {}
	current_item.spec_to_tiernum = {}
end

--- Announces the selected item
function Item_Announce()
	if current_item.id == nil then
		return
	end

	local _, item_link = _G.GetItemInfo(current_item.id)
	local msg = "Now Distributing: " .. item_link
	addon.Util.ChatGroup(msg, addon.Config.GetOption("ItemDistribute.announce_raid_warning"))
	local item_data = addon.Core.GetItemData(current_item.id)
	local total = 0
	if item_data ~= nil then
		local tiers = {}
		if item_data.by_tier then
			tiers = addon.Util.TableGetKeys(item_data.by_tier)
			_G.table.sort(tiers)
		end
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
			addon.Util.ChatGroup(str)
			total = total + 1
		end
		if item_data.price then
			addon.Util.ChatGroup(" ( " .. addon.data.tier_base_name .. ": " .. item_data.price .. "gp )")
		end
	end
	if total == 0 then
		addon.Util.ChatGroup("No prices set")
	end
	addon.Util.ChatGroup("DM \"need\" to " .. _G.UnitName("player"))
end

--- Returns the tier PR multiplier for the given spec
-- @param spec <string>
-- @return <number>
function Item_GetMultFromSpec(spec)
	local tiernum = Item_GetTiernumFromSpec(spec)
	if tiernum then
		local tier = addon.data.tiers[tiernum]
		return addon.Config.GetOption("Tiers.pr_mult." .. tier)
	end
	return 1
end

-- @param spec <string>
-- @return int
function Item_GetTiernumFromSpec(spec)
	return current_item.spec_to_tiernum[spec]
end

-------
-- Menu
-------

--- Create the right click context menu
function Menu_Create()
	sections.menu.frame = _G.CreateFrame("Frame", nil, _G.UIParent, "UIDropDownMenuTemplate")
	sections.menu.frame:SetPoint("TOPLEFT", -100, 0)
	sections.menu.frame:Hide()
	_G.UIDropDownMenu_Initialize(sections.menu.frame, Menu_Refresh, "MENU")
end

--- This function is called every time the context menu is opened
-- @param frame <Frame>
-- @param level <number>
-- @param menulist
function Menu_Refresh(frame, level, menulist)
	local GetMenuButton = addon.Util.GetMenuButton

	local button = GetMenuButton()
	button = GetMenuButton()
	button.text = addon.short_name
	button.isTitle = true
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	button.text = "Addon Options"
	button.func = function ()
		_G.InterfaceOptionsFrame_OpenToCategory(addon.Options.panel)
		_G.InterfaceOptionsFrame_OpenToCategory(addon.Options.panel)
	end
	_G.UIDropDownMenu_AddButton(button)

	if sections.window.frame and current_item.id then
		button = GetMenuButton()
		button.text = "Item"
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
			Transition_to1()
		end
		_G.UIDropDownMenu_AddButton(button)
	end

	if sections.window.frame and sections.history.index > 1 then
		button = GetMenuButton()
		button.text = "History"
		button.isTitle = true
		_G.UIDropDownMenu_AddButton(button)

		button = GetMenuButton()
		button.text = "Clear History"
		button.func = function ()
			History_Clear()
		end
		_G.UIDropDownMenu_AddButton(button)
	end

	button = GetMenuButton()
	button.text = "Window"
	button.isTitle = true
	_G.UIDropDownMenu_AddButton(button)

	button = GetMenuButton()
	if sections.window.is_minimized then
		button.text = "Maximize Window"
		button.func = function ()
			Window_Maximize()
		end
	else
		button.text = "Minimize Window"
		button.func = function ()
			Window_Minimize()
		end
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
	_G.ToggleDropDownMenu(1, nil, sections.menu.frame, "cursor", 3, -3, nil, nil, 2)
end

---------
-- Window
---------

--- Create the window
function Window_Create()
	-- Create window frame
	sections.window.frame = _G.CreateFrame("Frame", nil, nil, "BasicFrameTemplate")
	sections.window.frame:EnableMouse(true)
	sections.window.frame:SetClampedToScreen(true)
	sections.window.frame:SetPoint(
		"TOPLEFT",
		addon.Config.GetOption("ItemDistribute.x"),
		addon.Config.GetOption("ItemDistribute.y")
	)
	sections.window.frame:SetPoint("TOP", addon.Config.GetOption("ItemDistribute.y"))
	sections.window.frame:SetWidth(sections.window.width)
	sections.window.frame:SetHeight(sections.header.height)
	sections.window.frame:SetScale(0.9)
	sections.window.frame:SetFrameStrata("HIGH")

	-- Remove the default close button from "BasicFrameTemplate"
	local close_btn = sections.window.frame:GetChildren()
	close_btn:Hide()

	-- Add a minimize button
	sections.window.frame.minimize_btn = _G.CreateFrame("Button", nil, sections.window.frame)
	sections.window.frame.minimize_btn:SetPoint("TOPRIGHT", 0, 1)
	sections.window.frame.minimize_btn:SetSize(24, 24)
	sections.window.frame.minimize_btn:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Up")
	sections.window.frame.minimize_btn:SetHighlightTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Up")
	sections.window.frame.minimize_btn:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Down")
	sections.window.frame.minimize_btn:SetScript("OnClick", function ()
		Window_Minimize()
	end)

	-- Add a maximize button
	sections.window.frame.maximize_btn = _G.CreateFrame("Button", nil, sections.window.frame)
	sections.window.frame.maximize_btn:SetPoint("TOPRIGHT", 0, 1)
	sections.window.frame.maximize_btn:SetSize(24, 24)
	sections.window.frame.maximize_btn:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
	sections.window.frame.maximize_btn:SetHighlightTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
	sections.window.frame.maximize_btn:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Down")
	sections.window.frame.maximize_btn:SetScript("OnClick", function ()
		Window_Maximize()
	end)
	sections.window.frame.maximize_btn:Hide()

	-- Window background
	-- To darken the background texture a bit
	local bg = sections.window.frame:CreateTexture(nil)
	bg:SetColorTexture(0, 0, 0, 0.6)
	bg:SetPoint("TOPLEFT", 3, -20)
	bg:SetPoint("BOTTOMRIGHT", -3, 3)
end

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
		local s, e = _G.string.find(_G.string.lower(msg), "need")
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
		if not Window_IsReady() then
			return
		end

		-- Occurs when the player drops the item onto the window
		local info_type, item_id, item_link = _G.GetCursorInfo()
		if info_type == nil or info_type ~= "item" then
			return
		end

		-- Return held item to where it came from
		_G.ClearCursor()

		Transition_to2(item_id)
	elseif button == "RightButton" then
		Menu_Toggle()
	end
end

--- When scrolling the window
-- @param window <Frame>
-- @param dir <number> 1 for up, -1 for down
function Window_OnMouseWheel(window, dir)
	if cur_step == 2 then
		local min = 0
		local max = sections.players.index - sections.players.max_visible
		local diff = -1 * dir
		local new_offset = sections.players.offset + diff
		sections.players.offset = _G.max(min, _G.min(max, new_offset))
		Players_ScrollReposition()
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
	if sections.history.frame:IsVisible() then
		h = h + sections.history.frame:GetHeight()
	end
	sections.window.frame:SetHeight(h)
end

--- Unlock the window
-- Enable dragging and bind to drag events
function Window_Unlock()
	sections.window.frame:SetMovable(true)
	sections.window.frame:RegisterForDrag("LeftButton")
	sections.window.frame:SetScript("OnDragStart", Window_OnDragStart)
	sections.window.frame:SetScript("OnDragStop", Window_OnDragStop)
end

--- When starting window drag
function Window_OnDragStart()
	sections.window.frame:StartMoving()
end

--- When stopping window drag
function Window_OnDragStop()
	local _, _, _, x, y = sections.window.frame:GetPoint()

	-- Clamp top left
	x = _G.max(x, 0)
	y = _G.min(y, 0)

	-- Clamp bottom right
	x = _G.min(x, _G.GetScreenWidth() - sections.window.frame:GetWidth())
	y = _G.max(y, -1 * _G.GetScreenHeight() + sections.window.frame:GetHeight())

	-- Save position
	addon.Config.SetOption("ItemDistribute.x", x)
	addon.Config.SetOption("ItemDistribute.y", y)

	-- Set position
	sections.window.frame:StopMovingOrSizing()
	sections.window.frame:ClearAllPoints()
	sections.window.frame:SetPoint("TOPLEFT", x, y)
end

--- Reset the window's position
function Window_ResetPosition()
	addon.Config.SetOptionToDefault("ItemDistribute.x")
	addon.Config.SetOptionToDefault("ItemDistribute.y")
	sections.window.frame:SetPoint(
		"TOPLEFT",
		addon.Config.GetOption("ItemDistribute.x"),
		addon.Config.GetOption("ItemDistribute.y")
	)
	sections.window.frame:SetPoint("TOP", addon.Config.GetOption("ItemDistribute.y"))
	sections.window.frame:SetPoint("CENTER", 0, 0)
end

--- Lock the window
-- Disable dragging events and set unmovable
function Window_Lock()
	sections.window.frame:SetMovable(false)
	sections.window.frame:RegisterForDrag(nil)
	sections.window.frame:SetScript("OnDragStart", nil)
	sections.window.frame:SetScript("OnDragStop", nil)
end

--- Close the window
function Window_Close()
	addon.Util.PlaySoundClose()
	Window_Hide()
	Transition_to1(false)
end

--- Open the window
function Window_Open()
	addon.Util.PlaySoundOpen()
	Window_Show()
	Transition_to1(false)
end

--- Minimize the window
function Window_Minimize()
	Transition_to1()
	sections.history.frame:Hide()
	Header_SetMinimized()
	sections.window.frame:SetWidth(sections.window.width_minimized)
	sections.window.frame.maximize_btn:Show()
	sections.window.frame.minimize_btn:Hide()
	Window_Resize()
	sections.window.is_minimized = true
end

--- Maximize the window
function Window_Maximize()
	Transition_to1()
	sections.history.frame:Show()
	Header_SetMaximized()
	sections.window.frame:SetWidth(sections.window.width)
	sections.window.frame.maximize_btn:Hide()
	sections.window.frame.minimize_btn:Show()
	Window_Resize()
	sections.window.is_minimized = false
end

--- Returns true if the window is ready for items
-- @return <boolean>
function Window_IsReady()
	if sections.window.is_minimized then
		return false
	end
	if not sections.window.frame:IsVisible() then
		return false
	end
	return true
end

--- Show the window
function Window_Show()
	sections.window.frame:Show()
end

--- Hide the window
function Window_Hide()
	sections.window.frame:Hide()
end

--- Returns true if the window is open, false otherwise
-- @return <boolean>
function Window_IsOpen()
	return sections.window.frame:IsVisible()
end

-------
-- Test
-------

function Test_Needs()
	Players_Add("Berg")
	Players_Add("Dambi")
	Players_Add("Tuna")
	Players_Add("Sheep")
	Players_Add("Quackin")
	Players_Add("Colitiscow")
	Players_Add("Beazlebubs")
end
