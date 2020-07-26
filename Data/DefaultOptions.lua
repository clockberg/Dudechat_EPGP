local _, addon = ...

function DEPGP:GetDefaultOptionsData()
	return {
		["version"] = 1,
		["flag"] = true,
		["flag2"] = true,
		["foo.bar"] = 123,
		["item_dist_window.x"] = 200,
		["item_dist_window.y"] = -200,
		["item_dist_window.lock"] = false,
	}
end
