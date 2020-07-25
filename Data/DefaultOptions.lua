local _, addon = ...

function DEPGP:GetDefaultOptionsData()
	return {
		["version"] = 1,
		["flag"] = true,
		["flag2"] = true,
		["foo.bar"] = 123,
	}
end
