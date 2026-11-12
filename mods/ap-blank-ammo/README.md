# Air-Made Blank Ammo / 空气空包弹

为资源匮乏环境下的机枪塔提供零原料、低伤害应急弹药。适用于 Factorio 2.1，兼容 Krastorio 2 和 Krastorio 2 Spaced Out。

## 制作与使用

- 配方无需任何物品或流体原料，开局可用，无需额外研究。
- 只能在具备常规装配能力的组装机中生产，包括适用的模组组装机；禁止手工制作。
- 禁止在太空平台生产。不按气压限制其他星球，保留艰苦环境中的生产能力。
- 平台限制仅针对生产，不限制运输或使用已生产的弹药。
- 默认每发 1 点基础物理伤害，每匣基础制造时间 5 秒。
- 弹匣容量与当前基础机枪弹药一致：原版及 K2 标准武器模式通常为 10 发，K2 真实武器模式为 30 发。
- 使用 `bullet` 弹药类别，可供机枪塔、冲锋枪及使用同类弹药的载具武器使用。K2 真实武器模式下的手枪使用独立类别，不接受此弹药。
- 正常接受子弹伤害、射速科技与炮塔加成，实际伤害仍受目标物理抗性影响。
- 不可回收，不作为穿甲弹等高级弹药的配方原料。弹药伤害与射速仍正常受到科技增益。配方不接受产能或品质效果，只生产普通品质弹药。

## 设置

| 启动设置 | 默认值 | 范围 |
| --- | --- | --- |
| 空包弹基础伤害 | 1 | 0.1 至 100 |
| 空包弹匣制造时间 | 5 秒 | 0.1 至 3600 秒 |

制造时间以制造速度 1 计算。例如制造速度 0.5 的组装机需要 10 秒完成默认配方。仅免除原料消耗，机器仍消耗其正常电力或燃料。

基础伤害很低，面对装甲目标时效果有限；该弹药定位为供应困难时的保底弹药，不替代常规弹药升级。

## 实现与兼容

模组仅修改数据阶段原型，没有运行时脚本。K2 开启真实武器时复制步枪弹与独立弹体，保留弹道和碰撞行为，并修改空包弹自身伤害；关闭时沿用当前普通机枪弹机制。原有弹药和弹体均不修改。

使用独立配方分类阻止手搓，使用独立表面属性阻止平台生产，避免通过气压或重力间接排除模组星球。模组依赖均为可选项，可在原版 2.1 中单独启用。

弹匣图标通过引用和染色游戏原有图像实现。官方美术资源版权归 Wube Software 所有。

## 验证

在仓库根目录运行独立场景测试，不修改玩家的模组列表、设置或存档：

```bash
python3 tests/ap-blank-ammo/run.py --game-dir "<游戏安装目录>" --mods-dir "<游戏 mods 目录>"
```

覆盖原版、太空时代、当前启用的模组组合、K2 标准和真实武器模式、自定义参数。检查零原料生产、禁止手搓、平台限制、回收隔离，以及研究后实际机枪塔伤害与射击间隔的变化。

## English

Emergency bullet magazines with no item or fluid ingredients. Default damage is 1 physical damage per shot, with 5 seconds of base crafting time per magazine. Damage and crafting time are startup settings.

Manufacturing is restricted to compatible assembling machines outside space platforms. Hand crafting, recycling, productivity and quality effects are disabled. Other planets are not restricted by pressure or gravity. Finished ammunition may still be transported and used on platforms.

Uses the `bullet` category and inherits the current basic rifle magazine's capacity and firing behavior. Supports Krastorio 2 realistic weapons enabled or disabled, and Krastorio 2 Spaced Out. No runtime scripts.
