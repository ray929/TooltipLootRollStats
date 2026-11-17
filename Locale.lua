-- Locale.lua -- 三套文案 + 运行时语言切换（默认英语，客户端是简中/繁中时用对应中文）
local ADDON, ns = ...

local L = {}
ns.L = L

ns.LANG_NAMES = {
	auto = "auto",
	enUS = "English",
	zhCN = "简体中文",
	zhTW = "繁體中文",
}

local DEFAULT_LANGUAGE = "enUS"

local STRINGS = {}

STRINGS.enUS = {
	LINE = "Need: %s  Greed: %s",
	COUNT = "%d",
	MSG_STATUS = "%d cached entries. Type /tlrs help for commands.",
	MSG_CLEARED = "Cache cleared, %d entries removed.",
	MSG_NO_TARGET = "Your target is not a player.",
	MSG_REQUESTED = "Requested data for %s; the tooltip refreshes when the server answers.",
	MSG_BUSY = "Another query is already running, try again in a moment.",
	MSG_FAILED = "Query failed: the target cannot be inspected or is out of range.",
	MSG_SELF = "You - Need: %s, Greed: %s",
	MSG_SELF_NODATA = "You - could not read statistics.",
	MSG_DEBUG = "Debug output: %s",
	MSG_ON = "on",
	MSG_OFF = "off",
	MSG_LANG = "Language: %s",
	MSG_LANG_SET = "Language switched to %s.",
	MSG_LANG_USAGE = "Usage: /tlrs lang auto|enUS|zhCN|zhTW",
	MSG_HELP1 = "/tlrs          show cache status",
	MSG_HELP2 = "/tlrs clear    wipe the cache",
	MSG_HELP3 = "/tlrs target   query your current target now",
	MSG_HELP4 = "/tlrs self     print your own roll counts",
	MSG_HELP5 = "/tlrs debug    toggle debug output",
	MSG_HELP6 = "/tlrs lang     language: auto, enUS, zhCN, zhTW",
	MSG_RETIRED = "No longer works: Blizzard removed the Need rolls and Greed rolls statistics. Nice job, Blizzard! Enjoy this... whatever it is.",
	MSG_RETIRED_CLEARED = "No longer works: Blizzard removed the Need rolls and Greed rolls statistics. The cache has been cleared, you can uninstall the addon now...",
}

STRINGS.zhCN = {
	LINE = "需求: %s  贪婪: %s",
	COUNT = "%d次",
	MSG_STATUS = "缓存 %d 条记录。输入 /tlrs help 查看命令。",
	MSG_CLEARED = "已清空缓存，共 %d 条。",
	MSG_NO_TARGET = "当前目标不是玩家，无法查询。",
	MSG_REQUESTED = "已请求 %s 的数据，等服务器回包后提示框会自动刷新。",
	MSG_BUSY = "正在查询其他玩家，请稍后再试。",
	MSG_FAILED = "查询失败：目标无法观察，或已经离开范围。",
	MSG_SELF = "自己 — 需求: %s，贪婪: %s",
	MSG_SELF_NODATA = "自己 — 读取统计失败。",
	MSG_DEBUG = "调试输出：%s",
	MSG_ON = "开",
	MSG_OFF = "关",
	MSG_LANG = "当前语言：%s",
	MSG_LANG_SET = "语言已切换为 %s。",
	MSG_LANG_USAGE = "用法：/tlrs lang auto|enUS|zhCN|zhTW",
	MSG_HELP1 = "/tlrs          查看缓存状态",
	MSG_HELP2 = "/tlrs clear    清空缓存",
	MSG_HELP3 = "/tlrs target   立即查询当前目标",
	MSG_HELP4 = "/tlrs self     打印自己的掷骰次数",
	MSG_HELP5 = "/tlrs debug    开关调试输出",
	MSG_HELP6 = "/tlrs lang     切换语言：auto / enUS / zhCN / zhTW",
	MSG_RETIRED = "已失效！暴雪把成就统计里的「需求掷骰次数」和「贪婪掷骰次数」两项移除了。干的漂亮，暴雪！尽情享受这坨我说不上来是什么的东西吧！",
	MSG_RETIRED_CLEARED = "已失效！暴雪把成就统计里的「需求掷骰次数」和「贪婪掷骰次数」两项移除了，缓存已经清空，您可以卸载本插件了...",
}

STRINGS.zhTW = {
	LINE = "需求: %s  貪婪: %s",
	COUNT = "%d次",
	MSG_STATUS = "快取 %d 筆記錄。輸入 /tlrs help 查看指令。",
	MSG_CLEARED = "已清空快取，共 %d 筆。",
	MSG_NO_TARGET = "目前目標不是玩家，無法查詢。",
	MSG_REQUESTED = "已請求 %s 的資料，等伺服器回包後提示框會自動更新。",
	MSG_BUSY = "正在查詢其他玩家，請稍後再試。",
	MSG_FAILED = "查詢失敗：目標無法觀察，或已經離開範圍。",
	MSG_SELF = "自己 — 需求: %s，貪婪: %s",
	MSG_SELF_NODATA = "自己 — 讀取統計失敗。",
	MSG_DEBUG = "除錯輸出：%s",
	MSG_ON = "開",
	MSG_OFF = "關",
	MSG_LANG = "目前語言：%s",
	MSG_LANG_SET = "語言已切換為 %s。",
	MSG_LANG_USAGE = "用法：/tlrs lang auto|enUS|zhCN|zhTW",
	MSG_HELP1 = "/tlrs          查看快取狀態",
	MSG_HELP2 = "/tlrs clear    清空快取",
	MSG_HELP3 = "/tlrs target   立即查詢目前目標",
	MSG_HELP4 = "/tlrs self     列印自己的擲骰次數",
	MSG_HELP5 = "/tlrs debug    開關除錯輸出",
	MSG_HELP6 = "/tlrs lang     切換語言：auto / enUS / zhCN / zhTW",
	MSG_RETIRED = "已失效！暴雪把成就統計裡的「需求擲骰次數」和「貪婪擲骰次數」兩項移除了。幹得漂亮，暴雪！盡情享受這坨我說不上來是什麼的東西吧！",
	MSG_RETIRED_CLEARED = "已失效！暴雪把成就統計裡的「需求擲骰次數」和「貪婪擲骰次數」兩項移除了，快取已經清空，您可以卸載本插件了...",
}

local function ClientLanguage()
	local locale = (GetLocale and GetLocale()) or DEFAULT_LANGUAGE
	if STRINGS[locale] then return locale end
	return DEFAULT_LANGUAGE
end
ns.ClientLanguage = ClientLanguage

-- pref 为 auto/nil 时跟随客户端；其余非中文客户端一律落回英语
function ns.ResolveLanguage(pref)
	if pref and STRINGS[pref] then return pref end
	return ClientLanguage()
end

function ns.SetLanguage(code)
	local source = STRINGS[code]
	if not source then
		code = ClientLanguage()
		source = STRINGS[code]
	end

	for key in pairs(L) do
		L[key] = nil
	end
	for key, value in pairs(source) do
		L[key] = value
	end
	L.language = code
end

ns.SetLanguage(ClientLanguage())
