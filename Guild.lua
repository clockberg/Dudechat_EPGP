local _, addon = ...

-- Module setup
local M = {}
addon.Guild = M
local _G = _G
setfenv(1, M)

--- Load this module
function Load()
	addon.data = addon.data or {}
	if addon.data.roster == nil then
		addon.data.roster = {}
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

	addon.data.roster = {}
	for i = 1, num_members do
		local player_data = GetFreshPlayerData(i)
		addon.data.roster[player_data.name] = player_data
	end
end

--- Returns guild roster info for a specific player
-- @param gindex <number> The guild roster index of the player.
--   Note: changes frequently.
-- @return <table>
function GetFreshPlayerData(gindex)
	local fullname, _, _, level, _, _, _, officer_note, _, _, class, _, _, _, _, _, guid = _G.GetGuildRosterInfo(gindex)
	return {
		["name"] = fullname,
		["level"] = level,
		["officer_note"] = officer_note,
		["class"] = class,
		["level"] = level,
		["guid"] = guid,
		["gindex"] = gindex,
	}
end

--- Returns player data for the given character name
-- If the response from the server doesn't match the local roster cache,
-- we need to reload the whole roster in order to get accurate data.
-- @param player_name <string> The name of the character to return data for
-- @return <table> or <nil>
function GetPlayerData(player_name)
	local player_fullname = GetPlayerFullname(player_name)
	local cached_data = addon.data.roster[player_fullname]
	if cached_data == nil then
		-- No record of this player
		-- Maybe not in the guild, maybe another problem
		return nil
	end
	local fresh_data = GetFreshPlayerData(cached_data.gindex)

	-- See if the fresh data matches the cache
	if fresh_data.player_fullname == player_fullname then
		return fresh_data
	end

	-- Local roster cache is dirty, need to refresh
	RefreshRoster()
	return addon.data.roster[player_fullname]
end

--- Returns the class of the player from the cached data
-- @param player_name <string>
-- @return string
function GetPlayerClass(player_name)
	local player_fullname = GetPlayerFullname(player_name)
	local player_data = addon.data.roster[player_fullname]
	if player_data then return player_data.class end
	return nil
end

--- Returns EP and GP from the given officer note
-- @param note <string> The officer note to decode
-- @return <table> {"ep" = <number>, "gp" = <number>}
function DecodeOfficerNote(note)
	local ep, gp = _G.string.match(note, "(%d*%.?%d+)%s*,%s*(%d*%.?%d+)")
	if ep == nil or not ep then ep = 0 end
	if gp == nil or not gp then gp = 0 end
	return {
		["ep"] = _G.tonumber(ep),
		["gp"] = _G.tonumber(gp),
	}
end

--- Returns a string for the officer note for the given EPGP
-- @param ep <number>
-- @param gp <number>
-- @return <string>
function EncodeOfficerNote(ep, gp)
	return _G.tostring(ep) .. "," .. _G.tostring(gp)
end

--- Update the EPGP values of the given player
-- @param player_name <string>
-- @param ep_change <number>
-- @param gp_change <number>
function UpdateEPGP(player_name, ep_change, gp_change)
	local player_fullname = GetPlayerFullname(player_name)
	local player_data = GetPlayerData(player_fullname)
	if player_data == nil then
		addon.Core.Error("Could not update player EPGP. Player '" .. player_fullname .. "' not found.")
		return
	end
	local epgp = DecodeOfficerNote(player_data.officer_note)
	epgp.ep = epgp.ep + ep_change
	epgp.gp = epgp.gp + gp_change
	local officer_note = EncodeOfficerNote(epgp.ep, epgp.gp)
	if addon.Core.TEST then
		_G.print("(TEST) GuildRosterSetOfficerNote(" .. officer_note .. ")")
	else
		_G.GuildRosterSetOfficerNote(player_data.gindex, officer_note)
	end
end

--- Returns the full name of the given player (server included)
-- @param player_name <string>
-- @return <string>
function GetPlayerFullname(player_name)
	if _G.string.find(player_name, '-') then
		-- There is already a dash in the player name,
		-- therefore most likely already a fullname
		-- (dashes are not allowed in player names)
		return player_name
	end
	return player_name .. '-' .. _G.GetRealmName()
end
