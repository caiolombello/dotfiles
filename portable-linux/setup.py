#!/usr/bin/env python3
"""Plan-first personal dotfiles. No installers, shell eval, networking or services."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import tempfile
import uuid

ROOT = Path(__file__).resolve().parent
BASE = {"files/vimrc": ".vimrc", "files/zshrc": ".zshrc", "files/gitconfig": ".gitconfig"}
OPTIONAL = {
    "dev": {"optional/code-settings.json": ".config/Code/User/settings.json"},
    "ai": {"optional/ai/AGENTS.md": ".config/personal-ai/AGENTS.md"},
}
STATE = ".local/state/personal-dotfiles"
TOOLS = {"base": ["python3", "git", "zsh", "vim"], "dev": ["tmux", "rg", "jq", "fzf"], "machine": [], "ai": []}
TARGETS = set(BASE.values()) | {x for p in OPTIONAL.values() for x in p.values()} | {".config/git/personal.inc", ".config/personal-dotfiles/machine.json"}


class Failure(Exception):
    def __init__(self, message, code=3):
        super().__init__(message)
        self.code = code


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise Failure("Invalid command-line arguments", 3)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()


def safe_text(value):
    if not isinstance(value, str) or not value or any(ord(c) < 32 for c in value):
        raise Failure("Invalid or control-character input")
    return value


def target_path(home, relative):
    p = Path(relative)
    if p.is_absolute() or ".." in p.parts:
        raise Failure("Path traversal refused")
    full = home / p
    for part in [home, *[home / Path(*p.parts[:i]) for i in range(1, len(p.parts) + 1)]]:
        if part.is_symlink():
            raise Failure("Symlink target/ancestor refused")
        if part.exists() and part != full and not part.is_dir():
            raise Failure("Non-directory target ancestor refused")
    if full.exists() and not full.is_file():
        raise Failure("Target must be an ordinary file")
    return full


def load_json(path):
    if re.search(r"(?i)^(?:\.env|auth(?:[._-]|$)|credentials?(?:[._-]|$)|id_rsa|id_ed25519)", path.name) or any(x in {".ssh", ".aws", ".kube", "sessions"} for x in path.parts):
        raise Failure("Credential/session filenames are outside configuration scope")
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 2_000_000:
        raise Failure("Invalid JSON source")
    return json.loads(path.read_text())


def home_path(value, mutation=False, allow_live=False):
    p = Path(value)
    if not p.is_absolute() or p != p.resolve() or not p.is_dir() or p == Path("/"):
        raise Failure("HOME must be an existing absolute directory without symlinks")
    if mutation and not allow_live:
        # TMPDIR is caller-controlled and cannot broaden the live-write gate.
        temps = [Path("/tmp").resolve(), Path("/var/tmp").resolve()]
        if not any(temp in p.parents for temp in temps) or p == Path.home().resolve():
            raise Failure("Live HOME writes require explicit --allow-live-home after host approval")
        try:
            import pwd
            if p == Path(pwd.getpwuid(os.getuid()).pw_dir).resolve():
                raise Failure("Account HOME requires explicit --allow-live-home")
        except ImportError:
            pass
    return p


def config(path, home):
    c = {} if path is None else load_json(Path(path))
    if not isinstance(c, dict) or set(c) - {"personal_identity", "personal_roots", "machine"}:
        raise Failure("Unknown configuration keys")
    identity = c.get("personal_identity")
    roots = c.get("personal_roots", [])
    if not isinstance(roots, list) or len(roots) > 20:
        raise Failure("personal_roots must be a bounded list")
    if bool(identity) != bool(roots):
        raise Failure("Identity and personal_roots must be configured together")
    if identity:
        if not isinstance(identity, dict) or set(identity) != {"name", "email"}:
            raise Failure("Identity requires exactly name/email")
        for value in identity.values():
            safe_text(value)
            if "<" in value or "PLACEHOLDER" in value or "REPLACE" in value:
                raise Failure("Replace identity placeholders locally")
        if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", identity["email"]):
            raise Failure("Invalid email syntax")
    normalized = []
    for root in roots:
        root = safe_text(root).replace("${HOME}", str(home))
        if re.search(r"[\[\]*?{}<>$`]", root) or ".." in Path(root).parts:
            raise Failure("Glob/placeholders/traversal in personal_roots refused")
        p = Path(root)
        if not p.is_absolute() or p != p.resolve() or home not in p.parents:
            raise Failure("Personal roots must be concrete subdirectories of selected HOME")
        normalized.append(str(p))
    machine = c.get("machine", {})
    if not isinstance(machine, dict) or set(machine) - {"editor", "label"}:
        raise Failure("Unknown machine keys")
    editor = machine.get("editor", "vim")
    if editor not in {"vim", "nvim", "code", "zed"}:
        raise Failure("Editor must be an allowlisted executable name")
    label = machine.get("label", "generic-linux")
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,64}", label):
        raise Failure("Invalid local machine label")
    return {"personal_identity": identity, "personal_roots": normalized, "machine": {"editor": editor, "label": label}}


def quote_git(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def payload(profiles, c):
    manifests = [load_json(ROOT / "manifest.json"), load_json(ROOT / "profile-manifest.json")]
    if set(manifests[0]) != set(BASE):
        raise Failure("Base manifest allowlist drift", 4)
    expected_optional = {s: d for p in OPTIONAL.values() for s, d in p.items()}
    if set(manifests[1]) != set(expected_optional):
        raise Failure("Optional manifest allowlist drift", 4)
    selected = dict(BASE)
    for profile in profiles:
        selected.update(OPTIONAL.get(profile, {}))
    result = {}
    for source, dest in selected.items():
        manifest = manifests[0] if source in BASE else manifests[1]
        entry = manifest[source]
        if set(entry) != {"sha256", "destination"} or entry["destination"] != dest:
            raise Failure("Manifest destination drift", 4)
        path = target_path(ROOT, source)
        if not path.is_file():
            raise Failure("Missing source file", 4)
        data = path.read_bytes()
        if digest(data) != entry["sha256"]:
            raise Failure("Source hash drift", 4)
        result[dest] = data
    if c["personal_identity"]:
        value = result[".gitconfig"].decode()
        for root in c["personal_roots"]:
            value += "\n[includeIf " + quote_git("gitdir:" + root + "/**") + "]\n\tpath = ~/.config/git/personal.inc\n"
        result[".gitconfig"] = value.encode()
        identity = c["personal_identity"]
        result[".config/git/personal.inc"] = ("[user]\n\tname = " + quote_git(identity["name"]) + "\n\temail = " + quote_git(identity["email"]) + "\n").encode()
    if "machine" in profiles:
        result[".zshrc"] += ("\n# Explicit machine profile; no external source/eval.\nexport EDITOR=" + c["machine"]["editor"] + "\nexport VISUAL=" + c["machine"]["editor"] + "\n").encode()
        result[".config/personal-dotfiles/machine.json"] = canonical(c["machine"]) + b"\n"
    return result


def read_state(home):
    p = target_path(home, STATE + "/current.json")
    if not p.exists():
        return {"managed": {}, "latest": None}
    state = load_json(p)
    if not isinstance(state, dict) or set(state) != {"managed", "latest"} or not isinstance(state["managed"], dict):
        raise Failure("Invalid managed state", 4)
    if any(n not in TARGETS or not isinstance(h, str) or not re.fullmatch("[0-9a-f]{64}", h) for n, h in state["managed"].items()) or (state["latest"] is not None and (not isinstance(state["latest"], str) or not re.fullmatch("[0-9a-f]{32}", state["latest"]))):
        raise Failure("Unsafe managed state", 4)
    return state


def make_plan(home, profiles, c):
    data = payload(profiles, c)
    state = read_state(home)
    managed = state["managed"]
    files = []
    for name, content in sorted(data.items()):
        p = target_path(home, name)
        old = digest(p.read_bytes()) if p.exists() else None
        new = digest(content)
        action = "create" if old is None else "unchanged" if old == new else "update" if managed.get(name) == old else "conflict"
        files.append({"path": name, "before_sha256": old, "after_sha256": new, "action": action})
    plan = {"home": str(home), "profiles": profiles, "config_sha256": digest(canonical(c)), "state_sha256": digest(canonical(state)), "files": files}
    plan["plan_id"] = digest(canonical(plan))
    return plan, data


def write(home, name, data):
    p = target_path(home, name)
    p.parent.mkdir(parents=True, exist_ok=True)
    p = target_path(home, name)
    tmp = p.parent / (".dotfiles-write-" + uuid.uuid4().hex)
    fd = os.open(tmp, os.O_CREAT | os.O_EXCL | os.O_WRONLY | getattr(os, "O_NOFOLLOW", 0), 0o600)
    with os.fdopen(fd, "wb") as output:
        output.write(data)
        output.flush()
        os.fsync(output.fileno())
    os.replace(tmp, p)


def require_plan(plan, identifier):
    if not identifier or identifier != plan["plan_id"]:
        raise Failure("Review a fresh plan and pass its exact --plan-id", 4)


def apply(home, plan, data, identifier):
    require_plan(plan, identifier)
    if any(f["action"] == "conflict" for f in plan["files"]):
        raise Failure("Unmanaged existing configuration conflicts; preserved", 4)
    changed = [f for f in plan["files"] if f["action"] != "unchanged"]
    old_state = read_state(home)
    if not changed and all(old_state["managed"].get(f["path"]) == f["after_sha256"] for f in plan["files"]):
        return {"status": "unchanged", "plan_id": plan["plan_id"]}
    tx = uuid.uuid4().hex
    prefix = STATE + "/transactions/" + tx
    journal = {"id": tx, "home": str(home), "status": "prepared", "files": changed, "state_before": old_state}
    for f in changed:
        p = target_path(home, f["path"])
        if p.exists():
            write(home, prefix + "/before/" + f["path"], p.read_bytes())
    write(home, prefix + "/journal.json", canonical(journal) + b"\n")
    for f in changed:
        p = target_path(home, f["path"])
        old = digest(p.read_bytes()) if p.exists() else None
        if old != f["before_sha256"]:
            raise Failure("Destination changed during apply; inspect prepared journal", 4)
        write(home, f["path"], data[f["path"]])
    for f in plan["files"]:
        if digest(target_path(home, f["path"]).read_bytes()) != f["after_sha256"]:
            raise Failure("Post-apply verification failed; preserve journal", 4)
    state = {"managed": dict(old_state["managed"]), "latest": tx}
    state["managed"].update({f["path"]: f["after_sha256"] for f in plan["files"]})
    write(home, STATE + "/current.json", canonical(state) + b"\n")
    journal["status"] = "applied"
    write(home, prefix + "/journal.json", canonical(journal) + b"\n")
    return {"status": "applied-and-verified" if changed else "adopted-and-verified", "transaction": tx, "changed_files": len(changed)}


def rollback_plan(home, tx):
    if not re.fullmatch("[0-9a-f]{32}", tx or ""):
        raise Failure("Invalid transaction id")
    state = read_state(home)
    if state["latest"] != tx:
        raise Failure("Rollback must target the latest active transaction", 4)
    journal = load_json(target_path(home, STATE + "/transactions/" + tx + "/journal.json"))
    if not isinstance(journal, dict) or set(journal) != {"id", "home", "status", "files", "state_before"} or not isinstance(journal["files"], list) or len(journal["files"]) > len(TARGETS) or not all(isinstance(f, dict) for f in journal["files"]):
        raise Failure("Malformed transaction journal", 4)
    if journal["id"] != tx or journal["home"] != str(home) or journal["status"] != "applied":
        raise Failure("Invalid transaction state", 4)
    before = journal["state_before"]
    if not isinstance(before, dict) or set(before) != {"managed", "latest"} or not isinstance(before["managed"], dict) or any(n not in TARGETS or not isinstance(h, str) or not re.fullmatch("[0-9a-f]{64}", h) for n, h in before["managed"].items()):
        raise Failure("Unsafe previous state", 4)
    if before["latest"] is not None and (not isinstance(before["latest"], str) or not re.fullmatch("[0-9a-f]{32}", before["latest"])):
        raise Failure("Unsafe previous transaction", 4)
    for f in journal["files"]:
        if set(f) != {"path", "before_sha256", "after_sha256", "action"} or not isinstance(f["path"], str) or f["path"] not in TARGETS or f["action"] not in {"create", "update"} or not isinstance(f["after_sha256"], str) or not re.fullmatch("[0-9a-f]{64}", f["after_sha256"]) or (f["before_sha256"] is not None and (not isinstance(f["before_sha256"], str) or not re.fullmatch("[0-9a-f]{64}", f["before_sha256"]))):
            raise Failure("Unsafe journal operation", 4)
        p = target_path(home, f["path"])
        if not p.exists() or digest(p.read_bytes()) != f["after_sha256"]:
            raise Failure("Rollback refuses drift; preserve user edits", 4)
        if f["before_sha256"] is not None:
            b = target_path(home, STATE + "/transactions/" + tx + "/before/" + f["path"])
            if digest(b.read_bytes()) != f["before_sha256"]:
                raise Failure("Rollback backup hash drift", 4)
    if len({f["path"] for f in journal["files"]}) != len(journal["files"]):
        raise Failure("Duplicate journal operations", 4)
    plan = {"home": str(home), "transaction": tx, "files": journal["files"], "operation": "rollback", "journal_sha256": digest(canonical(journal))}
    plan["plan_id"] = digest(canonical(plan))
    return plan, journal


def rollback(home, tx, identifier):
    plan, journal = rollback_plan(home, tx)
    require_plan(plan, identifier)
    prefix = STATE + "/transactions/" + tx
    for f in journal["files"]:
        # Preserve every current managed byte in the journal; never unlink files.
        p = target_path(home, f["path"])
        data = p.read_bytes()
        if digest(data) != f["after_sha256"]:
            raise Failure("Destination changed during rollback; preserve journal", 4)
        write(home, prefix + "/retired/" + f["path"], data)
        if f["before_sha256"] is None:
            retired = target_path(home, prefix + "/moved/" + f["path"])
            retired.parent.mkdir(parents=True, exist_ok=True)
            os.replace(p, retired)
        else:
            b = target_path(home, prefix + "/before/" + f["path"])
            data = b.read_bytes()
            if digest(data) != f["before_sha256"]:
                raise Failure("Backup changed during rollback; preserve journal", 4)
            write(home, f["path"], data)
    write(home, STATE + "/current.json", canonical(journal["state_before"]) + b"\n")
    journal["status"] = "rolled-back"
    write(home, prefix + "/journal.json", canonical(journal) + b"\n")
    return {"status": "rolled-back", "transaction": tx, "all_retired_bytes_preserved": True}


def pending_transactions(home):
    folder = target_path(home, STATE + "/transactions/probe").parent
    pending = []
    if folder.exists():
        for p in folder.iterdir():
            if not re.fullmatch("[0-9a-f]{32}", p.name):
                continue
            journal = load_json(target_path(home, STATE + "/transactions/" + p.name + "/journal.json"))
            if not isinstance(journal, dict) or journal.get("status") not in {"applied", "rolled-back"}:
                pending.append(p.name)
    return pending


def main():
    parser = Parser(description=__doc__)
    parser.add_argument("command", choices=["plan", "doctor", "apply", "verify", "rollback-plan", "rollback"])
    parser.add_argument("--home", required=True)
    parser.add_argument("--profile", choices=["base", "dev", "machine", "ai"], action="append", default=[])
    parser.add_argument("--config")
    parser.add_argument("--plan-id")
    parser.add_argument("--transaction")
    parser.add_argument("--allow-live-home", action="store_true", help="Requires prior explicit host/TI authorization; never used during preparation")
    args = parser.parse_args()
    mutation = args.command in {"apply", "rollback"}
    home = home_path(args.home, mutation, args.allow_live_home)
    if args.command in {"rollback-plan", "rollback"}:
        if args.command == "rollback-plan":
            output, _ = rollback_plan(home, args.transaction)
        else:
            output = rollback(home, args.transaction, args.plan_id)
        print(json.dumps(output, indent=2))
        return 0
    profiles = sorted(set(["base", *args.profile]))
    c = config(args.config, home)
    plan, data = make_plan(home, profiles, c)
    if args.command == "plan":
        print(json.dumps(plan, indent=2))
        return 4 if any(f["action"] == "conflict" for f in plan["files"]) else 0
    if args.command == "apply":
        print(json.dumps(apply(home, plan, data, args.plan_id), indent=2))
        return 0
    drift = [f["path"] for f in plan["files"] if f["action"] != "unchanged"]
    if args.command == "verify":
        print(json.dumps({"verified": not drift, "drift_or_missing": drift}, indent=2))
        return 4 if drift else 0
    required = sorted({tool for profile in profiles for tool in TOOLS[profile]} | ({c["machine"]["editor"]} if "machine" in profiles else set()))
    missing = [tool for tool in required if shutil.which(tool) is None]
    pending = pending_transactions(home)
    print(json.dumps({"profiles": profiles, "missing_tools": missing, "target_drift_or_missing": drift, "conflicts": [f["path"] for f in plan["files"] if f["action"] == "conflict"], "pending_transactions": pending, "personal_identity_explicit": bool(c["personal_identity"]), "nix_validation": "not performed"}, indent=2))
    return 4 if pending or any(f["action"] == "conflict" for f in plan["files"]) else 2 if missing or drift else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Failure as error:
        print(json.dumps({"error": str(error), "exit_code": error.code}))
        raise SystemExit(error.code)
    except (ValueError, TypeError, KeyError, json.JSONDecodeError):
        print(json.dumps({"error": "Malformed input or metadata", "exit_code": 3}))
        raise SystemExit(3)
    except OSError:
        print(json.dumps({"error": "I/O failure; preserve and inspect any prepared journal", "exit_code": 5}))
        raise SystemExit(5)
