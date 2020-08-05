local _, addon = ...

-- Module setup
local M = {}
addon.Core = M
local _G = _G
setfenv(1, M)

--- Load this module
function Load()
	addon.Config.Load()
	addon.Options.Load()
	addon.Guild.Load()
	addon.ItemTooltip.Load()
	addon.ItemDistribute.Load()
end
