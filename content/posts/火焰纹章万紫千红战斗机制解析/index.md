---
title: "《火焰之纹章：万紫千红》战斗数值与核心机制全解析"
date: 2026-10-28T09:30:00+08:00
draft: false
tags: ["游戏", "战棋", "Switch 2", "火焰之纹章"]
description: "全面梳理《火焰之纹章：万紫千红》（万缕千丝）底层战斗数值体系：攻防伤害减法公式、负重追击判定、命中必杀规则，以及战技与烈焰技的核心博弈。"
toc: true
cover: "cover.jpg"
math: true
---

《火焰之纹章：万紫千红》{{< fnref 1 >}}（中文官方译名《火焰之纹章 万缕千丝》）在鞑古扎大陆的斗祭舞台上拉开序幕。本作在回归经典战略战棋扎实手感的同时，对底层攻防模型、负重惩罚、耐久结算以及角色专属系统进行了深度重构。

无论是在斗祭竞技场还是大陆地图探索中，摸清底层数值逻辑都是制定战术配队、凹点规划与高难度开荒的基础。本文将游戏内的伤害计算公式与战斗机制进行系统化拆解。

---

## 一、 伤害判定与攻防减法模型

本作依旧采用系列经典的“净攻防减法”结算逻辑，即攻击方综合攻击力扣除防守方对应护甲值，计算结果非负。

### 1. 物理与魔法伤害

* **物理单发伤害**：
  $$\text{Dmg}_{\text{Phys}} = \max\left(0,\, \text{Atk}_{\text{Phys}} - \text{Def}_{\text{Target}}\right)$$

  其中综合物理攻击力与防御力拆解如下：
  $$\begin{aligned}
  \text{Atk}_{\text{Phys}} &= \text{Str} + \text{Mt} + \text{Skill}_{\text{Atk}} \\
  \text{Def}_{\text{Target}} &= \text{Def} + \text{Terrain} + \text{Skill}_{\text{Def}}
  \end{aligned}$$

  **公式符号详解**：
  * $\text{Dmg}_{\text{Phys}}$（Physical Damage，物理单发伤害）：最终结算给目标扣除的单次物理生命值。
  * $\text{Atk}_{\text{Phys}}$（Physical Attack，综合物理攻击力）：攻击方打出的综合物理打击强度。
  * $\text{Def}_{\text{Target}}$（Target Defense，实际物理防御力）：防守方受击时实际发挥的综合护甲强度。
  * $\text{Str}$（Strength，力量）：攻击方角色的力量属性值，构成物理伤害的角色基础。
  * $\text{Mt}$（Might，武器威力）：装备武器的面板固有破坏力。
  * $\text{Def}$（Defense，防守）：防守方角色的基础防守属性值。
  * $\text{Terrain}$（Terrain Defense，地形防御）：防守方所处地块的地形防御加成（如要塞提供 $+2$、城门提供 $+3$ 等）。
  * $\text{Skill}_{\text{Atk}}$（Attack Skill Bonus，攻击特技加成）：主动战技或攻击类被动特技带来的固定攻击力补正。
  * $\text{Skill}_{\text{Def}}$（Defense Skill Bonus，防御特技加成）：受击方防御类被动特技提供的固定护甲或减免补正。
  * $\max(0,\, A - B)$：数学取大函数。当攻击力低于防御力时伤害归 $0$，避免出现负数反向加血。

