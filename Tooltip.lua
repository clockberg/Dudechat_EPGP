local _, ns = ...

local ICON_HEIGHT = 18
local ICON_WIDTH = 18
local TEXT_WIDTH = 35

-- Create icons frame
local frame = CreateFrame("Frame")
frame:SetPoint("BOTTOMLEFT", 0, 0)
--frame:SetBackdrop({edgeFile = "edgeFile"});

-- Create and align the frame's textures (icons)
local frameTextures = {}
local frameTexts = {}

local row = 1
for row = 1, 5 do
    local yOffset = -1 * (row - 1) * ICON_HEIGHT
    frameTextures[row] = {}
    for col = 1, 14 do
        local xOffset = (col - 1) * ICON_WIDTH + TEXT_WIDTH

        frameTexts[row] = frame:CreateFontString(frame, "OVERLAY", "GameTooltipText")
        frameTexts[row]:SetPoint("TOPLEFT", 0, yOffset - 1)

        frameTextures[row][col] = frame:CreateTexture(nil, "OVERLAY")
        frameTextures[row][col]:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
        frameTextures[row][col]:SetSize(16, 16)
    end
end

-- Clear the frame's previous texture state
local function clearFrame()
    for i = 1, #frameTexts do
        frameTexts[i]:SetText(nil)
    end
    for i = 1, #frameTextures do
        for j = 1, #frameTextures[i] do
            frameTextures[i][j]:SetTexture(nil)
        end
    end
end

local function tierToOrder(tier)
    if (tier == ns.TIER_Z) then return 1
    elseif (tier == ns.TIER_S) then return 2
    elseif (tier == ns.TIER_A) then return 3
    elseif (tier == ns.TIER_B) then return 4
    elseif (tier == ns.TIER_C) then return 5
    else return 0
    end
end

local function resizeFrame(rows, cols)
    local width = cols * ICON_WIDTH + TEXT_WIDTH
    local height = rows * ICON_HEIGHT
    frame:SetSize(width, height)
    frame:SetMaxResize(width, height)
end

local function tablelength(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

local function ModifyItemTooltip(tooltip)
    local itemName = select(1, tooltip:GetItem())
    local itemId = select(1, GetItemInfoInstant(itemName))

    -- Reuse the frame state if the item hasn't changed
    if previousItemID == itemId then
        GameTooltip_InsertFrame( tooltip, frame )
        return
    end

    -- Check if the item has data
    local itemData = ns.items_db[itemId];
    if itemData == nil then
        -- Don't modify the tooltip
        return
    end

    previousItemID = itemId

    clearFrame()

    print("--- ITEM # " .. itemId .. " ---")

    local num_rows = tablelength(itemData.Rankings)
    local num_cols = 0
    local keys = {}
    table.foreach(itemData.Rankings, function (key, v) table.insert(keys, key) end )
    table.sort(keys, function (arg1, arg2)
        return tierToOrder(arg1) < tierToOrder(arg2)
    end)

    for i = 1, #keys do
        local key = keys[i]
        local rankingData = itemData.Rankings[key]
        num_cols = max(num_cols, table.getn(rankingData.Roles))
    end
    resizeFrame(num_rows, num_cols)

    local myrow = 1
    for i = 1, #keys do
        local key = keys[i]
        local rankingData = itemData.Rankings[key]
        -- show tier and value text
        frameTexts[myrow]:SetText(key .. ": " .. rankingData.Value)

        for j, role in pairs(rankingData.Roles) do
            -- show role icon
            local mycol = j
            frameTextures[myrow][mycol]:SetTexture(ns.roleIconTextures[role])
        end
        myrow = myrow + 1
    end

    GameTooltip_InsertFrame(tooltip, frame)
end

local function InitTooltipExtension()
    GameTooltip:HookScript("OnTooltipSetItem", ModifyItemTooltip)
end

InitTooltipExtension()
