# TooltipLootRollStats

## English

**Display only. Do not read it as a verdict on anyone.**

The two numbers are Blizzard's own lifetime counters. They say how often a player picked Need or Greed, nothing about whether any single roll was fair.

### What it does

Hovering a player adds two lines to the unit tooltip:

```
Need: 128  Greed: 342
(updated:2026-11-14 13:40)
```

The values are read from the achievement statistics (1044 Need rolls, 1043 Greed rolls) through the achievement comparison API. Until the server answers you see `Need: -  Greed: -`, and the tooltip refreshes by itself when the data arrives.

### Features

- Cached per player GUID, shared by every character on the account.
- A query starts only after the cursor rests 0.6s on the same player, and only one runs at a time.
- Cached entries show instantly; entries older than 24h refresh in the background.
- Failed lookups (out of range, not inspectable, timeout) are not cached and are retried after 5 minutes.
- Records older than 180 days, or beyond 2000 entries, are pruned.
- Your own character is read from local statistics, no query needed.
- English, Simplified Chinese and Traditional Chinese, switchable without reloading.

### Slash commands

| Command | Action |
| --- | --- |
| `/tlrs` | Show cache status |
| `/tlrs clear` | Wipe the cache |
| `/tlrs target` | Query your current target now |
| `/tlrs self` | Print your own two counters |
| `/tlrs debug` | Toggle debug output |
| `/tlrs lang` | Show or switch language: `auto`, `enUS`, `zhCN`, `zhTW` |

### Limits

- Only players the client lets you inspect. Out of range, other faction, or a different phase keeps showing `-`.
- One achievement comparison runs at a time, so a second player waits for the first to finish or time out.
- A tooltip line holds a single font size, so the timestamp sits on its own line, two points smaller than the values.
- The numbers are lifetime counters as the client reports them. The addon adds no estimates and no interpretation.

## 简体中文

**仅用于数据显示，请勿对号入座。**

这两个数字是暴雪自己的终身计数，只说明该玩家点过多少次需求 / 贪婪，不构成对任何一次分配的判断。

### 简介

鼠标指向玩家时，在单位提示框加两行：

```
需求: 128次  贪婪: 342次
(updated:2026-11-14 13:40)
```

数值取自成就统计（1044 需求掷骰次数、1043 贪婪掷骰次数），通过成就比较接口向服务器查询。数据没回来之前显示 `需求: -  贪婪: -`，回来后提示框会自己刷新。

### 功能

- 按玩家 GUID 缓存，同一账号下所有角色共用一份。
- 光标在同一个人身上停留 0.6 秒才发起查询，且同一时间只跑一个，扫过一群人不会挨个去问。
- 有缓存立刻显示；超过 24 小时的记录在后台刷新。
- 查询失败（超出范围、不可观察、超时）不写缓存，同一个人 5 分钟内不重试。
- 记录超过 180 天或总数超过 2000 条时自动清理。
- 自己的角色直接读本地统计，不发查询。
- 英语 / 简体中文 / 繁体中文三套文案，切换后立即生效，不用重载。

### 命令

| 命令 | 作用 |
| --- | --- |
| `/tlrs` | 查看缓存条数 |
| `/tlrs clear` | 清空缓存 |
| `/tlrs target` | 立即查询当前目标 |
| `/tlrs self` | 打印自己的两项次数 |
| `/tlrs debug` | 开关调试输出 |
| `/tlrs lang` | 查看或切换语言：`auto`、`enUS`、`zhCN`、`zhTW` |

### 限制

- 只能读到客户端允许观察的玩家。距离过远、跨阵营、副本相位不同，都会一直显示 `-`。
- 同一时间只能比较一个玩家，快速换目标时后一个要等前一个结束或超时。
- 提示框一行只能有一种字号，所以更新时间单独占一行，比数值那行小 2 点。
- 数字是客户端给出的终身计数，插件不做推算，也不做任何评价。

## 正體中文

**僅供資料顯示，請勿對號入座。**

這兩個數字是暴雪自己的終身計數，只說明該玩家點過多少次需求 / 貪婪，不構成對任何一次分配的判斷。

### 簡介

滑鼠移到玩家身上時，在單位提示框加兩行：

```
需求: 128次  貪婪: 342次
(updated:2026-11-14 13:40)
```

數值取自成就統計（1044 需求擲骰次數、1043 貪婪擲骰次數），透過成就比較介面向伺服器查詢。資料還沒回來之前顯示 `需求: -  貪婪: -`，回來後提示框會自己更新。

### 功能

- 依玩家 GUID 快取，同一帳號下所有角色共用一份。
- 滑鼠在同一個人身上停留 0.6 秒才發起查詢，且同一時間只跑一個，掃過一群人不會逐個去問。
- 有快取立刻顯示；超過 24 小時的記錄在背景更新。
- 查詢失敗（超出範圍、無法觀察、逾時）不寫入快取，同一個人 5 分鐘內不重試。
- 記錄超過 180 天或總數超過 2000 筆時自動清理。
- 自己的角色直接讀本機統計，不發查詢。
- 英文 / 簡體中文 / 繁體中文三套文案，切換後立即生效，不用重新載入。

### 指令

| 指令 | 作用 |
| --- | --- |
| `/tlrs` | 查看快取筆數 |
| `/tlrs clear` | 清空快取 |
| `/tlrs target` | 立即查詢目前目標 |
| `/tlrs self` | 列印自己的兩項次數 |
| `/tlrs debug` | 開關除錯輸出 |
| `/tlrs lang` | 查看或切換語言：`auto`、`enUS`、`zhCN`、`zhTW` |

### 限制

- 只能讀到客戶端允許觀察的玩家。距離太遠、跨陣營、副本相位不同，都會一直顯示 `-`。
- 同一時間只能比較一個玩家，快速換目標時後一個要等前一個結束或逾時。
- 提示框一行只能有一種字級，所以更新時間單獨佔一行，比數值那行小 2 點。
- 數字是客戶端給出的終身計數，插件不做推算，也不做任何評價。
