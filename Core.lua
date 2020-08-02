local _, addon = ...

-- Module setup
local M = {}
addon.Core = M
local _G = _G
local dd = function (msg) addon.debug("Core." .. msg) end
setfenv(1, M)

--- Load this module
function Load()
	dd("Load")
	addon.Config.Load()
	addon.Options.Load()
	addon.ItemTooltip.Load()
end
