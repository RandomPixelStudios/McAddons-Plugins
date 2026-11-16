#!/usr/bin/env python3
"""Validates every plugin in plugins/ and writes index.json.

Usage:
  build_index.py --check                 # validate only (pull requests)
  build_index.py --repo OWNER/NAME --ref SHA   # validate + write index.json (main branch)

Download URLs are pinned to a commit SHA, and every file carries its SHA-256, so what players
install is byte-for-byte what was reviewed and merged.
"""
import argparse, hashlib, json, os, re, shutil, subprocess, sys, datetime

ID = re.compile(r"^[a-z][a-z0-9_]{1,31}$")
PATH = re.compile(r"^[A-Za-z0-9_\-.]+(/[A-Za-z0-9_\-.]+)*$")
PERMS = {"chat", "players", "players.modify", "world.read", "world.write", "effects", "commands",
         "commands.run", "hud", "keys", "storage", "content",
         "resources", "data", "gui", "network", "render"}
ALLOWED_EXT = {".lua", ".json", ".png", ".md", ".txt", ".ogg", ".mcmeta", ".mcfunction", ".nbt"}
MAX_FILE, MAX_TOTAL, MAX_FILES = 2 * 1024 * 1024, 16 * 1024 * 1024, 256
API_MAJOR = 1

def fail(errors, pid, msg):
    errors.append(f"{pid}: {msg}")

def lua_check(path, errors, pid):
    luac = shutil.which("luac5.2") or shutil.which("luac")
    if not luac:
        return
    r = subprocess.run([luac, "-p", path], capture_output=True, text=True)
    if r.returncode != 0:
        fail(errors, pid, "Lua syntax error: " + (r.stderr or r.stdout).strip())

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--repo", default="RandomPixelStudios/McAddons-Plugins")
    ap.add_argument("--ref", default="main")
    a = ap.parse_args()

    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    pdir = os.path.join(root, "plugins")
    errors, entries = [], []
    for pid in sorted(os.listdir(pdir)):
        d = os.path.join(pdir, pid)
        if not os.path.isdir(d):
            continue
        if not ID.match(pid):
            fail(errors, pid, "folder name must match " + ID.pattern); continue
        try:
            m = json.load(open(os.path.join(d, "plugin.json"), encoding="utf-8"))
        except Exception as e:
            fail(errors, pid, f"plugin.json: {e}"); continue
        if m.get("id") != pid: fail(errors, pid, "id must equal folder name")
        if not m.get("name"): fail(errors, pid, "name is required")
        if not m.get("description"): fail(errors, pid, "description is required")
        if not re.match(r"^\d+\.\d+\.\d+", str(m.get("version", ""))): fail(errors, pid, "version must be semver")
        api = str(m.get("api", ""))
        if not re.match(r"^\d+(\.\d+)?$", api) or int(api.split(".")[0]) != API_MAJOR:
            fail(errors, pid, f"api must be {API_MAJOR}.x")
        perms = m.get("permissions", [])
        for p in perms:
            if p not in PERMS: fail(errors, pid, f"unknown permission {p}")
        content = m.get("content") or {}
        if any(content.get(k) for k in ("items", "blocks", "ores", "loot")) and "content" not in perms:
            fail(errors, pid, "items/blocks/ores/loot need the 'content' permission")
        if os.path.isdir(os.path.join(d, "assets")) and "resources" not in perms:
            fail(errors, pid, "an assets/ folder needs the 'resources' permission")
        if os.path.isdir(os.path.join(d, "data")) and "data" not in perms:
            fail(errors, pid, "a data/ folder needs the 'data' permission")
        if m.get("side", "both") not in ("server", "client", "both"): fail(errors, pid, "side must be server/client/both")
        entry = m.get("entry", "main.lua")
        if not os.path.isfile(os.path.join(d, entry)): fail(errors, pid, f"entry {entry} missing")

        files, total = [], 0
        for base, dirs, names in os.walk(d):
            dirs[:] = sorted(x for x in dirs if not x.startswith("."))
            for n in sorted(names):
                full = os.path.join(base, n)
                rel = os.path.relpath(full, d).replace(os.sep, "/")
                if n.startswith("."): continue
                if os.path.islink(full): fail(errors, pid, f"symlinks not allowed: {rel}"); continue
                if not PATH.match(rel) or os.path.splitext(n)[1] not in ALLOWED_EXT:
                    fail(errors, pid, f"file not allowed: {rel}"); continue
                data = open(full, "rb").read()
                if len(data) > MAX_FILE: fail(errors, pid, f"{rel} larger than {MAX_FILE} bytes")
                total += len(data)
                if n.endswith(".lua"): lua_check(full, errors, pid)
                files.append({
                    "path": rel,
                    "url": f"https://raw.githubusercontent.com/{a.repo}/{a.ref}/plugins/{pid}/{rel}",
                    "sha256": hashlib.sha256(data).hexdigest(),
                    "size": len(data),
                })
        if total > MAX_TOTAL or len(files) > MAX_FILES: fail(errors, pid, "plugin too large")
        icon = next((f["url"] for f in files if f["path"] == "icon.png"), None)
        entries.append({
            "id": pid, "name": m.get("name"), "version": m.get("version"),
            "description": m.get("description"), "authors": m.get("authors", []),
            "api": api, "side": m.get("side", "both"), "permissions": perms,
            "icon": icon, "repo": f"https://github.com/{a.repo}/tree/main/plugins/{pid}",
            "files": files,
        })

    if errors:
        print("Validation failed:\n  " + "\n  ".join(errors))
        sys.exit(1)
    print(f"OK - {len(entries)} plugins valid")
    if a.check:
        return
    index = {"schema": 1, "updated": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
             "plugins": entries}
    with open(os.path.join(root, "index.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("wrote index.json")

if __name__ == "__main__":
    main()
