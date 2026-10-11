# My Factorio Mods

AutumnPizazz 的《异星工厂》(Factorio) 模组源码仓库。

## 核心约定

- **源码目录名不带版本号**。版本号只写在两处：每个模组 `info.json` 的 `version` 字段（唯一来源），以及 `changelog.txt` 顶部的条目。
  这样每次发版不会因为「把目录名从 `xxx_1.0.0` 改成 `xxx_1.0.1`」而在 git 里产生一整串删除/新增记录。
- 文本文件统一 **LF** 换行（见 `.gitattributes`），避免 Windows 侧编辑造成「整文件重写」的假 diff。
- **打包产物（`*.zip`）不入库**（见 `.gitignore`），只提交源码。
- **不要把本机信息写进仓库**：提交进仓库的文件里不要出现本机绝对路径或用户名（如 `C:\Users\<用户名>\…`、`/mnt/c/Users/<用户名>/…`、`/home/<用户名>/…`）。文档与示例一律用占位符，例如 `--out "<游戏 mods 目录>"`。

## 模组列表

| 目录 | 模组名 | 版本 | factorio_version | 说明 |
| --- | --- | --- | --- | --- |
| `mods/Pizazz-CN` | Pizazz-CN | 0.2.3 | 2.1 | 自用汉化包（仅简体中文），按模组分文件放在 `locale/zh-CN/` |
| `mods/space-platform-thrust-physics` | space-platform-thrust-physics | 0.1.2 | 2.1 | 替换太空平台推力-速度公式：推力/质量决定加速度，速度产生阻力 |
| `mods/ap-adjustment-for-onlyNauvis` | ap-adjustment-for-onlyNauvis | 1.0.0 | 2.0 | 新增钨弹系列（弹药/配方/科技/弹体） |
| `mods/ap-adjustment-for-py` | ap-adjustment-for-py | 1.0.0 | 2.0 | （标题 Pizazzs's Adjustment For Py）调整 Pyanodons 的 `mdrn-loader` 配方 |
| `mods/early-bulk-inserter-for-py` | early-bulk-inserter-for-py | 1.0.0 | 2.0 | （标题 Early Bulk Inserter for Py）让 Pyanodons 的 Bulk Inserter 更早、更便宜 |

## 目录结构

```
mods/
  <模组名>/              每个模组一个目录，目录名 = info.json 里的 name
    info.json            版本号、依赖、标题、简介
    changelog.txt        发版日志（顶部是最新版本）
    thumbnail.png        模组缩略图（144x144）
    ...                  其余为模组自身的数据文件
tools/
  modtool.py             统一管理脚本：列出版本、提升版本号、打包
```

## 发版流程

```bash
# 1. 提升版本号（会同时改写 info.json 与插入 changelog 骨架）
python3 tools/modtool.py bump Pizazz-CN patch      # 0.2.3 -> 0.2.4

# 2. 填写 changelog.txt 顶部的骨架（把 TODO 换成真实内容）

# 3. 打包（自动用 <模组名>_<版本号> 作 zip 内顶层目录，并做 CRC / 版本 / 目录结构 / PNG 合法性自检）
python3 tools/modtool.py pack Pizazz-CN                          # -> dist/Pizazz-CN_0.2.4.zip
python3 tools/modtool.py pack Pizazz-CN --out "<游戏 mods 目录>"   # 顺手装进本地游戏测试
python3 tools/modtool.py pack --all --dry-run                    # 预演所有模组
```

`tools/modtool.py` 的用法：

```bash
python3 tools/modtool.py list                        # 列出所有模组、版本、有无 changelog / thumbnail
python3 tools/modtool.py bump <模组> patch           # 0.2.3 -> 0.2.4
python3 tools/modtool.py bump <模组> minor           # 0.2.3 -> 0.3.0
python3 tools/modtool.py bump <模组> major           # 0.2.3 -> 1.0.0
python3 tools/modtool.py bump <模组> 1.2.3           # 直接指定版本号
python3 tools/modtool.py bump --all patch --dry-run  # 所有模组各进一个 patch（预演，不落盘）
python3 tools/modtool.py pack <模组>                 # 打包为 dist/<模组名>_<版本号>.zip（并自检）
python3 tools/modtool.py pack --all --reproducible   # 全部打包，源码不变则 zip 字节不变
```

其它选项：`--date YYYY-MM-DD`（changelog 日期，默认今天）、`--sections "新增翻译,优化"`、`--force`（允许版本号不变或倒退）。

## 许可证

本仓库的模组源码采用 **MIT License**（见 [`LICENSE`](LICENSE)）：可自由使用、修改、再分发、商用，只需保留版权声明与许可声明。

两点例外与说明：

- 模组中引用或派生的《异星工厂》(Factorio) 官方美术资源（例如 `mods/space-platform-thrust-physics` 的 `thumbnail.png` 基于游戏自带的推进器图标与星空贴图）版权归 **Wube Software** 所有，不属于本仓库 MIT 授权的范围，请遵循游戏自身的资产使用条款。
- 汉化包 `mods/Pizazz-CN` 里的翻译文本由本人整理，同样以 MIT 授权；但其中每个模组的名称/简介仍属各原作者，翻译仅作兼容用途。
