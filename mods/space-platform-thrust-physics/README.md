# Space Platform Thrust Physics / 太空平台推力物理

**Make space platforms fly like real ships: thrust and mass decide how fast you accelerate — and
speed is only fought by a gentle drag.**

**让太空平台像真飞船一样飞：推力和质量决定你加速有多快，而速度只会被一点点阻力拖慢。**

In vanilla, your top speed is capped by how bulky the platform is (in 2.1 by its mass, in 2.0 by
its width), so piling on engines hits diminishing returns and a big ship can never be fast. This
mod replaces that formula with the one you already know from school: `F = m · a`.

原版里顶速被“船体有多臃肿”卡死（2.1 看质量，2.0 看宽度）：发动机越加越没用，大船永远快不起来。
本模组把它换成你中学就学过的那条式子：`F = m · a`。

* More thrust → more acceleration. / 推力越大，加速越快。
* More mass → slower acceleration, but **no ceiling on top speed**. / 质量越大加速越慢，但**顶速不再被封顶**。
* Speed itself creates drag, and drag cancels thrust: that is what sets your top speed.
  速度本身会产生阻力，阻力和推力相抵之处，就是你的顶速。

---

## English

### What you will notice in game

* **Acceleration feels like a rocket.** An empty scout leaps forward, a loaded freighter crawls —
  same engines, different mass (`a = F / m`).
* **Engines actually buy speed.** By default the model is *quadratic*: 4× the thrust = 2× the top
  speed, so adding engines always helps.
* **Mass no longer caps your speed by itself.** Vanilla's "heavier platform = forever slower"
  penalty is off by default (you can switch it back on).
* **Hull size can still matter — if you want it to.** Drag can scale with platform width, height
  and mass, each with its own reference value and exponent. Default: drag ∝ width, so a 34-tile
  ship with the same engines tops out ~30 % slower than a 17-tile one.

### Speed at a glance (default settings)

Top speed = `v0 · sqrt( (thrust / T0) / size_factor )`, with `v0 = 1000 km/s`, `T0 = 61.2 GN`
(4 legendary thrusters at full throttle) and `size_factor = width / 17`.

| Legendary thrusters (full throttle) | Thrust | Top speed (17 tiles wide) |
|---|---|---|
| 1 | 15.3 GN | ~500 km/s |
| 2 | 30.6 GN | ~707 km/s |
| 4 | 61.2 GN | ~1000 km/s |
| 8 | 122.4 GN | ~1414 km/s |

| Platform width (4 legendary thrusters) | Top speed |
|---|---|
| 8 tiles | ~1458 km/s |
| 17 tiles | ~1000 km/s |
| 24 tiles | ~842 km/s |
| 34 tiles | ~707 km/s |
| 50 tiles | ~583 km/s |

Quality matters: one legendary thruster ≈ 2.5 normal thrusters. These numbers are a balance
starting point, not a law of nature — retune them until the game feels right.

### Pick a preset

| Preset | What to set | Result |
|---|---|---|
| **Balanced** *(default)* | drag model `quadratic`, ref. thrust `61.2`, ref. top speed `1000`, width exponent `1.0` | Engines buy speed; wide ships are slower. |
| **Pure physics** | width / height / mass exponents all `0` | Top speed depends only on total thrust; size is irrelevant and mass only affects acceleration. |
| **Capital ships** | ref. thrust `120`, ref. top speed `1500`, width exponent `0.5` | Big freighters stay viable; drag grows only with √width. |
| **Racing** | ref. top speed `3000` | Everything is ~3× faster; scale your travel plans accordingly. |
| **Vanilla-ish** | heavy-mass penalty `true`, width exponent `0.0`, mass exponent `0.5` | Heavily loaded platforms get punished, like 2.0/2.1 vanilla. |

### Settings

Everything is a **startup setting**: *Settings → Mod settings → Startup → Space platform thrust
physics*, change it, then reload the save (or restart the game).