* **魔法单发伤害**：
  $$\text{Dmg}_{\text{Mag}} = \max\left(0,\, \text{Atk}_{\text{Mag}} - \text{Res}_{\text{Target}}\right)$$

  其中综合魔法攻击力与魔防拆解如下：
  $$\begin{aligned}
  \text{Atk}_{\text{Mag}} &= \text{Mag} + \text{Mt} + \text{Skill}_{\text{Atk}} \\
  \text{Res}_{\text{Target}} &= \text{Res} + \text{Terrain} + \text{Skill}_{\text{Res}}
  \end{aligned}$$

  **公式符号详解**：
  * $\text{Dmg}_{\text{Mag}}$（Magical Damage，魔法单发伤害）：最终结算给目标扣除的单次魔法生命值。
  * $\text{Atk}_{\text{Mag}}$（Magical Attack，综合魔法攻击力）：攻击方施展的综合魔法打击强度。
  * $\text{Res}_{\text{Target}}$（Target Resistance，实际魔法防御力）：防守方受击时实际发挥的综合魔防强度。
  * $\text{Mag}$（Magic，魔力）：攻击方角色的魔力属性值，构成魔法伤害的角色基础。
  * $\text{Mt}$（Might，法术威力）：法术或魔法武器的面板固有破坏力。
  * $\text{Res}$（Resistance，魔防）：防守方角色的基础魔防属性值。
  * $\text{Terrain}$（Terrain Resistance，地形魔防）：神殿、祭坛等特殊地形提供的魔防加成。
  * $\text{Skill}_{\text{Res}}$（Resistance Skill Bonus，魔防特技加成）：受击方被动特技提供的额外魔防减免。

### 2. 特效克制与倍率修正

* **兵种特效（克制）**：弓箭克制飞行、长枪克制骑兵、重甲杀手克制重甲。触发克制时，系统优先对武器基础威力进行增幅（通常为 $\text{Mt} \times 2$ 或 $\text{Mt} \times 3$），再计入总攻击力进行破甲结算，而非直接对最终伤害乘算。这使得低威力但带特效的武器面对高防克制目标时能产生质变。
* **技能倍率加成**：如部分角色的“全力攻击”或特定战技，直接对基础结算后的伤害进行乘算（例如 $\times 1.3$ 或 $\times 1.5$）。
* **必杀（暴击）伤害**：
  $$\text{Dmg}_{\text{Crit}} = \text{Dmg}_{\text{Base}} \times 3$$

  **公式符号详解**：
  * $\text{Dmg}_{\text{Crit}}$（Critical Damage，必杀伤害）：命中判定触发暴击时的单发最终伤害。
  * $\text{Dmg}_{\text{Base}}$（Base Damage，单发基础伤害）：未暴击时的常规单发伤害（即前述计算所得的 $\text{Dmg}_{\text{Phys}}$ 或 $\text{Dmg}_{\text{Mag}}$）。命中必杀时伤害稳定翻 3 倍。

---

## 二、 武器耐久、负重与攻速判定

本作对历代武器磨损机制进行了重大革新：**普通攻击不再消耗武器耐久度**，只有主动发动战技时才会扣除耐久；魔法则采用独立的使用次数配额制，通关或在基地休息即可回满。

在这一设定下，武器的 **重量（Weight）** 成为了限制高威力和高级武器肆意使用的核心门槛。

### 1. 攻击速度（Attack Speed, AS）

角色装备武器时，若武器过重，将直接惩罚其有效速度。本作引入了“力量按比例抵消重量”的规则：

$$\text{AS} = \text{Spd} - \max\left(0,\, \text{Wt} - \left\lfloor \frac{\text{Str}}{5} \right\rfloor\right)$$

**公式符号详解**：
* $\text{AS}$（Attack Speed，攻击速度）：角色的有效攻速，主导战斗中的追击判定与基础回避率。
* $\text{Spd}$（Speed，速度）：角色的自身基础速度属性值。
* $\text{Wt}$（Weight，武器重量）：当前装备武器或法术的重量数值。
* $\text{Str}$（Strength，力量）：角色的自身基础力量属性值。
* $\lfloor x \rfloor$：数学向下取整函数（Floor）。例如 $\lfloor 14 / 5 \rfloor = 2$。代表角色力量每拥有整 **5 点力量**，才能抵消 **1 点武器重量**；不足 5 点的部分不产生抵消收益。
* $\max(0,\, \text{Wt} - \lfloor \text{Str} / 5 \rfloor)$：超额负重惩罚值。若力量抵消值大于等于武器重量，该项归 0（力量充裕时攻速不受武器拖累，但也不会反向增加攻速）。

### 2. 追击判定机制

