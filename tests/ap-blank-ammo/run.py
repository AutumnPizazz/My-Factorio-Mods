#!/usr/bin/env python3
"""Run isolated Factorio integration scenarios without changing the player's mods or saves."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-dir", type=Path, required=True)
    parser.add_argument("--mods-dir", type=Path, required=True)
    parser.add_argument("--case", choices=("vanilla", "space-age", "current", "k2-standard", "k2-realistic", "custom"), action="append")
    args = parser.parse_args()
    game_dir = args.game_dir.resolve()
    installed = args.mods_dir.resolve()
    source = Path(__file__).resolve().parent
    root = source.parent.parent
    output = Path(tempfile.mkdtemp(prefix="factorio-blank-ammo-tests-"))
    print(f"Test output: {output}", flush=True)

    current = json.loads((installed / "mod-list.json").read_text(encoding="utf-8"))
    known_names = {mod["name"] for mod in current["mods"]}
    for info in (game_dir / "data").glob("*/info.json"):
        known_names.add(json.loads(info.read_text(encoding="utf-8"))["name"])
    cases = args.case or ["vanilla", "space-age", "current", "k2-standard", "k2-realistic", "custom"]
    for case in cases:
        work = output / case
        mods = work / "mods"
        mods.mkdir(parents=True)
        for entry in installed.iterdir():
            if entry.suffix == ".zip" or (entry.is_dir() and (entry / "info.json").is_file()):
                if not entry.name.startswith("ap-blank-ammo_") and entry.name != "ap-blank-ammo":
                    (mods / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
        (mods / "ap-blank-ammo").symlink_to(root / "mods" / "ap-blank-ammo", target_is_directory=True)

        if case == "vanilla":
            names = {"base"}
        elif case == "space-age":
            names = {"base", "space-age", "quality", "recycler", "elevated-rails"}
        else:
            names = {mod["name"] for mod in current["mods"] if mod["enabled"]}
            if (installed / "mod-settings.dat").exists():
                shutil.copy2(installed / "mod-settings.dat", mods / "mod-settings.dat")
        names.update(("ap-blank-ammo", "ap-blank-ammo-tests"))
        (mods / "mod-list.json").write_text(json.dumps({
            "mods": [{"name": name, "enabled": name in names} for name in sorted(known_names | names)]
        }), encoding="utf-8")

        helper = mods / "ap-blank-ammo-tests"
        helper.mkdir()
        (helper / "info.json").write_text(json.dumps({
            "name": "ap-blank-ammo-tests", "version": "0.1.0", "title": "Blank ammo tests",
            "author": "AutumnPizazz", "factorio_version": "2.1", "dependencies": ["ap-blank-ammo"]
        }), encoding="utf-8")
        shutil.copy2(source / "data-final-fixes.lua", helper / "data-final-fixes.lua")
        scenario = helper / "scenarios" / "integration"
        scenario.mkdir(parents=True)
        shutil.copy2(source / "control.lua", scenario / "control.lua")

        overrides = []
        if case in ("k2-standard", "k2-realistic"):
            value = "true" if case == "k2-realistic" else "false"
            overrides.extend([
                'data.raw["bool-setting"]["kr-realistic-weapons"].hidden = true',
                f'data.raw["bool-setting"]["kr-realistic-weapons"].forced_value = {value}'
            ])
        if case == "custom":
            overrides.extend([
                'data.raw["double-setting"]["ap-blank-ammo-damage"].default_value = 2.5',
                'data.raw["double-setting"]["ap-blank-ammo-crafting-time"].default_value = 2'
            ])
        if overrides:
            (helper / "settings-updates.lua").write_text("\n".join(overrides) + "\n", encoding="utf-8")

        config = work / "config.ini"
        config.write_text(
            f"[path]\nread-data={game_dir / 'data'}\nwrite-data={work / 'data'}\n"
            "[other]\ncheck-updates=false\nenable-crash-log-uploading=false\n",
            encoding="utf-8"
        )
        command = [str(game_dir / "bin" / "x64" / "factorio"), "--config", str(config),
                   "--mod-directory", str(mods), "--disable-audio", "--test-scenario",
                   "ap-blank-ammo-tests/integration", "--test-arg", case, "--test-ticks", "2400"]
        log = work / "console.log"
        print(f"Running {case}...", flush=True)
        with log.open("w", encoding="utf-8") as stream:
            result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=180)
        text = log.read_text(encoding="utf-8", errors="replace")
        if result.returncode or "[ap-blank-ammo-tests] PASS:" not in text:
            print("\n".join(text.splitlines()[-45:]), flush=True)
            print(f"FAIL: {case} (exit {result.returncode}); log: {log}", flush=True)
            return 1
        for line in text.splitlines():
            if "[ap-blank-ammo-tests]" in line:
                print(line, flush=True)
        print(f"PASS: {case}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