| Setting | Default | What it does |
|---|---|---|
| `sptp-drag-model` | `quadratic` | `quadratic`: 4× thrust = 2× top speed. `linear`: 2× thrust = 2× top speed. |
| `sptp-reference-thrust-gn` | `61.2` | Thrust that should reach the reference top speed (61.2 GN = 4 legendary thrusters). |
| `sptp-reference-top-speed` | `1000` | Top speed in km/s at the reference thrust and size, with drag strength 1. |
| `sptp-drag-strength` | `1.0` | Global drag multiplier. `0` = no drag at all (speed keeps growing), `2` = half the top speed. |
| `sptp-reference-width` | `17` | Width in tiles at which the width part of drag is exactly 1. |
| `sptp-width-exponent` | `1.0` | `0` = width ignored, `1` = drag ∝ width, `0.5` = ∝ √width. |
| `sptp-reference-height` | `17` | Same idea, for platform height. |
| `sptp-height-exponent` | `0.0` | `0` = height ignored (default). |
| `sptp-reference-weight-tons` | `1000` | Mass in tons at which the mass part of drag is exactly 1. |
| `sptp-weight-exponent` | `0.0` | `0` = mass does not affect drag (default), `0.5` = a heavier hull is draggier. |
| `sptp-keep-heavy-mass-penalty` | `false` | Keep vanilla's `thrust / (1 + weight / 10 000 000)` penalty. |
| `sptp-speed-cap` | `0` | Hard speed limit in km/s (`0` = disabled). |
| `sptp-custom-expression` | *(empty)* | Paste any engine math expression here to take full control; it overrides everything above. |

Exponents accept `-10` … `10` and fractional values; a **negative** exponent makes the platform
*faster* as that dimension grows.

### Good to know

* **Old saves:** nothing to migrate — every platform in every save follows the new formula.
* **Multiplayer:** all players must use the same startup settings (the save stores them).
* **Compatibility:** the mod only rewrites the platform acceleration formula and adds no items or
  entities. Another mod that also rewrites `space_platform_acceleration_expression` will conflict —
  if that happens, merge both in this mod's *custom expression* setting.
* Mods that set `speed` directly from scripts are unaffected.

### If you like to read formulas

```
acceleration = (thrust − drag) / weight / 60        (per tick; weight in kg, thrust in N)
drag         = K · speed · |speed|^(n−1) · sign(speed) · size_factor
size_factor  = (width/ref_width)^eW · (height/ref_height)^eH · (weight/ref_weight_kg)^eM
K            = drag_strength · T0 / v0^n            (T0, v0 = reference thrust and top speed)
```

The drag coefficient is calibrated so that, at the reference size, a platform with the reference
thrust tops out exactly at the reference top speed.

---

## 中文

### 游戏里会有什么变化

* **加速像火箭了。** 空载小快艇一蹬就飞，满载货轮磨磨蹭蹭——同样的发动机，不同的质量
  （`a = F / m`）。
* **发动机真的能换速度了。** 默认是二次模型：推力 ×4 → 顶速 ×2，加发动机永远有用。
* **质量本身不再封死顶速。** 原版“越重永远越慢”的惩罚默认关闭（可以手动打开）。
* **船体尺寸依然可以参与阻力——由你决定。** 阻力可分别跟随宽度、高度、质量，各自有参考值和
  指数。默认：阻力 ∝ 宽度，所以同样推力下 34 格宽的船顶速比 17 格船慢约 30%。

### 看一眼速度表（默认设置）

顶速 = `v0 · sqrt( (推力 / T0) / 尺寸因子 )`，其中 `v0 = 1000 km/s`、`T0 = 61.2 GN`
（4 台传说推进器满推力）、`尺寸因子 = 宽度 / 17`。

| 传说推进器（满推力） | 总推力 | 顶速（17 格宽） |
|---|---|---|
| 1 | 15.3 GN | 约 500 km/s |
| 2 | 30.6 GN | 约 707 km/s |
| 4 | 61.2 GN | 约 1000 km/s |
| 8 | 122.4 GN | 约 1414 km/s |

| 平台宽度（4 台传说推进器） | 顶速 |
|---|---|
| 8 格 | 约 1458 km/s |
| 17 格 | 约 1000 km/s |
| 24 格 | 约 842 km/s |
| 34 格 | 约 707 km/s |
| 50 格 | 约 583 km/s |

品质很关键：1 台传说推进器 ≈ 2.5 台普通推进器。以上数值只是平衡起点，不是物理定律，觉得不合适就自己调。

### 选一个预设