* **追击触发线**：
  $$\text{AS}_{\text{Attacker}} - \text{AS}_{\text{Defender}} \ge 4$$

  **公式符号详解**：
  * $\text{AS}_{\text{Attacker}}$（Attacker AS，攻击方攻速）：主动发起攻击方的有效攻击速度。
  * $\text{AS}_{\text{Defender}}$（Defender AS，防守方攻速）：防守方的有效攻击速度。
  * 当攻击方攻速领先防守方 4 点或以上时，触发追击（单回合内连续进行第二次攻击）。
* **连击武器**：装备勇者系列武器或徒手拳套时，单次交锋自带双连击；若满足攻速差 $\ge 4$，单回合总计可打出 4 次判定。

---

## 三、 命中、回避与必杀概率体系

战斗界面的所有概率展示均基于攻守双方的属性对冲。

### 1. 命中率与回避率

* **基础命中与回避值**：
  $$\begin{aligned}
  \text{Hit} &= \text{Hit}_{\text{Wpn}} + \text{Dex} + \text{Support} + \text{Skill}_{\text{Hit}} \\
  \text{Avoid} &= \text{AS} + \text{Avo}_{\text{Wpn}} + \text{Terrain}_{\text{Avo}} + \text{Skill}_{\text{Avo}}
  \end{aligned}$$

* **最终实机命中概率**：
  $$\text{Hit Rate} = \max\left(0,\, \min\left(100,\, \text{Hit} - \text{Avoid}\right)\right)$$

**公式符号详解**：
* $\text{Hit Rate}$（Combat Hit Rate，实机命中率）：战斗预测面板最终显示的实际命中概率（百分比，严格落在 0% 到 100% 之间）。
* $\text{Hit}$（Total Hit，综合命中值）：攻击方的综合命中判定数值。
* $\text{Hit}_{\text{Wpn}}$（Weapon Hit，武器命中率）：武器或法术面板自带的基础命中率。
* $\text{Dex}$（Dexterity，技巧）：角色的技巧/灵巧属性值，决定武器操控与命中精度。
* $\text{Support}$（Support Bonus，支援加成）：相邻或协同攻击友军提供的支援羁绊加成。
* $\text{Skill}_{\text{Hit}}$（Hit Skill Bonus，命中特技加成）：被动特技或战技带来的命中率额外补正（如“剑术·命中+15”）。
* $\text{Avoid}$（Total Avoid，综合回避值）：防守方的综合回避判定数值。
* $\text{AS}$（Attack Speed，攻击速度）：防守方的实际攻击速度，攻速按 1:1 比例直接转化为基础回避能力。
* $\text{Avo}_{\text{Wpn}}$（Weapon Avoid，武器回避修正）：武器自身附带的回避补正（部分轻灵剑增加回避，笨重武器可能倒扣回避）。
* $\text{Terrain}_{\text{Avo}}$（Terrain Avoid，地形回避加成）：防守方所处地块的地形回避率加成（如基础灌木丛直接提供 $+20\%$ 回避，森林提供 $+20\%$，要塞提供 $+30\%$ 等）。
* $\text{Skill}_{\text{Avo}}$（Avoid Skill Bonus，回避特技加成）：防御类被动特技带来的回避率额外补正（如“敏捷回避+10”）。
* $\min(100,\, \dots)$ 与 $\max(0,\, \dots)$：区间夹紧函数，确保最终命中率严格落在 $[0\%,\, 100\%]$ 范围，既不会出现溢出破百，也不会跌为负数。

### 2. 必杀率与必杀回避

* **基础必杀与必杀回避值**：
  $$\begin{aligned}
  \text{Crit} &= \text{Crit}_{\text{Wpn}} + \left\lfloor \frac{\text{Dex} + \text{Lck}}{2} \right\rfloor + \text{Skill}_{\text{Crit}} \\
  \text{Dodge} &= \text{Lck} + \text{Skill}_{\text{Ddg}}
  \end{aligned}$$

* **最终暴击触发概率**：
  $$\text{Crit Rate} = \max\left(0,\, \text{Crit} - \text{Dodge}\right)$$

