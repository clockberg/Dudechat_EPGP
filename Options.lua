local _, ns = ...

local Options = {};
Options.__index = Options;
function Options:new()
	local self = {};
	setmetatable(self, Options);
	self.panel = nil;
	return self;
end

-- called when the frame is initially displayed, and after requesting the default values to be restored
function Options:OnRefresh()
	print("Options:refresh()");
end

-- called when the player presses the Okay button, indicating that settings should be saved
function Options:OnOkay()
	print("Options:okay()");
end

-- called when the player presses the Cancel button, indicating that changes made should be discarded
function Options:OnCancel()
	print("Options:cancel()");
end

-- called when the player presses the Defaults button, indicating that default settings for the addon should be restored
function Options:OnDefault()
	print("Options:default()");
end

function Options:Init()
	self.panel = CreateFrame("Frame");
	self.panel.name = "Dudechat EPGP";
	self.panel.refresh = self.OnRefresh;
	self.panel.okay = self.OnOkay;
	self.panel.cancel = self.OnCancel;
	self.panel.default = self.OnDefault;

	local titletext = self.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	titletext:SetPoint("TOPLEFT", 14, -10);
	titletext:SetPoint("TOPRIGHT", -14, -10);
	titletext:SetJustifyH("LEFT");
	titletext:SetHeight(24);
	titletext:SetText("Dudechat EPGP");
end

function Options:AddCheckbox(x, y, tooltip)
	local checkbox = CreateFrame("CheckButton", nil, self.panel, "ChatConfigCheckButtonTemplate");
	checkbox:SetPoint("TOPLEFT", 14, -35);
	checkbox.tooltip = tooltip;
	checkbox:SetScript("OnClick", function ()
		print("checkbox onclick");
	end)
	local texture = self.panel:CreateTexture(nil, "BACKGROUND");
	texture:SetColorTexture(1, 0, 0)
	texture:SetAllPoints(checkbox)
	texture:Show()
end

function Options:Connect()
	InterfaceOptions_AddCategory(self.panel);
end

local opts = Options:new();
opts:Init();
opts:AddCheckbox(14, -35, "CheckboxName", "CheckboxTooltip");
opts:Connect();
