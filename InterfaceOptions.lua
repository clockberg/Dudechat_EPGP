local _, addon = ...

local InterfaceOptions = {}
InterfaceOptions.__index = InterfaceOptions
function InterfaceOptions:New()
	local self = {}
	setmetatable(self, InterfaceOptions)
	return self
end

function DEPGP:InitInterfaceOptions()
	self.interface_options = InterfaceOptions:New()
	self.interface_options:Init()
	self.interface_options:AddCheckbox()
	self.interface_options:AddCheckbox(14, -35, "CheckboxName", "CheckboxTooltip")
	self.interface_options:Connect()
end

-- called when the frame is initially displayed, and after requesting the default values to be restored
function InterfaceOptions:OnRefresh()
	print("InterfaceOptions:refresh()")
end

-- called when the player presses the Okay button, indicating that settings should be saved
function InterfaceOptions:OnOkay()
	print("InterfaceOptions:okay()")
end

-- called when the player presses the Cancel button, indicating that changes made should be discarded
function InterfaceOptions:OnCancel()
	print("InterfaceOptions:cancel()")
end

-- called when the player presses the Defaults button, indicating that default settings for the addon should be restored
function InterfaceOptions:OnDefault()
	print("InterfaceOptions:default()")
end

function InterfaceOptions:Init()
	self.panel = CreateFrame("Frame")
	self.panel.name = "Dudechat EPGP"
	self.panel.refresh = self.OnRefresh
	self.panel.okay = self.OnOkay
	self.panel.cancel = self.OnCancel
	self.panel.default = self.OnDefault

	local titletext = self.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", 14, -10)
	titletext:SetPoint("TOPRIGHT", -14, -10)
	titletext:SetJustifyH("LEFT")
	titletext:SetHeight(24)
	titletext:SetText("Dudechat EPGP")
end

function InterfaceOptions:AddCheckbox(x, y, tooltip)
	local checkbox = CreateFrame("CheckButton", nil, self.panel, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", 14, -35)
	checkbox.tooltip = tooltip
	checkbox:SetScript("OnClick", function ()
		print("checkbox onclick")
	end)
	local texture = self.panel:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(1, 0, 0)
	texture:SetAllPoints(checkbox)
	texture:Show()
end

function InterfaceOptions:Connect()
	InterfaceOptions_AddCategory(self.panel)
end
