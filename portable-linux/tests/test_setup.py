#!/usr/bin/env python3
"""Offline Linux rehearsal. Fixtures remain in temp directories; no deletion."""
import hashlib
import json
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = Path(tempfile.mkdtemp(prefix="personal-dotfiles-test-"))
        self.home = self.temp / "home"
        self.home.mkdir()
        self.envhome = self.temp / "env"
        self.envhome.mkdir()
        self.env = {"PATH": "/usr/bin:/bin", "HOME": str(self.envhome), "LANG": "C", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "PYTHONDONTWRITEBYTECODE": "1"}
        self.source = ROOT

    def cli(self, command, *args, code=0, env=None):
        run = subprocess.run([sys.executable, str(self.source / "setup.py"), command, "--home", str(self.home), *args], env=env or self.env, capture_output=True, text=True)
        self.assertEqual(run.returncode, code, run.stdout + run.stderr)
        result = json.loads(run.stdout)
        return result

    def plan_apply(self, *args):
        plan = self.cli("plan", *args)
        applied = self.cli("apply", *args, "--plan-id", plan["plan_id"])
        return applied

    def local_config(self, **overrides):
        data = {"personal_identity": {"name": "Example User", "email": "person@example.invalid"}, "personal_roots": ["${HOME}/projects/personal"], "machine": {"editor": "vim", "label": "example-linux"}}
        data.update(overrides)
        path = self.temp / "local.json"
        path.write_text(json.dumps(data))
        return ["--config", str(path)]

    def copy_source(self, omit=None):
        self.source = self.temp / "source"
        shutil.copytree(ROOT, self.source, ignore=shutil.ignore_patterns(omit) if omit else None)

    def journal(self, tx):
        return self.home / ".local/state/personal-dotfiles/transactions" / tx / "journal.json"

    def test_plan_has_no_writes(self):
        p = self.cli("plan")
        self.assertEqual(len(p["files"]), 3)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_apply_verify_and_idempotence(self):
        self.plan_apply()
        self.cli("verify")
        self.assertEqual(self.plan_apply()["status"], "unchanged")
        text = (self.home / ".gitconfig").read_text()
        self.assertIn("useConfigOnly = true", text)

    def test_doctor_unapplied_then_applied(self):
        self.cli("doctor", code=2)
        self.plan_apply()
        self.cli("doctor")

    def test_adoption_of_identical_bytes_allows_managed_update(self):
        for source, dest in {"files/vimrc": ".vimrc", "files/zshrc": ".zshrc", "files/gitconfig": ".gitconfig"}.items():
            (self.home / dest).write_bytes((ROOT / source).read_bytes())
        self.assertEqual(self.plan_apply()["status"], "adopted-and-verified")
        self.plan_apply("--profile", "machine")
        self.cli("verify", "--profile", "machine")

    def test_all_profiles_and_identity_scope(self):
        args = ["--profile", "dev", "--profile", "machine", "--profile", "ai", *self.local_config()]
        p = self.cli("plan", *args)
        self.assertNotIn("Example User", json.dumps(p))
        self.plan_apply(*args)
        self.cli("verify", *args)
        self.assertTrue((self.home / ".config/personal-ai/AGENTS.md").exists())
        self.assertIn("export EDITOR=vim", (self.home / ".zshrc").read_text())
        self.assertNotIn("source ", (self.home / ".zshrc").read_text())
        personal = self.home / "projects/personal/sample"
        other = self.home / "projects/other"
        for directory in [personal, other]:
            directory.mkdir(parents=True)
            subprocess.run(["/usr/bin/git", "init", "-q", str(directory)], check=True, env=self.env)
        env = dict(self.env, HOME=str(self.home), GIT_CONFIG_GLOBAL=str(self.home / ".gitconfig"))
        r = subprocess.run(["/usr/bin/git", "-C", str(personal), "config", "user.name"], env=env, capture_output=True, text=True)
        self.assertEqual(r.stdout.strip(), "Example User")
        r = subprocess.run(["/usr/bin/git", "-C", str(other), "config", "user.name"], env=env, capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        r = subprocess.run(["/usr/bin/git", "-C", str(other), "var", "GIT_AUTHOR_IDENT"], env=env, capture_output=True)
        self.assertNotEqual(r.returncode, 0)

    def test_unmanaged_configuration_preserved(self):
        (self.home / ".vimrc").write_text("user fixture\n")
        p = self.cli("plan", code=4)
        self.cli("apply", "--plan-id", p["plan_id"], code=4)
        self.assertEqual((self.home / ".vimrc").read_text(), "user fixture\n")
        self.assertFalse((self.home / ".local").exists())

    def test_destination_drift_stales_plan(self):
        p = self.cli("plan")
        (self.home / ".vimrc").write_text("new user fixture\n")
        self.cli("apply", "--plan-id", p["plan_id"], code=4)
        self.assertFalse((self.home / ".local").exists())

    def test_source_hash_drift(self):
        self.copy_source()
        (self.source / "files/vimrc").write_text("unreviewed\n")
        self.cli("plan", code=4)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_symlink_source(self):
        self.copy_source("vimrc")
        (self.source / "files/vimrc").symlink_to(ROOT / "files/vimrc")
        self.cli("plan", code=3)

    def test_symlink_destination_ancestor(self):
        other = self.temp / "other"
        other.mkdir()
        (self.home / ".config").symlink_to(other, target_is_directory=True)
        self.cli("plan", "--profile", "dev", code=3)
        self.assertEqual(list(other.iterdir()), [])

    def test_manifest_traversal(self):
        self.copy_source()
        p = self.source / "manifest.json"
        m = json.loads(p.read_text())
        m["files/vimrc"]["destination"] = "../escape"
        p.write_text(json.dumps(m))
        self.cli("plan", code=4)

    def test_config_control_character_rejected(self):
        args = self.local_config(personal_identity={"name": "Example\n[include]", "email": "person@example.invalid"})
        self.cli("plan", *args, code=3)

    def test_editor_command_injection_rejected(self):
        self.cli("plan", "--profile", "machine", *self.local_config(machine={"editor": "vim; touch injected"}), code=3)
        self.assertFalse((self.home / "injected").exists())

    def test_personal_root_traversal_rejected(self):
        self.cli("plan", *self.local_config(personal_roots=["${HOME}/../other"]), code=3)

    def test_broad_identity_root_rejected(self):
        self.cli("plan", *self.local_config(personal_roots=["${HOME}"]), code=3)

    def test_placeholder_identity_rejected(self):
        self.cli("plan", "--config", str(ROOT / "config.example.json"), code=3)

    def test_source_optional_allowlist_drift(self):
        self.copy_source()
        p = self.source / "profile-manifest.json"
        m = json.loads(p.read_text())
        m["extra"] = {"destination": ".extra", "sha256": "0" * 64}
        p.write_text(json.dumps(m))
        self.cli("plan", code=4)

    def test_rollback_new_files_preserves_retired_bytes(self):
        tx = self.plan_apply()["transaction"]
        old = (self.home / ".vimrc").read_bytes()
        p = self.cli("rollback-plan", "--transaction", tx)
        self.cli("rollback", "--transaction", tx, "--plan-id", p["plan_id"])
        self.assertFalse((self.home / ".vimrc").exists())
        retired = self.journal(tx).parent / "moved/.vimrc"
        self.assertEqual(retired.read_bytes(), old)
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_managed_update_and_rollback(self):
        self.plan_apply()
        base = (self.home / ".zshrc").read_bytes()
        tx = self.plan_apply("--profile", "machine")["transaction"]
        self.cli("verify", "--profile", "machine")
        p = self.cli("rollback-plan", "--transaction", tx)
        self.cli("rollback", "--transaction", tx, "--plan-id", p["plan_id"])
        self.assertEqual((self.home / ".zshrc").read_bytes(), base)
        self.cli("verify")

    def test_rollback_refuses_user_edit(self):
        tx = self.plan_apply()["transaction"]
        (self.home / ".vimrc").write_text("user edit\n")
        self.cli("rollback-plan", "--transaction", tx, code=4)
        self.assertEqual((self.home / ".vimrc").read_text(), "user edit\n")

    def test_stale_transaction_rejected(self):
        tx = self.plan_apply()["transaction"]
        self.plan_apply("--profile", "machine")
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_journal_injection_rejected(self):
        tx = self.plan_apply()["transaction"]
        p = self.journal(tx)
        data = json.loads(p.read_text())
        data["files"][0]["path"] = ".config/unmanaged-tool/settings.json"
        p.write_text(json.dumps(data))
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_duplicate_journal_rejected(self):
        tx = self.plan_apply()["transaction"]
        p = self.journal(tx)
        data = json.loads(p.read_text())
        data["files"].append(data["files"][0])
        p.write_text(json.dumps(data))
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_malformed_journal_operations_rejected(self):
        tx = self.plan_apply()["transaction"]
        p = self.journal(tx)
        data = json.loads(p.read_text())
        data["files"] = ["not an operation"]
        p.write_text(json.dumps(data))
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_malformed_state_rejected(self):
        self.plan_apply()
        p = self.home / ".local/state/personal-dotfiles/current.json"
        data = json.loads(p.read_text())
        data["latest"] = 1
        p.write_text(json.dumps(data))
        self.cli("plan", code=4)

    def test_credential_named_config_is_never_accepted(self):
        p = self.temp / "auth.json"
        p.write_text("not a settings document")
        self.cli("plan", "--config", str(p), code=3)

    def test_live_home_blocked_before_read_or_write(self):
        actual = pwd.getpwuid(os.getuid()).pw_dir
        r = subprocess.run([sys.executable, str(ROOT / "setup.py"), "apply", "--home", actual, "--plan-id", "0" * 64], env=self.env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 3)

    def test_missing_tools_reported_without_execution(self):
        self.plan_apply()
        p = self.cli("doctor", code=2, env=dict(self.env, PATH=""))
        self.assertIn("git", p["missing_tools"])

    def test_tmpdir_cannot_bypass_live_gate(self):
        env = dict(self.env, TMPDIR=str(ROOT.parent))
        self.cli("apply", "--home", str(ROOT), "--plan-id", "0" * 64, code=3, env=env)

    def test_invalid_plan_id_writes_nothing(self):
        self.cli("apply", "--plan-id", "0" * 64, code=4)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_rollback_backup_tamper(self):
        self.plan_apply()
        tx = self.plan_apply("--profile", "machine")["transaction"]
        (self.journal(tx).parent / "before/.zshrc").write_text("tamper\n")
        self.cli("rollback-plan", "--transaction", tx, code=4)

    def test_unknown_profile_usage_code(self):
        self.cli("plan", "--profile", "unknown", code=3)

    def test_legacy_restore_compatibility(self):
        path = self.temp / "legacy"
        path.mkdir()
        for option in [[], ["--apply"], ["--verify"]]:
            r = subprocess.run([sys.executable, str(ROOT / "restore.py"), "--scratch-home", str(path), *option], env=self.env, capture_output=True)
            self.assertEqual(r.returncode, 0)

    def test_pending_transaction_reported(self):
        tx = self.plan_apply()["transaction"]
        p = self.journal(tx)
        data = json.loads(p.read_text())
        data["status"] = "prepared"
        p.write_text(json.dumps(data))
        r = self.cli("doctor", code=4)
        self.assertEqual(r["pending_transactions"], [tx])


if __name__ == "__main__":
    unittest.main()
