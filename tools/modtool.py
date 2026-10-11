#!/usr/bin/env python3
"""modtool —— My-Factorio-Mods 仓库的统一模组管理工具。

设计前提：**源码目录名不带版本号**（例如 mods/Pizazz-CN/），版本号只存在于
`info.json` 的 version 字段与 `changelog.txt` 的顶部条目里。这样每次发版不会因为
"目录改名" 而在 git 里产生一长串删除/新增记录。

目前提供三个子命令：
  list    列出仓库里所有模组（目录名 / info.json 里的 name、version / 有无 changelog、thumbnail）
  bump    提升版本号：改写 info.json 的 version，并在 changelog.txt 顶部插入待填写的骨架
  pack    打包成可上传的 <name>_<version>.zip（zip 内顶层目录同名），并做打包后自检

示例：
  python3 tools/modtool.py list
  python3 tools/modtool.py bump Pizazz-CN patch          # 0.2.2 -> 0.2.3
  python3 tools/modtool.py bump space-platform-thrust-physics minor
  python3 tools/modtool.py bump mods/Pizazz-CN 0.3.0     # 直接指定版本号
  python3 tools/modtool.py bump --all patch              # 所有模组各进一个 patch
  python3 tools/modtool.py bump Pizazz-CN patch --dry-run
  python3 tools/modtool.py pack Pizazz-CN                # -> dist/Pizazz-CN_0.2.3.zip
  python3 tools/modtool.py pack Pizazz-CN --out "<游戏 mods 目录>"   # 顺手装进本地游戏测试
  python3 tools/modtool.py pack --all --dry-run

约定：
  * 版本号必须是纯数字点分（1~4 段，如 "1.0" / "0.2.2" / "2.1.0.3"）；本工具不会自作主张
    补零，patch/minor/major 递推时保持原来的段数。
  * 只改 info.json 里 version 那一行的字符串，其余格式（缩进、顺序、末尾换行）原样保留，
    因此 diff 永远只有一行。
  * changelog.txt 已存在同版本条目时默认拒绝覆盖；确实要重写用 --force。
  * pack 会检查「目录名 == info.json 的 name」以及「changelog.txt 顶部版本 == info.json 的 version」，
    不一致时拒绝打包（确认无碍再加 --force）；缺 thumbnail.png / changelog.txt 只警告不拦截。
  * pack 还会校验模组里的 .png 是不是真正的 PNG（签名 / IHDR / IEND）。缩略图被当成文本
    做过换行转换、或存成 JPEG 后改名，都会让 mod portal 报
    "Failed to read thumbnail.png image file"，所以这里直接拦下不让打包。
  * pack 默认跳过垃圾文件（__pycache__、.pyc、.DS_Store、编辑器临时文件等）；
    --reproducible 会固定 zip 内的时间戳与权限位，内容不变则产出的 zip 逐字节相同。
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import struct
import sys
import zipfile
from pathlib import Path

SEP = "-" * 99  # 与 Factorio 官方 changelog 的分隔线等长
VERSION_RE = re.compile(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:\.(\d+))?$')
INFO_VERSION_RE = re.compile(r'("version"\s*:\s*")([^"]*)(")')
CHANGELOG_VERSION_RE = re.compile(r'^Version:\s*(\S+)\s*$', re.MULTILINE)

# PNG 文件头；portal 报 "Failed to read thumbnail.png image file" 基本就是它不匹配
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

# 打包时要跳过的目录/文件名与后缀
JUNK_DIRS = {"__pycache__", ".git", ".idea", ".vscode", ".svn"}
JUNK_FILES = {".DS_Store", "Thumbs.db", "desktop.ini"}
JUNK_SUFFIXES = {".pyc", ".pyo", ".bak", ".orig", ".rej", ".tmp", ".swp", ".swo", ".log"}


class ModToolError(Exception):
    """工具自身的可预期错误（参数/文件问题），由 main() 统一打印。"""


def read_text(path: Path) -> str:
    """按 UTF-8 读取，且**不做换行转换**（newline="" ）——保证 LF/CRLF 原样往返。"""
    with open(path, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def write_text(path: Path, text: str) -> None:
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


# --------------------------------------------------------------------------------------
# 仓库 / 模组发现
# --------------------------------------------------------------------------------------
def repo_root(cli: str | None) -> Path:
    """定位仓库根目录：默认 tools/ 的上一级。"""
    root = Path(cli).resolve() if cli else Path(__file__).resolve().parent.parent
    if not (root / "mods").is_dir():
        raise ModToolError(f"{root} 下没有 mods/ 目录，请用 --repo 指定仓库根目录")
    return root


def discover_mods(root: Path) -> list[dict]:
    """扫描 mods/*/info.json，返回按目录名排序的模组信息列表。"""
    mods: list[dict] = []
    for info_path in sorted((root / "mods").glob("*/info.json")):
        mod_dir = info_path.parent
        try:
            info = json.loads(info_path.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as exc:
            raise ModToolError(f"{info_path} 不是合法 JSON：{exc}") from exc
        changelog = mod_dir / "changelog.txt"
        mods.append(
            {
                "dir": mod_dir,
                "dir_name": mod_dir.name,
                "info_path": info_path,
                "info": info,
                "name": info.get("name", ""),
                "version": info.get("version", ""),
                "factorio_version": info.get("factorio_version", ""),
                "changelog": changelog if changelog.is_file() else None,
                "thumbnail": (mod_dir / "thumbnail.png") if (mod_dir / "thumbnail.png").is_file() else None,
            }
        )
    if not mods:
        raise ModToolError(f"{root / 'mods'} 下没有找到任何模组（缺少 */info.json）")
    return mods


def find_mod(mods: list[dict], spec: str) -> dict:
    """按目录名、目录名去掉 mods/ 前缀、或 info.json 里的 name 定位单个模组。"""
    key = spec.replace("\\", "/").rstrip("/").split("/")[-1]
    hits = [m for m in mods if m["dir_name"] == key or m["name"] == key]
    if not hits:
        names = "、".join(m["dir_name"] for m in mods)
        raise ModToolError(f"找不到模组 {spec!r}；现有模组：{names}")
    if len(hits) > 1:
        raise ModToolError(f"{spec!r} 同时匹配到多个模组：{[m['dir_name'] for m in hits]}")
    return hits[0]


# --------------------------------------------------------------------------------------
# 版本号
# --------------------------------------------------------------------------------------
def parse_version(text: str) -> tuple[int, ...]:
    m = VERSION_RE.match(text.strip())
    if not m:
        raise ModToolError(f"版本号 {text!r} 不合法：应为 1~4 段纯数字，例如 0.2.2")
    return tuple(int(g) for g in m.groups() if g is not None)


def bump_version(current: str, spec: str) -> str:
    """按 patch/minor/major 递推，段数与原版本保持一致（如 "1.0" -> "1.1"）。"""
    parts = list(parse_version(current))
    idx = {"major": 0, "minor": 1, "patch": 2}[spec]
    while len(parts) <= idx:
        parts.append(0)
    parts[idx] += 1
    for i in range(idx + 1, len(parts)):
        parts[i] = 0
    return ".".join(str(p) for p in parts)


def version_key(text: str) -> tuple[int, ...]:
    parts = list(parse_version(text))
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts)


