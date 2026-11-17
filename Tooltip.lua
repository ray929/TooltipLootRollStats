-- Tooltip.lua -- 在单位提示框里加统计行与更小字号的更新时间，并处理"数据晚到"后的刷新
local ADDON, ns = ...

local TT = ns.TT
local L = ns.L

local GOLD = "|cffffd100"
local GRAY = "|cff9d9d9d"

local DWELL = 0.6        -- 光标在一个玩家身上停留这么久才发查询，扫过一堆单位时不至于每个都问
local RETRY_GAP = 0.5    -- 有查询在跑时，隔这么久再看一眼

local hoverGUID, hoverToken
local dwellArmed, dwellAt = false, 0
local refreshing = false

local function FormatValue(value)
	if type(value) ~= "number" then
		return GRAY .. "-|r"
	end
	return GOLD .. L.COUNT:format(value) .. "|r"
end

-- 提示框的 FontString 是复用的，改字体或字号会留到后续渲染（包括别的插件写的行），
-- 所以这里只加文本，不碰字体，也不加时间戳。
local function AddStatsLine(tooltip, entry)
	local text = L.LINE:format(FormatValue(entry and entry.n), FormatValue(entry and entry.g))
	pcall(tooltip.AddLine, tooltip, text, 1, 1, 1, true)
end

-- 提示框里到底是谁：data.guid 是权威身份，GetUnit() 只作补充
local function ResolveIdentity(tooltip, data)
	local guid, token

	if type(data) == "table" and data.guid then
		local dataGUID = data.guid
		if not TT.IsSecret(dataGUID) and type(dataGUID) == "string" then
			guid = dataGUID
		end
	end

	local ok, unit = pcall(tooltip.GetUnit, tooltip)
	if ok and unit and not TT.IsSecret(unit) and type(unit) == "string" then
		local unitGUID = UnitGUID(unit)
		if unitGUID and not TT.IsSecret(unitGUID) then
			if not guid then guid = unitGUID end
			if unitGUID == guid then token = unit end
		end
	end

	if guid and not token then
		token = TT:FindToken(guid, nil)
	end

	return guid, token
end

local function GetTooltipIdentity(tooltip)
	if not tooltip then return nil end
	local data
	if tooltip.GetPrimaryTooltipData then
		local ok, value = pcall(tooltip.GetPrimaryTooltipData, tooltip)
		if ok then data = value end
	end
	return ResolveIdentity(tooltip, data)
end

local function LooksLikePlayer(guid, token)
	if token then
		local ok, isPlayer = pcall(UnitIsPlayer, token)
		if ok and isPlayer then return true end
	end
	return type(guid) == "string" and guid:sub(1, 7) == "Player-"
end

local function IsSelfUnit(guid, token)
	if guid and TT.playerGUID and guid == TT.playerGUID then return true end
	if token and UnitIsUnit then
		local ok, same = pcall(UnitIsUnit, token, "player")
		if ok and same then return true end
	end
	return false
end

local ArmDwell

local function DwellTick()
	dwellArmed = false
	local guid = hoverGUID
	if not guid then return end

	if not GameTooltip:IsShown() then
		hoverGUID, hoverToken = nil, nil
		return
	end

	local currentGUID, currentToken = GetTooltipIdentity(GameTooltip)
	if currentGUID ~= guid or not LooksLikePlayer(currentGUID, currentToken) then
		return
	end

	local now = GetTime()
	local remaining = DWELL - (now - dwellAt)
	if remaining > 0 then
		-- 夹一个下限：剩余时间可能被浮点算成 0，那样 C_Timer.After(0) 会原地重排、卡死
		ArmDwell(math.max(0.05, remaining))
		return
	end

	if not TT:NeedsRefresh(guid) then return end
	if TT.inFlight then
		ArmDwell(RETRY_GAP)
		return
	end

	TT:StartRequest(guid, hoverToken)
end

ArmDwell = function(delay)
	if dwellArmed then return end
	dwellArmed = true
	C_Timer.After(delay or DWELL, DwellTick)
end

local function NoteHover(guid, token)
	if guid ~= hoverGUID then
		hoverGUID, hoverToken = guid, token
		dwellAt = GetTime()
	else
		hoverToken = token or hoverToken
	end
	ArmDwell()
end

local function TooltipUsable(tooltip)
	if tooltip.IsForbidden then
		local ok, forbidden = pcall(tooltip.IsForbidden, tooltip)
		if not ok or forbidden then return false end
	end
	return true
end

local function OnUnitTooltip(tooltip, data)
	if not tooltip or not TooltipUsable(tooltip) then return end

	local guid, token = ResolveIdentity(tooltip, data)
	if not guid or not LooksLikePlayer(guid, token) then return end

	local entry
	if IsSelfUnit(guid, token) then
		entry = TT:SelfStats()
	else
		entry = TT:GetEntry(guid)
		if TT:NeedsRefresh(guid) then
			NoteHover(guid, token)
		end
	end

	AddStatsLine(tooltip, entry)
end

-- 数据到手后，如果提示框还停在这个人身上，重建一次让它显示新数字
function ns.OnDataUpdated(guid)
	if not guid or refreshing then return end
	if not GameTooltip:IsShown() then return end
	if not TooltipUsable(GameTooltip) then return end

	local currentGUID, currentToken = GetTooltipIdentity(GameTooltip)
	if currentGUID ~= guid or not currentToken then return end

	refreshing = true
	local ok = pcall(GameTooltip.SetUnit, GameTooltip, currentToken)
	if ok then
		pcall(GameTooltip.Show, GameTooltip)
	end
	refreshing = false
end

-- 一次查询结束后，光标如果还停在需要数据的人身上，重新排一次
function ns.OnRequestDone()
	if not GameTooltip:IsShown() then return end
	local guid, token = GetTooltipIdentity(GameTooltip)
	if not guid or not LooksLikePlayer(guid, token) then return end
	if TT:NeedsRefresh(guid) then
		NoteHover(guid, token)
	end
end

function ns.InstallTooltip()
	local installed = false
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
		and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
		installed = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, OnUnitTooltip)
	end
	if not installed then
		GameTooltip:HookScript("OnTooltipSetUnit", function(self)
			OnUnitTooltip(self)
		end)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
-- 事件名在某些客户端版本上可能不存在，注册失败就靠轮询兜底，不要让插件加载失败
pcall(frame.RegisterEvent, frame, "INSPECT_ACHIEVEMENT_READY")
frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON then
			TT:Init()
		end
	elseif event == "PLAYER_LOGIN" then
		TT.playerGUID = UnitGUID("player")
		ns.InstallTooltip()
		-- 统计项已被暴雪移除，插件再也取不到数，登录时说一声，免得被当成网络或距离问题
		TT.AddChat(L.MSG_RETIRED)
	elseif event == "INSPECT_ACHIEVEMENT_READY" then
		TT:OnAchievementReady()
	end
end)