**公式符号详解**：
* $\text{Crit Rate}$（Combat Critical Rate，实机必杀率）：战斗预测面板最终显示的实际必杀（暴击）触发概率（百分比）。
* $\text{Crit}$（Total Critical，综合必杀值）：攻击方的综合必杀判定数值。
* $\text{Crit}_{\text{Wpn}}$（Weapon Critical，武器必杀率）：武器或法术面板自带的必杀值（如杀手系武器、倭刀等通常自带 20 到 30 点基础必杀）。
* $\text{Dex}$（Dexterity，技巧）：攻击方角色的技巧属性值。
* $\text{Lck}$（Luck，幸运）：角色的幸运属性值。
* $\lfloor \frac{\text{Dex} + \text{Lck}}{2} \rfloor$：技巧与幸运属性相加折半并向下取整，两者共同构成角色的基础必杀输出潜力。
* $\text{Skill}_{\text{Crit}}$（Critical Skill Bonus，必杀特技加成）：特技提供的额外必杀率（如“必杀+10”）。
* $\text{Dodge}$（Critical Avoid，必杀回避/防暴击）：防守方抵抗被暴击的能力，主要由防守方自身的幸运属性（$\text{Lck}$）决定。
* $\text{Skill}_{\text{Ddg}}$（Dodge Skill Bonus，防暴特技加成）：防御类特技提供的额外必杀回避补正。
* $\max(0,\, \text{Crit} - \text{Dodge})$：当攻击方的必杀值低于防守方的防暴击能力时，实机暴击率归零。

---

## 四、 本作特色系统：战技与烈焰技

除了常规属性碰撞，本作战斗的核心变数集中在战技（Combat Arts）与烈焰技（Blaze Arts）的资源管理上。

### 1. 战技（Combat Arts）
战技以消耗武器耐久为代价发动。由于平 A 零消耗，战技的定位完全转变为“关键局面的解题工具”：
* 提供固定攻击力加成（$\text{Atk} +3 \sim +8$）以打破防御阈值；
* 补正命中短板（如斧战技通常提供大额命中补偿）；
* 施加击退、破防或移动位移等战术状态。

### 2. 烈焰技（Blaze Arts）与过载博弈
烈焰技为特定主要角色专属的高阶行动，以 **消耗自身生命值（HP）** 为启动代价，并随着释放积攒专用烈焰槽：
* **半蓄状态**：烈焰槽充能达到一半时，角色获得额外的常态伤害增强；
* **过载爆发（Overdrive）**：当烈焰槽蓄满时，可释放威力极大的终结爆发技，但随之触发过载代价——**该英雄在本场战斗剩余时间内，最大生命值（Max HP）直接减半**。
* **战术取舍**：这种设定让烈焰技成为典型的“双刃剑”。在面对 Boss 强突或危急关头，过载爆发能瞬间定胜负，但过早失控则会让核心主力变为一触即溃的脆皮。

### 3. 神龛祝福（Blessings）
在大地图神龛中升级的祝福系统，为局内提供了关键容错机制。包括有限次数的行动回溯、特定回合内的免伤结界以及临时资源减免，高难度攻坚时需合理分配祝福点数，配合战技进行防线拆解。

---

![鞑古扎大陆](battlefield-atmosphere.png)

---

## 五、 开荒实战建议

1. **前期重视武器锻造减重**：游戏前中期的锻造石资源相对充裕，优先将主力携带的铁系、钢系武器进行锻造强化，重点选择“降低重量”与“提升命中”分支。由于力量除以 5 才能抵消 1 点重量，锻造减重 1 到 2 点相当于变相省下了 5 到 10 点力量对攻速的束缚。
2. **轻装弓箭全员配置**：绝大多数常规武器在本作中不受兵种限制（拳套等个别武器除外）。前期尽量为近战手备一把轻型训练弓或铁弓，利用射程安全白嫖敌方近战单位血线。
3. **计算好攻速追击线**：面对敌方高敏盗贼或剑士时，切忌盲目换上重型大斧导致攻速被拉开 $\ge 4$ 进而遭到双连击。时刻关注面板的攻速差值，是保证生存的第一准则。

---

{{< refers title="参考与注释" >}}
{{< refer num=1 source="任天堂官方宣传物料" url="https://www.nintendo.com" >}}
《火焰之纹章：万紫千红》（万缕千丝）主视觉图。
{{< /refer >}}
{{< /refers >}}