# --------------------------------------------------------------------------------------
# 写文件
# --------------------------------------------------------------------------------------
def write_info_version(mod: dict, new_version: str) -> str:
    """只替换 info.json 里的 version 字符串，保留其余格式；返回原始文本。"""
    path: Path = mod["info_path"]
    original = path.read_text(encoding="utf-8")
    new_text, count = INFO_VERSION_RE.subn(rf'\g<1>{new_version}\g<3>', original, count=1)
    if count != 1:
        raise ModToolError(f"{path} 里找不到可替换的 \"version\" 字段")
    if new_text != original:
        path.write_text(new_text, encoding="utf-8")
    return original


def changelog_has_version(text: str, version: str) -> bool:
    return re.search(rf"^Version:\s*{re.escape(version)}\s*$", text, re.MULTILINE) is not None


def skeleton(version: str, date: str, sections: list[str]) -> str:
    body = "\n".join(f"  {sec}:\n    - TODO: describe this release\n" for sec in sections)
    return f"{SEP}\nVersion: {version}\nDate: {date}\n\n{body}\n"


def update_changelog(mod: dict, new_version: str, date: str, sections: list[str],
                     force: bool) -> tuple[bool, str]:
    """在 changelog.txt 顶部插入骨架。返回 (是否改动, 说明)。不存在则新建。"""
    path: Path = mod["changelog"] or (mod["dir"] / "changelog.txt")
    if path.is_file():
        text = path.read_text(encoding="utf-8")
        if changelog_has_version(text, new_version) and not force:
            return False, f"changelog.txt 已有 {new_version} 条目，跳过（加 --force 可覆盖）"
        if force and changelog_has_version(text, new_version):
            # 删掉已有的同名条目，重新插入骨架
            pattern = re.compile(
                rf"^{SEP}\nVersion:\s*{re.escape(new_version)}\s*\n(?:.*\n)*?(?=^{SEP}|\Z)",
                re.MULTILINE,
            )
            text = pattern.sub("", text, count=1)
        new_text = skeleton(new_version, date, sections).rstrip("\n") + "\n\n" + text.lstrip("\n")
    else:
        new_text = skeleton(new_version, date, sections)
    path.write_text(new_text, encoding="utf-8")
    return True, f"{'更新' if mod['changelog'] else '新建'} {path.relative_to(mod['dir'].parent.parent)}"


