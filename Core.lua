-- Core.lua -- 缓存、查询队列与成就比较数据读取
local ADDON, ns = ...

local L = ns.L
local TT = {}
ns.TT = TT

-- 成就统计 ID
TT.STAT_NEED = 1044    -- 需求掷骰次数
TT.STAT_GREED = 1043   -- 贪婪掷骰次数

TT.CACHE_TTL = 24 * 3600      -- 超过一天的数据允许后台刷新
TT.RETRY_AFTER = 300          -- 查询失败后同一玩家 5 分钟内不再重试
TT.REQUEST_TIMEOUT = 6        -- 服务端迟迟不回包就当失败
TT.CACHE_MAX = 2000           -- 缓存条数上限
TT.CACHE_KEEP_DAYS = 180      -- 超过半年的记录直接清掉

TT.debug = false
TT.failedAt = {}
TT.inFlight = nil
TT.stores = 0
TT.playerGUID = nil

local DB

local function IsSecret(value)
	if issecretvalue == nil then return false end
	return issecretvalue(value) and true or false
end
TT.IsSecret = IsSecret

-- 统计值可能是数字，也可能是带千分位的字符串
local function ToNumber(value)
	if value == nil then return nil end
	if IsSecret(value) then return nil end
	local kind = type(value)
	if kind == "number" then
		return value
	elseif kind == "string" then
		return tonumber((value:gsub("[,%s]", "")))
	end
	return nil
end
TT.ToNumber = ToNumber

