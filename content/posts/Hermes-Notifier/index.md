---
title: "为Hermes添加主动提醒插件"
date: 2026-11-10T19:05:00+08:00
draft: true
tags: ["AGENT", "HERMES", "技术"]
description: "让你的Hermes摆脱被动的一问一答模式，根据历史会话主动跟进并提醒未闭环事项。"
toc: true
cover: "cover.jpg"
math: true
---

## 使用Muse的体验

前端时间Muse比较火的时候，我也跟风注册了一个，一段时间的体验下来，发现Muse确实是一个产品力比Hermes要高很多的Agent，包括在与用户交互、UI的显示等方面都比Hermes做的要好。但在功能上我认为Muse并没有比Hermes做得更多，而由于之前的一些任务我都放在了Hermes上，Muse在功能上并没有让我有迁移过去的动力。{{<spoiler>}}我在Muse出来之前买了一台Mini主机用来部署Hermes，迁移过去岂不是浪费了😡！{{</spoiler>}}

但是Muse上有一点让我觉得做的很好的，就是他会根据你与他的历史对话不定时主动向你发送还没有完结的事项，通知你是否需要继续这个话题，这一点就很有个人助手的感觉。而Hermes则是一问一答式的，只有你主动安排他才会执行，像一个工具。所以本篇就是通过一个插件来让Hermes实现类似Muse中的主动通知的功能。