# --------------------------------------------------------------------------------------
# 子命令
# --------------------------------------------------------------------------------------
def cmd_list(root: Path, args: argparse.Namespace) -> int:
    mods = discover_mods(root)
    width = max(len(m["dir_name"]) for m in mods)
    print(f"仓库：{root}    共 {len(mods)} 个模组\n")
    print(f"{'目录':<{width}}  {'name':<34} {'version':<9} {'factorio':<9} changelog  thumbnail")
    for m in mods:
        cl = "有" if m["changelog"] else "缺"
        th = "有" if m["thumbnail"] else "缺"
        flag = "" if m["dir_name"] == m["name"] else "  ← 目录名与 name 不一致"
        print(f"{m['dir_name']:<{width}}  {m['name']:<34} {m['version']:<9} "
              f"{m['factorio_version']:<9} {cl:<9}  {th}{flag}")
    return 0


def cmd_bump(root: Path, args: argparse.Namespace) -> int:
    mods = discover_mods(root)
    targets = mods if args.all else [find_mod(mods, args.mod)]
    date = args.date or _dt.date.today().isoformat()
    sections = [s.strip() for s in args.sections.split(",") if s.strip()]
    failures = 0

    for m in targets:
        if m["dir_name"] != m["name"]:
            print(f"[警告] {m['dir_name']}/info.json 的 name 是 {m['name']!r}，与目录名不一致")
        current = m["version"]
        new = args.version if args.version and args.version not in ("patch", "minor", "major") \
            else bump_version(current, args.version or "patch")
        parse_version(new)  # 校验
        if version_key(new) <= version_key(current) and not args.force:
            print(f"[跳过] {m['dir_name']}：新版本 {new} 不大于当前版本 {current}（要强制请加 --force）")
            failures += 1
            continue

        print(f"\n=== {m['dir_name']}  {current} -> {new}  ({date})")
        if args.dry_run:
            print("    [dry-run] 将改写 info.json 的 version；changelog 将插入骨架：")
            print("    " + skeleton(new, date, sections).replace("\n", "\n    ").rstrip())
            continue
        write_info_version(m, new)
        print(f"    [OK] info.json  version -> {new}")
        changed, note = update_changelog(m, new, date, sections, args.force)
        print(f"    [{'OK' if changed else '--'}] {note}")
        print(f"    下一步：填写 changelog 内容，然后 git add mods/{m['dir_name']} && git commit")

    if failures and not args.all:
        return 1
    return 0


# --------------------------------------------------------------------------------------
# pack：打包成可上传的 zip
# --------------------------------------------------------------------------------------
def changelog_top_version(path: Path) -> str | None:
    """取 changelog.txt 里最上面那条 `Version:`（文件本身是按新→旧排列的）。"""
    m = CHANGELOG_VERSION_RE.search(read_text(path))
    return m.group(1) if m else None