| 预设 | 怎么设 | 效果 |
|---|---|---|
| **均衡**（默认） | 阻力模型 `quadratic`、参考推力 `61.2`、参考顶速 `1000`、宽度指数 `1.0` | 发动机买速度；越宽越慢。 |
| **纯物理** | 宽度 / 高度 / 质量指数全部设 `0` | 顶速只由总推力决定；尺寸无关，质量只影响加速度。 |
| **巨舰** | 参考推力 `120`、参考顶速 `1500`、宽度指数 `0.5` | 大货轮依然可用；阻力只按 √宽度 增长。 |
| **竞速** | 参考顶速 `3000` | 全体提速约 3 倍，请相应调整航行计划。 |
| **接近原版** | 保留重质量惩罚 `true`、宽度指数 `0.0`、质量指数 `0.5` | 满载平台会被狠狠惩罚，接近 2.0/2.1 原版手感。 |

### 设置项

全部是**启动时设置**：打开 *设置 → 模组设置 → 启动时 → 太空平台推力物理*，改完后重载存档
（或重启游戏）生效。

| 设置 | 默认 | 作用 |
|---|---|---|
| `sptp-drag-model` | `quadratic` | `quadratic`：推力 ×4 → 顶速 ×2；`linear`：推力 ×2 → 顶速 ×2。 |
| `sptp-reference-thrust-gn` | `61.2` | 达到“参考顶速”所需的推力（61.2 GN = 4 台传说推进器）。 |
| `sptp-reference-top-speed` | `1000` | 在参考推力、参考尺寸、阻力强度 1.0 下的顶速（km/s）。 |
| `sptp-drag-strength` | `1.0` | 全局阻力系数。`0` = 没有阻力（速度一直涨），`2` = 顶速减半。 |
| `sptp-reference-width` | `17` | 宽度参考值（格）：等于它时宽度因子为 1。 |
| `sptp-width-exponent` | `1.0` | `0` = 忽略宽度，`1` = 阻力 ∝ 宽度，`0.5` = ∝ √宽度。 |
| `sptp-reference-height` | `17` | 高度参考值（格）：等于它时高度因子为 1。 |
| `sptp-height-exponent` | `0.0` | `0` = 忽略高度（默认）。 |
| `sptp-reference-weight-tons` | `1000` | 质量参考值（吨）：等于它时质量因子为 1。 |
| `sptp-weight-exponent` | `0.0` | `0` = 质量不影响阻力（默认），`0.5` = 越重阻力越大。 |
| `sptp-keep-heavy-mass-penalty` | `false` | 保留原版的 `thrust / (1 + weight / 10 000 000)` 惩罚。 |
| `sptp-speed-cap` | `0` | 硬性限速（km/s），`0` = 关闭。 |
| `sptp-custom-expression` | （空） | 填入任意引擎数学表达式即可完全接管，优先级高于以上所有选项。 |

指数范围 `-10` ~ `10`，支持小数；**负指数**意味着该尺寸越大反而越快。

### 须知

* **老存档**：无需迁移，所有存档里的所有平台都按新公式运行。
* **多人游戏**：所有玩家必须使用相同的启动时设置（设置保存在存档里）。
* **兼容性**：本模组只改写平台加速度公式，不新增物品或实体。若有其它模组也改写
  `space_platform_acceleration_expression`，会互相覆盖——此时可用本模组的“自定义表达式”把两者合并。
* 直接用脚本改 `speed` 的模组不受影响。

### 想读公式的话

```
加速度 = (推力 − 阻力) / 质量 / 60        （每 tick；质量单位 kg，推力单位 N）
阻力   = K · 速度 · |速度|^(n−1) · sign(速度) · 尺寸因子
尺寸因子 = (宽度/参考宽度)^指数W · (高度/参考高度)^指数H · (质量/参考质量)^指数M
K      = 阻力强度 · T0 / v0^n              （T0、v0 = 参考推力与参考顶速）
```

阻力系数经过标定：在参考尺寸下，平台拥有“参考推力”时，顶速正好等于“参考顶速”。

---

*Made for Factorio 2.1 (Space Age), data-stage only — no runtime scripting, no per-tick cost.
Built-in English + 简体中文.*
*适用于异星工厂 2.1（太空时代），纯数据层实现——没有运行时脚本、没有逐 tick 开销。内置英文与简体中文。*
