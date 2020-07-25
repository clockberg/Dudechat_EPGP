local _, ns = ...

local DEPGP = {};
DEPGP.__index = DEPGP;
function DEPGP:new()
	local self = {};
	setmetatable(self, DEPGP);
	self.frame = nil;
	return self;
end

function DEPGP:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == ns.ADDON_NAME then
		if DEPGPConfig == nil then
			DEPGPConfig = {};
		end
		if DEPGPConfig.count == nil then
			DEPGPConfig.count = 0;
		end
		DEPGPConfig.count = DEPGPConfig.count + 1;
		print("count = " .. DEPGPConfig.count)
	end
end

function DEPGP:init()
	self.frame = CreateFrame("FRAME");
	self.frame:RegisterEvent("ADDON_LOADED");
	self.frame:RegisterEvent("PLAYER_LOGOUT");
	self.frame:SetScript("OnEvent", DEPGP.OnEvent);
end

ns.app = DEPGP:new();
ns.app:init();