def check_pngs(mod: dict, files: list[Path]) -> list[str]:
    """校验 .png 是不是真正的 PNG（签名 / IHDR / IEND），返回问题列表。

    踩过的坑：把 thumbnail.png 当成文本文件做过 CRLF→LF 转换，文件头变成
    89504e470a1a0a（少了 0d），portal 上传时报 code 500 "Failed to read
    thumbnail.png image file"。
    """
    problems: list[str] = []
    for path in files:
        if path.suffix.lower() != ".png":
            continue
        rel = path.relative_to(mod["dir"]).as_posix()
        data = path.read_bytes()
        if not data.startswith(PNG_SIGNATURE):
            problems.append(
                f"{rel} 不是合法 PNG：文件头是 {data[:8].hex()}，应为 {PNG_SIGNATURE.hex()}"
                "（常见原因：被当成文本做过换行转换，或存成 JPEG/WEBP 后改名）"
            )
            continue
        if len(data) < 33 or data[12:16] != b"IHDR":
            problems.append(f"{rel} 缺 IHDR 块，PNG 已损坏")
            continue
        width, height = struct.unpack(">II", data[16:24])
        if data[-8:-4] != b"IEND":
            problems.append(f"{rel} 末尾没有 IEND 块（{width}x{height}），文件可能被截断")
    return problems


def collect_mod_files(mod: dict) -> tuple[list[Path], list[str]]:
    """收集要打包的文件（按相对路径排序），并返回顺带的警告。"""
    files: list[Path] = []
    warnings: list[str] = []
    for path in sorted(mod["dir"].rglob("*")):
        rel = path.relative_to(mod["dir"])
        if any(part in JUNK_DIRS for part in rel.parts):
            continue
        if path.is_dir():
            continue
        if path.is_symlink():
            warnings.append(f"跳过符号链接 {rel.as_posix()}")
            continue
        if path.name in JUNK_FILES or path.name.startswith("."):
            continue
        if path.suffix.lower() in JUNK_SUFFIXES:
            continue
        if path.stat().st_size == 0:
            warnings.append(f"{rel.as_posix()} 是 0 字节空文件")
        files.append(path)
    return files, warnings


