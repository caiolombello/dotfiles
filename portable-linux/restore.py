#!/usr/bin/env python3
"""Offline, allowlisted rehearsal only. Never restore to the active HOME."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parent
ALLOWLIST = {"files/vimrc": ".vimrc", "files/zshrc": ".zshrc", "files/gitconfig": ".gitconfig"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def payload():
    manifest = json.loads((ROOT / "manifest.json").read_text())
    if set(manifest) != set(ALLOWLIST):
        raise ValueError("Manifest must match the fixed allowlist exactly")
    result = {}
    for source, destination in ALLOWLIST.items():
        entry = manifest[source]
        if set(entry) != {"destination", "sha256"} or entry["destination"] != destination:
            raise ValueError("Manifest destination drift")
        path = ROOT / source
        if path.is_symlink() or path.parent.is_symlink() or not path.is_file():
            raise ValueError("Payload must contain ordinary files")
        data = path.read_bytes()
        if digest(data) != entry["sha256"]:
            raise ValueError("Payload hash drift: " + source)
        result[destination] = data
    return result


def scratch_path(value):
    path = Path(value)
    if not path.is_absolute() or path != path.resolve() or not path.is_dir():
        raise ValueError("Use an existing absolute scratch directory without symlinks")
    temp_root = Path(tempfile.gettempdir()).resolve()
    if path == temp_root or temp_root not in path.parents:
        raise ValueError("Rehearsal HOME must be a subdirectory of the system temp directory")
    if path == Path.home().resolve():
        raise ValueError("Refusing current HOME")
    try:
        import pwd
        if path == Path(pwd.getpwuid(os.getuid()).pw_dir).resolve():
            raise ValueError("Refusing account HOME")
    except ImportError:
        pass
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scratch-home", required=True)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Copy only into an empty temporary HOME")
    mode.add_argument("--verify", action="store_true", help="Compare exact files and hashes without writing")
    args = parser.parse_args()
    data = payload()
    home = scratch_path(args.scratch_home)
    if args.verify:
        if {p.name for p in home.iterdir()} != set(data):
            raise ValueError("Restored HOME contains missing or unexpected entries")
        for name, expected in data.items():
            path = home / name
            if path.is_symlink() or not path.is_file() or path.read_bytes() != expected:
                raise ValueError("Restored content drift: " + name)
        print("VERIFIED: fixed allowlist, exact files and hashes")
        return
    if any(home.iterdir()):
        raise ValueError("Refusing non-empty HOME; existing files are preserved")
    if not args.apply:
        print(json.dumps({"mode": "dry-run", "files": sorted(data)}, indent=2))
        return
    for name, content in data.items():
        fd = os.open(home / name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
        with os.fdopen(fd, "wb") as output:
            output.write(content)
    print("RESTORED: 3 allowlisted files in scratch HOME")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError) as error:
        raise SystemExit("Refused: " + str(error))
