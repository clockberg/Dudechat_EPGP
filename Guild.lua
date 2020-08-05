local _, addon = ...

-- Module setup
local M = {}
addon.Guild = M
local _G = _G
setfenv(1, M)

--- Load this module
function Load()
	if _G.DEPGPStorage.roster == nil then
		_G.DEPGPStorage.roster = {}
	end
	RefreshRoster()
end

--- Loads player data from the guild roster
-- The only way to get an updated officer note is through
-- GetGuildRosterInfo(<gindex>), and the only way to get `gindex`
-- is by scanning the whole guild roster and saving it for each player.
-- Also the `gindex` changes constantly, based on logins, logouts,
-- sorting, etc. So we have to repeatedly load the guild roster
-- to refresh `gindex`.
function RefreshRoster()
	local num_members, _, _ = _G.GetNumGuildMembers()
	if num_members == 0 then
		return
	end

	_G.DEPGPStorage.roster = {}
	for i = 1, num_members do
		local data = GetFreshPlayerData(i)
		_G.DEPGPStorage.roster[data.name] = data
	end
end

--- Returns guild roster info for a specific player
-- @param gindex <number> The guild roster index of the player.
--   Note: changes frequently.
-- @return <table>
function GetFreshPlayerData(gindex)
	-- dd("GetFreshPlayerData(" .. gindex ..")")
	local name, _, _, level, _, _, _, officer_note, _, _, class, _, _, _, _, _, guid = _G.GetGuildRosterInfo(gindex)
	return {
		["name"] = name,
		["level"] = level,
		["officer_note"] = officer_note,
		["class"] = class,
		["guid"] = guid,
		["gindex"] = gindex,
	}
end

--- Returns player data for the given player name
-- If the response from the server doesn't match the local roster cache,
-- we need to reload the whole roster in order to get accurate data.
-- @param name <string> The name of the player to return data for
-- @return <table> or <nil>
function GetPlayerData(name)
	local cached_data = _G.DEPGPStorage.roster[name]
	if cached_data == nil then
		-- No record of this player
		-- Maybe not in the guild, maybe another problem
		return nil
	end
	local fresh_data = GetFreshPlayerData(cached_data.gindex)

	-- See if the fresh data matches the cache
	if fresh_data.name == name then
		return fresh_data
	end

	-- Local roster cache is dirty, need to refresh
	RefreshRoster()
	return _G.DEPGPStorage.roster[name]
end

--- Returns EP and GP from the given officer note
-- @param note <string> The officer note to parse
-- @return <table> {"ep" = <number>, "gp" = <number>}
function ParseOfficerNote(note)
	local ep, gp = _G.string.match(note, "(%d+)%s*,%s*(%d+)")
	if ep == nil or not ep then ep = 0 end
	if gp == nil or not gp then gp = 0 end
	return {
		["ep"] = _G.tonumber(ep),
		["gp"] = _G.tonumber(gp),
	}
end