def write_zip(target: Path, mod: dict, files: list[Path], top: str, reproducible: bool) -> None:
    """把 files 打进 target，zip 内路径统一为 <top>/<相对路径>。"""
    target.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in files:
            arcname = f"{top}/{path.relative_to(mod['dir']).as_posix()}"
            if reproducible:
                info = zipfile.ZipInfo(arcname, date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.create_system = 3          # 固定为 Unix，跨平台字节一致
                info.external_attr = 0o644 << 16
                zf.writestr(info, path.read_bytes())
            else:
                zf.write(path, arcname)


def verify_zip(target: Path, mod: dict, top: str, expected_count: int) -> list[str]:
    """重新读一遍刚写出的 zip：CRC、顶层目录、文件数、info.json 内容。"""
    problems: list[str] = []
    with zipfile.ZipFile(target) as zf:
        bad = zf.testzip()
        if bad:
            problems.append(f"CRC 校验失败：{bad}")
        names = zf.namelist()
        if len(names) != expected_count:
            problems.append(f"文件数不符：zip 内 {len(names)} 个，源目录 {expected_count} 个")
        outside = [n for n in names if not n.startswith(top + "/")]
        if outside:
            problems.append(f"有 {len(outside)} 个条目不在 {top}/ 下，例如 {outside[0]}")
        try:
            data = json.loads(zf.read(f"{top}/info.json").decode("utf-8-sig"))
        except Exception as exc:  # noqa: BLE001 - 自检阶段任何异常都算失败
            problems.append(f"zip 内 info.json 读不出来：{exc!r}")
        else:
            if data.get("name") != mod["name"] or data.get("version") != mod["version"]:
                problems.append(
                    f"zip 内 info.json 是 {data.get('name')} {data.get('version')}，"
                    f"与源目录的 {mod['name']} {mod['version']} 不一致"
                )
        if "changelog.txt" not in [n.split("/", 1)[-1] for n in names]:
            problems.append("zip 里没有 changelog.txt")
    return problems


def cmd_pack(root: Path, args: argparse.Namespace) -> int:
    mods = discover_mods(root)
    targets = mods if args.all else [find_mod(mods, args.mod)]
    out_dir = Path(args.out).expanduser().resolve() if args.out else (root / "dist")
    failures = 0

    print(f"输出目录：{out_dir}")
    for m in targets:
        name, version = m["name"], m["version"]
        print(f"\n=== {m['dir_name']}  {version}")
        hard: list[str] = []
        soft: list[str] = []

        if m["dir_name"] != name:
            hard.append(f"目录名 {m['dir_name']!r} 与 info.json 的 name {name!r} 不一致")
        try:
            parse_version(version)
        except ModToolError as exc:
            hard.append(str(exc))
        if not m["changelog"]:
            soft.append("没有 changelog.txt")
        else:
            top_ver = changelog_top_version(m["changelog"])
            if top_ver != version:
                hard.append(f"changelog.txt 顶部是 `Version: {top_ver}`，与 info.json 的 {version} 不一致")
        if not m["thumbnail"]:
            soft.append("没有 thumbnail.png（mod portal 会显示默认图）")

        files, warns = collect_mod_files(m)
        soft.extend(warns)
        hard.extend(check_pngs(m, files))
        if not files:
            hard.append("目录里没有可打包的文件")
        for w in soft:
            print(f"    [警告] {w}")
        if hard and not args.force:
            for h in hard:
                print(f"    [错误] {h}")
            print("    打包中止（确认无碍可加 --force）")
            failures += len(hard)
            continue

        top = f"{name}_{version}"
        target = out_dir / f"{top}.zip"
        if args.dry_run:
            print(f"    [dry-run] 将打包 {len(files)} 个文件 -> {target}")
            for p in files:
                print(f"        {p.relative_to(m['dir']).as_posix()}")
            continue
        if target.exists() and not args.force:
            print(f"    [错误] {target} 已存在（要覆盖请加 --force）")
            failures += 1
            continue

        write_zip(target, m, files, top, args.reproducible)
        problems = verify_zip(target, m, top, len(files))
        print(f"    [OK] {target}")
        print(f"         {len(files)} 个文件，{target.stat().st_size} 字节"
              f"{'，时间戳已固定（--reproducible）' if args.reproducible else ''}")
        if problems:
            for p in problems:
                print(f"    [自检失败] {p}")
            failures += len(problems)
        else:
            print(f"         自检通过：CRC ok、顶层目录 {top}/、info.json = {name} {version}")
            print(f"         上传 portal 直接选这个 zip；本地测试可 "
                  f"--out <游戏 mods 目录>")
    return 1 if failures else 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="modtool.py",
        description="My-Factorio-Mods 统一模组管理工具（源码目录不带版本号，版本号只写在 info.json / changelog.txt）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("--repo", help="仓库根目录（默认取本脚本所在 tools/ 的上一级）")
    sub = p.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("list", help="列出所有模组")
    sp.set_defaults(func=cmd_list)

    sp = sub.add_parser("bump", help="提升版本号 + 插入 changelog 骨架")
    sp.add_argument("mod", nargs="?", help="模组目录名或 info.json 里的 name")
    sp.add_argument("version", nargs="?", default="patch",
                    help="新版本号，或 patch/minor/major（默认 patch）")
    sp.add_argument("--all", action="store_true", help="对所有模组执行")
    sp.add_argument("--date", help="changelog 日期，默认今天 (YYYY-MM-DD)")
    sp.add_argument("--sections", default="Changes",
                    help="changelog 里要生成的小节，逗号分隔（默认 Changes；"
                         "Factorio 常用 Features/Changes/Bugfixes/Info）")
    sp.add_argument("--dry-run", action="store_true", help="只显示将要做的改动")
    sp.add_argument("--force", action="store_true", help="允许降级/同版本、覆盖同名 changelog 条目")
    sp.set_defaults(func=cmd_bump)

    sp = sub.add_parser("pack", help="打包成 <name>_<version>.zip（可直接上传或丢进 mods 目录）")
    sp.add_argument("mod", nargs="?", help="模组目录名或 info.json 里的 name")
    sp.add_argument("--all", action="store_true", help="对所有模组执行")
    sp.add_argument("--out", help="输出目录（默认 <仓库>/dist；本地测试可指向游戏 mods 目录）")
    sp.add_argument("--reproducible", action="store_true",
                    help="固定 zip 内的时间戳与权限位（内容不变则字节不变）")
    sp.add_argument("--dry-run", action="store_true", help="只列出将打包的文件，不写磁盘")
    sp.add_argument("--force", action="store_true",
                    help="忽略一致性错误（版本不一致等），并允许覆盖已存在的 zip")
    sp.set_defaults(func=cmd_pack)
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command in ("bump", "pack") and not args.all and not args.mod:
        raise ModToolError(f"{args.command} 需要指定模组，或用 --all 操作全部模组")
    return args.func(repo_root(args.repo), args)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ModToolError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(exc.code)