[插件仓库](https://github.com/GuGuDaDaDa/hermes-notifier)

## 实现原理

在与 Muse 讨论它的实现方式时，我注意到它会围绕每轮提醒整理一组上下文与下面几种候选文档。

| 文件名 | 生成阶段 | 作用 |
| --- | --- | --- |
| `conversation.md` | Stage 1 | 扫描水位之后的新消息（`# New`），以及按字符预算保留的水位前 24 小时背景消息（`# Earlier`） |
| `tracking.md` | Stage 1 生成，Stage 2 可重写 | 本期扫描时的活跃跟进事项快照；Worker 1 更新追踪库后会重写一次 |
| `scheduled-crons.md` | Stage 1 | 当前已有的定时任务清单、周期、下次运行时间与 `last_status` |
| `sent.md` | Stage 1 | 最近 7 天内已确认 `delivered` 的主动提醒历史 |
| `memory.md` | Stage 1 | 按本轮新消息与活跃事项提取关键词后检索到的相关记忆，并标明读取状态 |
| `context.md` | Stage 1 | 当前 UTC/本地时间、时区、投递平台、记忆源状态、失败 Cron 摘要及 `PROACTIVE_PREFERENCES.md` 全文 |
| `opportunities.md` | Stage 2 | Worker 1 产出的对话驱动候选事项 |
| `prepared.md` | Stage 2 | Worker 2 独立提出的时效性与存量跟进候选事项，附发送文案初稿 |
| `sources.md` | Stage 2 | 按候选事项的 `evidence_refs` 编译其引用的 `[source:N]` 原始证据块，并附近 7 天已投递提醒摘要 |

可以看出，整个流程不是每轮都重新阅读全部历史，而是以上一次已提交的扫描水位为起点，增量检查对话，并把相关上下文和背景信息拼装成快照，供后台调研 Worker 筛选候选事项。参考这个策略，可以设计出如下流程：

```text
确定性整理上下文（脚本，0 Token）
  → 分片只读调研（Worker 1 对话跟进，Worker 2 时效与备稿）
  → 汇总候选与证据
  → 有候选时唤醒主 Agent 逐条裁决并重写提醒
  → 投递与回执核销
  → 根据证据或用户反馈更新、关闭对应跟进事项
```

为了确定每轮扫描范围、保存跟进状态并避免漏发，还需要几张数据表分别记录检查点、事项、候选和投递回执：

- `checkpoints`：记录每一期运行（`run_id`）扫描的时间窗口（`window_start_utc` → `window_end_utc`）和状态（运行中主要使用 `pending` / `committed` / `superseded`）。它决定下一轮从哪个时间点开始扫描，以及异常中断或投递失败时如何回退重扫。
- `tracking_items`：持久化跟进事项（`goal_id`、标题、摘要、`status: active|closed`、`momentum_status: on_track|waiting|stalled|time_sensitive`）。后台调研 Worker 只能新增或更新 `active` 事项，不能关闭或重开事项；只有主 Agent 核实后或用户显式操作时，才能将事项改为 `closed`。
- `candidate_items`：保存每一期 Stage 2 筛出的 `[item:1]..[item:K]` 候选详情、证据编号 `evidence_refs`，以及主 Agent 对每一条候选作出的 `send` / `skip` 裁决、枚举理由（`decision_reason`）和备注。
- `sent_log`：记录主 Agent 决定发送的最终文本及送达状态（`pending` → 后续核销为 `delivered` 或 `failed`），防止漏发，并为 `sent.md` 中近 7 天的已投递账本提供数据源。

这里需要区分三种容易混淆的状态：检查点变为 `committed`，只表示本期扫描与候选处理已经完成；跟进事项变为 `closed`，表示该事项已经办结或被明确放弃；`sent_log` 变为 `delivered`，表示提醒已经确认送达。

确定好实现思路后，就可以开始 Vibe Coding 了。一次提醒的完整运行流程如下。

### 1. 扫描水位与检查点状态流转

已经提交的扫描窗口不应被无意义地重复检测，因此 Stage 1 首先要确定本轮扫描的时间范围。每次运行时，插件会先核销上一轮的投递回执、清理遗留的 `pending` 检查点，再从 `status='committed'` 的记录中取最大的 `window_end_utc` 作为本轮扫描起点。只要一期运行没有变成 `committed`，扫描水位就不会向后推进。

每个检查点的状态流转如下：

1. Stage 2 启动时，先向 `checkpoints` 插入一条 `status='pending'` 的记录。
2. 如果两个 Worker 没有产出任何候选（`K == 0`），Stage 2 直接将其改为 `committed`，推进下次扫描起点，无需唤醒主 Agent。
3. 如果产出候选（`K > 0`），检查点保持 `pending`，把是否推进水位的决策留给 Stage 3。只有主 Agent 对全部 `[item:1]..[item:K]` 作出裁决后，才会将检查点提交为 `committed`。
4. 如果中途出现超时、模型报错或进程被杀，导致检查点一直停在 `pending`，下一轮 Stage 1 会将遗留的 `pending` 全部标为 `superseded`。由于水位只认 `committed`，下一轮会沿用上一次成功提交的边界重扫，不会漏掉未审完的对话。

投递失败时也采用类似的回退机制。主 Agent 决定发送消息并提交后，检查点已经推进到 `committed`，但对应的 `sent_log` 仍是 `delivery_status='pending'`。下一轮 Stage 1 核销回执时，如果发现消息实际未成功投递（例如投递报错、归档丢失或被静默），会在同一个事务中将 `sent_log` 标为 `failed`，并把对应检查点从 `committed` 改回 `superseded`。这样，本次扫描就会退回到上一条 `committed` 的边界，重新评估该时间窗口。

另外，Stage 1 还有两层短路：不在活跃时间窗内时（默认9:00-21:30）直接静默退出；没有新消息、事项变化、时效事项、失败 Cron 或投递回滚时，则以 `no_op` 退出。这两种情况都不会创建新快照或推进水位。

### 2. 拼装上下文快照

取得最近一次已提交扫描窗口的结束时间后，Stage 1 会读取该水位之后到现在的人类对话增量，并按需补充水位前 24 小时内的背景消息。

这里读取的不是未经处理的“全部对话数据”。插件会排除 Cron、subagent、tool、webhook、system 等非人类会话，过滤 Cron/Webhook 镜像消息和内部控制令牌，并对超长消息、代码块和背景上下文执行截断或预算裁剪。随后，Stage 1 通过确定性代码将这些内容写入六份输入快照；Stage 2 启动时才创建本期的 `pending` 检查点，完成调研后再生成候选与证据文件。

### 3. 分片筛选候选事项

这一阶段由两个输入不同的 Worker 串行完成：

- **Worker 1** 读取 `conversation.md`、原 `tracking.md`、`scheduled-crons.md` 和防干扰规则，识别未闭环承诺、外部阻塞、时间锚点和中断的工作流。它可以新增或更新活跃跟进事项，并产出对话驱动的 `opportunities` 候选。每条候选都必须用 `evidence_refs` 引用一个或多个真实存在的 `[source:N]` 标记。
- Worker 1 的事项更新落库后，系统会重写 `tracking.md`，把最新的事项状态接力给下一个 Worker。
- **Worker 2** 不读取 Worker 1 的候选列表，也不重新扫描原始对话，而是读取更新后的 `tracking.md`、`memory.md`、`context.md` 和 `sent.md`，独立提出时效性与存量跟进的 `prepared` 候选，并为每条候选附上一段文案初稿。

两个 Worker 的结果经过结构化校验后，会统一编号为 `[item:1]..[item:K]` 并写入 `candidate_items`。Stage 2 最后生成 `opportunities.md`、`prepared.md` 和 `sources.md`。其中 `sources.md` 由 Python 按候选引用的 `[source:N]` 反查并抽取原始证据块，不是由模型凭空编写的摘要。

如果最终 `K == 0`，Stage 2 会直接提交检查点并静默结束；只有 `K > 0` 时，才会进入主 Agent 审稿阶段。

### 4. 主 Agent 审稿与发送通知

前置脚本 `proactive-tick.py` 只执行 Stage 1 和 Stage 2。脚本结束后，Hermes Cron 调度器会检查其 stdout 最后一行：

- `wakeAgent=false`：本轮静默结束，不创建主 Agent 会话；
- `wakeAgent=true`：调度器将脚本输出作为 `Script Output`，连同任务提示词和 `editorial-gate` 技能一起唤醒主 Agent。

主 Agent 先调用 `proactivity_read`，读取候选事项、证据、用户偏好，以及快照生成后新产生的实时对话增量，避免把用户刚刚已经处理完的事项再次提醒一遍。随后，主 Agent 对每条候选作出 `send` 或 `skip` 裁决，并调用 `proactivity_select` 一次性提交。

提交动作会在同一个事务中写入候选裁决、可选的事项关闭、检查点的 `committed` 状态，以及需要发送时的 `sent_log pending` 回执。若至少一条候选被标记为 `send`，主 Agent 会将它们合并并重写成一条自然短消息；若全部跳过，则只输出 `[SILENT]`。最后由 Cron 调度器负责实际投递或抑制投递。

### 5. 用户回复与事项闭环

提醒发出后，用户可能在普通会话中确认完成、明确放弃，或表示暂时搁置。此时需要更新的是对应的跟进事项：

- 已办结或明确放弃的事项，可以关闭；
- 只是暂缓的事项，更新其摘要或 `momentum_status`；
- 如果主 Agent 在 Stage 3 已经从实时对话增量中确认事项办结，也可以在 `proactivity_select` 中直接通过 `close_goal_ids` 关闭，无需再等待一次用户回复。

在普通会话中，插件会引导模型通过 `tracking_manage` 静默完成这些更新，并只针对当前话题自然回应用户。

## 已发现的问题与修复

`editorial-gate` 技能只挂载在 `proactive_notifier` Cron 任务的 Stage 3 审稿回合中。用户随后在原会话里回复提醒时，普通会话不会自动加载这个技能。实际使用中曾出现模型改走 `terminal` 执行 CLI 和 SQL、并把 `closed`、`goal_id` 或其他无关追踪项带进回复的情况。

为修正这个问题，插件在宿主调用 `register(ctx)` 时，通过 `ctx.register_system_prompt_section` 注册一段会话级提示词。宿主为新会话构建系统提示词时，会按会话平台决定是否注入这段内容；Cron、subagent 等非人类会话则不会注入，避免与 Stage 3 的审稿规则冲突。

这段提示词引导模型通过 `tracking_manage` 静默更新或关闭相关跟进事项，避免使用 `terminal`、CLI 或 SQLite 管理追踪状态。同时，它要求模型使用与用户一致的日常语言简短回应，要求暴露内部字段和执行过程。提示词属于行为约束而非代码级强制，因此工具 Schema 中也保留了相同的回复边界说明。

## 改进体验

**下面的方法只在飞书平台进行了测试。**

### 1. 关闭工具调用回显

对于飞书平台，Hermes 默认会显示工具调用过程。任务比较复杂时，工具卡片容易刷屏，而 Muse 通常只返回任务结果。因此建议关闭飞书平台的工具调用回显：

```bash
hermes config set display.platforms.feishu.tool_progress off
```

### 2. 执行前说明

我使用的是 **Gemini** 模型，默认提示词会倾向于优先执行工具。对于复杂任务，关闭工具调用回显后，会话可能会有相当长一段时间的静默（虽然飞书会显示正在输入的图标），体验不佳。Muse 在开始工作前，则往往会先给出一段回复，说明它准备进行的操作。

因此可以使用提示词约束模型：当任务需要多步或耗时操作时，在第一批 `tool_calls` 的同一条响应里顺带给出一句短说明。最简单的方法是在 `SOUL.md` 中加入：

```markdown
你当前正通过外部消息网关（如飞书等即时通讯工具）与用户对话。用户看不到实时的底层工具调用面板，只能看到发出的消息。
- 对于可能需要较长时间或多步处理的任务（例如检索调研、排查系统或日志、执行耗时命令、读写修改代码、批量处理、委派子任务等），请在发出第一批工具调用（tool_calls）的同一轮回复中，先用自然、直接的语言告诉用户你现在准备做什么或去核查什么，再紧接着在同一轮发起工具调用。
- 说明内容不必限制字数，按实际任务需要把正在做的事和大致范围说清楚即可；保持平静、准确的口吻，不要使用动作描写、舞台提示或空洞套话。
- 严禁只输出预告文字而不附带工具调用：预告文字必须与首批 tool_calls 在同一次响应中发出，否则系统会视为回复结束而无法继续执行。
- 如果中途切换到了耗时较长的下一个关键阶段，也可以在发起该轮 tool_calls 的同时附带说明当前进展，但不要在连续小步骤之间频繁刷屏。
- 对于不需要耗时操作或直接就能回答的简单对话，直接回复结果即可，不需要额外加开场预告。
```

如果不想修改 `SOUL.md`，也可以使用一个独立插件，在新会话构建系统提示词时按平台注入相同规则。

<details>
<summary>查看插件实现示例</summary>

```python
"""Gateway-only system prompt section encouraging pre-tool status explanations."""

from __future__ import annotations

from typing import Any, Mapping

SECTION_ID = "gateway-preamble"

# Surfaces where the user already sees live tool activity directly or no human is waiting in IM chat.
NON_GATEWAY_SURFACES = frozenset({
    "",
    "cli",
    "tui",
    "desktop",
    "local",
    "cron",
    "subagent",
    "tool",
    "webhook",
    "msgraph_webhook",
    "system",
    "api_server",
})

GATEWAY_PREAMBLE_SECTION = (
    "你当前正通过外部消息网关（如飞书等即时通讯工具）与用户对话。用户看不到实时的底层工具调用面板，"
    "只能看到发出的消息。\n"
    "- 对于可能需要较长时间或多步处理的任务（例如检索调研、排查系统或日志、执行耗时命令、"
    "读写修改代码、批量处理、委派子任务等），请在发出第一批工具调用（tool_calls）的同一轮回复中，"
    "先用自然、直接的语言告诉用户你现在准备做什么或去核查什么，再紧接着在同一轮发起工具调用。\n"
    "- 说明内容不必限制字数，按实际任务需要把正在做的事和大致范围说清楚即可；保持平静、"
    "准确的口吻，不要使用动作描写、舞台提示或空洞套话。\n"
    "- 严禁只输出预告文字而不附带工具调用：预告文字必须与首批 tool_calls 在同一次响应中发出，"
    "否则系统会视为回复结束而无法继续执行。\n"
    "- 如果中途切换到了耗时较长的下一个关键阶段，也可以在发起该轮 tool_calls 的同时附带说明当前进展，"
    "但不要在连续小步骤之间频繁刷屏。\n"
    "- 对于不需要耗时操作或直接就能回答的简单对话，直接回复结果即可，不需要额外加开场预告。"
)


def _render_gateway_preamble(session_info: Mapping[str, Any]) -> str:
    platform = str((session_info or {}).get("platform") or "").strip().lower()
    if platform in NON_GATEWAY_SURFACES:
        return ""
    return GATEWAY_PREAMBLE_SECTION


def register(ctx: Any) -> None:
    ctx.register_system_prompt_section(
        id=SECTION_ID,
        content=_render_gateway_preamble,
        position="after_memory",
    )
```

</details>