local function AddChat(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0TooltipLootRollStats|r " .. tostring(msg))
	end
end
TT.AddChat = AddChat

local function Debug(msg)
	if TT.debug then
		AddChat("|cff808080" .. tostring(msg) .. "|r")
	end
end
TT.Debug = Debug

function TT:Init()
	TooltipLootRollStatsDB = TooltipLootRollStatsDB or {}
	DB = TooltipLootRollStatsDB
	DB.cache = DB.cache or {}
	self.playerGUID = UnitGUID("player")
	self:Prune()
end

-- 清掉过期记录，并把总条数压到上限以内
function TT:Prune()
	if not DB then return end
	local cache = DB.cache
	local cutoff = time() - self.CACHE_KEEP_DAYS * 86400
	local alive, doomed = {}, {}

	for guid, entry in pairs(cache) do
		if type(entry) ~= "table" or type(entry.t) ~= "number" or entry.t < cutoff then
			doomed[#doomed + 1] = guid
		else
			alive[#alive + 1] = { guid = guid, t = entry.t }
		end
	end

	for _, guid in ipairs(doomed) do
		cache[guid] = nil
	end

	if #alive > self.CACHE_MAX then
		table.sort(alive, function(a, b) return a.t < b.t end)
		for i = 1, #alive - self.CACHE_MAX do
			cache[alive[i].guid] = nil
		end
	end
end

function TT:GetEntry(guid)
	if not DB or not guid then return nil end
	local entry = DB.cache[guid]
	if type(entry) == "table" and type(entry.t) == "number" then
		return entry
	end
	return nil
end

function TT:IsFresh(entry)
	return entry ~= nil and type(entry.t) == "number" and (time() - entry.t) < self.CACHE_TTL
end

-- 这条记录是否值得再向服务端问一次
function TT:NeedsRefresh(guid)
	if not guid or not DB then return false end
	if guid == self.playerGUID then return false end
	if self:IsFresh(DB.cache[guid]) then return false end
	if self.inFlight and self.inFlight.guid == guid then return false end
	local failedAt = self.failedAt[guid]
	if failedAt and (GetTime() - failedAt) < self.RETRY_AFTER then return false end
	return true
end

function TT:Store(guid, need, greed)
	if not DB or not guid then return end
	if need == nil and greed == nil then return end

	DB.cache[guid] = { n = need, g = greed, t = time() }
	self.stores = self.stores + 1
	if self.stores % 250 == 0 then
		self:Prune()
	end
end

function TT:CacheCount()
	if not DB then return 0 end
	local count = 0
	for _ in pairs(DB.cache) do
		count = count + 1
	end
	return count
end

function TT:ClearCache()
	local count = self:CacheCount()
	if DB then DB.cache = {} end
	self.failedAt = {}
	return count
end

local function ReadStat(readFunc, id)
	if type(readFunc) ~= "function" then return nil end
	local ok, value = pcall(readFunc, id)
	if not ok then return nil end
	return ToNumber(value)
end

-- 自己的数据不需要比较，直接读本角色统计
function TT:SelfStats()
	local need = ReadStat(GetStatistic, self.STAT_NEED)
	local greed = ReadStat(GetStatistic, self.STAT_GREED)
	if need == nil and greed == nil then return nil end
	return { n = need, g = greed }
end

-- 比较对象的数据，必须在 INSPECT_ACHIEVEMENT_READY 之后读
function TT:ReadComparison()
	local need = ReadStat(GetComparisonStatistic, self.STAT_NEED)
	local greed = ReadStat(GetComparisonStatistic, self.STAT_GREED)
	return need, greed
end

function TT:ClearComparison()
	if ClearAchievementComparisonUnit then
		pcall(ClearAchievementComparisonUnit)
	end
end

function TT:TokenMatches(token, guid)
	if token == nil or IsSecret(token) then return false end
	if type(token) ~= "string" or guid == nil then return false end
	if not UnitExists(token) then return false end
	local tokenGUID = UnitGUID(token)
	if tokenGUID == nil or IsSecret(tokenGUID) then return false end
	return tokenGUID == guid
end

-- 找一个能查到该 GUID 的单位标记：优先用提示框给的，其次是队伍/团队/光标
function TT:FindToken(guid, preferred)
	if not guid then return nil end
	if preferred and self:TokenMatches(preferred, guid) then return preferred end
	if guid == self.playerGUID then return "player" end

	if IsInRaid and IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local token = "raid" .. i
			if self:TokenMatches(token, guid) then return token end
		end
	elseif IsInGroup and IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do
			local token = "party" .. i
			if self:TokenMatches(token, guid) then return token end
		end
	end

	if type(UnitTokenFromGUID) == "function" then
		local ok, token = pcall(UnitTokenFromGUID, guid)
		if ok and self:TokenMatches(token, guid) then return token end
	end

	if self:TokenMatches("mouseover", guid) then return "mouseover" end
	return nil
end

function TT:StartRequest(guid, token, force)
	if not guid or self.inFlight then return false end
	if not force and not self:NeedsRefresh(guid) then return false end

	local unit = self:FindToken(guid, token)
	if not unit then
		self.failedAt[guid] = GetTime()
		Debug("找不到可查询的单位标记: " .. tostring(guid))
		return false
	end

	if CanInspect and not CanInspect(unit) then
		self.failedAt[guid] = GetTime()
		Debug("无法观察: " .. tostring(unit))
		return false
	end

	self:ClearComparison()
	local ok, ret = pcall(SetAchievementComparisonUnit, unit)
	if not ok or ret == false then
		self.failedAt[guid] = GetTime()
		Debug("设置比较单位失败: " .. tostring(unit))
		return false
	end

	local req = { guid = guid, unit = unit, startedAt = GetTime() }
	self.inFlight = req
	Debug("发起查询: " .. tostring(unit) .. " " .. tostring(guid))

	-- 主路径是 INSPECT_ACHIEVEMENT_READY；轮询是它没响时的兜底
	local function Poll()
		if self.inFlight ~= req then return end
		local need, greed = self:ReadComparison()
		if need ~= nil and greed ~= nil then
			self:Finish(req, true, need, greed)
			return
		end
		C_Timer.After(0.4, Poll)
	end
	C_Timer.After(0.4, Poll)

	C_Timer.After(self.REQUEST_TIMEOUT, function()
		if self.inFlight == req then
			Debug("查询超时: " .. tostring(req.unit))
			self:Finish(req, false)
		end
	end)

	return true
end

function TT:Finish(req, ok, need, greed)
	if self.inFlight ~= req then return end
	self.inFlight = nil
	self:ClearComparison()

	if ok then
		self:Store(req.guid, need, greed)
		self.failedAt[req.guid] = nil
		Debug(string.format("查询成功: %s 需求=%s 贪婪=%s",
			tostring(req.unit), tostring(need), tostring(greed)))
		if ns.OnDataUpdated then ns.OnDataUpdated(req.guid) end
	else
		self.failedAt[req.guid] = GetTime()
	end

	if ns.OnRequestDone then ns.OnRequestDone() end
end

function TT:OnAchievementReady()
	local req = self.inFlight
	if not req then return end

	local need, greed = self:ReadComparison()
	if need ~= nil or greed ~= nil then
		self:Finish(req, true, need, greed)
	end
	-- 两个都读不到就交给轮询和超时，事件本身不代表数据一定填好了
end
