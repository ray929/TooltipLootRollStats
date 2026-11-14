-- Commands.lua -- 斜杠命令
local ADDON, ns = ...

local TT = ns.TT
local L = ns.L

local function PrintHelp()
	TT.AddChat(L.MSG_HELP1)
	TT.AddChat(L.MSG_HELP2)
	TT.AddChat(L.MSG_HELP3)
	TT.AddChat(L.MSG_HELP4)
	TT.AddChat(L.MSG_HELP5)
end

SLASH_TOOLTIPLOOTROLLSTATS1 = "/tlrs"
SLASH_TOOLTIPLOOTROLLSTATS2 = "/lootrollstats"
SlashCmdList["TOOLTIPLOOTROLLSTATS"] = function(msg)
	msg = tostring(msg or "")
	msg = msg:gsub("^%s+", ""):gsub("%s+$", ""):lower()

	if msg == "" then
		TT.AddChat(L.MSG_STATUS:format(TT:CacheCount()))
	elseif msg == "help" then
		PrintHelp()
	elseif msg == "clear" then
		TT.AddChat(L.MSG_CLEARED:format(TT:ClearCache()))
	elseif msg == "debug" then
		TT.debug = not TT.debug
		TT.AddChat(L.MSG_DEBUG:format(TT.debug and L.MSG_ON or L.MSG_OFF))
	elseif msg == "target" then
		if not UnitExists("target") or not UnitIsPlayer("target") then
			TT.AddChat(L.MSG_NO_TARGET)
			return
		end
		local guid = UnitGUID("target")
		if not guid or TT.IsSecret(guid) then
			TT.AddChat(L.MSG_NO_TARGET)
			return
		end
		TT.failedAt[guid] = nil
		if TT:StartRequest(guid, "target", true) then
			TT.AddChat(L.MSG_REQUESTED:format(UnitName("target") or "?"))
		elseif TT.inFlight then
			TT.AddChat(L.MSG_BUSY)
		else
			TT.AddChat(L.MSG_FAILED)
		end
	elseif msg == "self" then
		local entry = TT:SelfStats()
		if entry then
			TT.AddChat(L.MSG_SELF:format(
				entry.n and tostring(entry.n) or "-",
				entry.g and tostring(entry.g) or "-"))
		else
			TT.AddChat(L.MSG_SELF_NODATA)
		end
	else
		PrintHelp()
	end
end
