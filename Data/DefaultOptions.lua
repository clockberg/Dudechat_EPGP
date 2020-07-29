local _, addon = ...

--- Returns the default options for the addon
-- @return <table>
function DEPGP:GetDefaultOptionsData()
	return {
		["item_tooltip_mod.show"] = true,
		["item_dist_window.x"] = 200,
		["item_dist_window.y"] = -200,
		["item_dist_window.lock"] = false,
	}
end
