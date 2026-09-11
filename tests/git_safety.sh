#!/usr/bin/env bash
# Test-owned local repositories, inert helper sentinels, no GUI or network.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path.cwd()
with tempfile.TemporaryDirectory(prefix="wezmacs-git-safety-") as tmp:
    fixture = Path(tmp).resolve()
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    home, tools = fixture / "home", fixture / "tools"
    home.mkdir()
    tools.mkdir()
    env.update(HOME=str(home), GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=str(home / "gitconfig"),
               GIT_TERMINAL_PROMPT="0", GIT_ALLOW_PROTOCOL="file:wezmacs-sentinel",
               WEZMACS_GIT_SAFETY=str(fixture), WEZMACS_SMOKE_ROOT=str(root),
               WEZMACSDIR=str(root / "tests/fixtures/smoke"), WEZTERM_LOG="info",
               PATH=str(tools) + os.pathsep + os.environ["PATH"])

    def run(*args, check=True):
        result = subprocess.run(args, env=env, capture_output=True)
        if check and result.returncode:
            raise AssertionError(f"{args!r}: {result.stderr.decode(errors='replace')}")
        return result

    def git(repo, *args, check=True):
        return run("git", "-C", str(repo), *args, check=check)

    def helper(name, body):
        path = tools / name
        path.write_text('#!/bin/sh\n' + body + '\n')
        path.chmod(0o700)
        return str(path)

    monitor = helper("monitor", 'printf ran > "$WEZMACS_GIT_SAFETY/fsmonitor-ran"')
    clean = helper("clean", 'printf ran > "$WEZMACS_GIT_SAFETY/clean-ran"\ntr a-z A-Z')
    process = helper("process", 'printf ran > "$WEZMACS_GIT_SAFETY/process-ran"\nexit 1')
    helper("git-remote-wezmacs-sentinel", 'printf ran > "$WEZMACS_GIT_SAFETY/transport-ran"\nexit 1')
    run("git", "config", "--global", "filter.lfs.clean", clean)
    run("git", "config", "--global", "filter.lfs.process", process)
    ordinary = fixture / "ordinary"
    run("git", "-c", "init.templateDir=", "init", "-q", "-b", "main", str(ordinary))
    for key, value in {"user.name": "Fixture", "user.email": "fixture@example.invalid",
                       "commit.gpgsign": "false", "core.hooksPath": "/dev/null",
                       "uploadpack.allowFilter": "true", "core.autocrlf": "false"}.items():
        git(ordinary, "config", key, value)
    (ordinary / "tracked.txt").write_text("base\n")
    (ordinary / ".gitattributes").write_text("tracked.txt text eol=lf\n")
    git(ordinary, "add", ".")
    git(ordinary, "commit", "-qm", "base")
    (ordinary / "tracked.txt").write_text("second\n")
    git(ordinary, "add", ".")
    git(ordinary, "commit", "-qm", "second")
    blob = git(ordinary, "rev-parse", "HEAD:tracked.txt").stdout.decode().strip()
    partial = fixture / "partial"
    run("git", "-c", "init.templateDir=", "clone", "-q", "--filter=blob:none", "--no-checkout",
        ordinary.as_uri(), str(partial))
    assert list((partial / ".git/objects/pack").glob("*.promisor")), "actual partial-clone pack required"
    git(partial, "remote", "set-url", "origin", "wezmacs-sentinel::local-only")
    assert git(partial, "--no-lazy-fetch", "cat-file", "-e", blob, check=False).returncode != 0
    # Positive control proves an unguarded missing-object read invokes ONLY our inert transport.
    assert git(partial, "cat-file", "-p", blob, check=False).returncode != 0
    assert (fixture / "transport-ran").is_file(), "promisor sentinel must be reachable"
    (fixture / "transport-ran").unlink()

    for name in ("clean", "process", "untracked-only", "no-helper", "info-attribute", "index-attribute"):
        shutil.copytree(ordinary, fixture / name)
    # Built-in normalization must remain intact: CRLF compares equal to the LF commit.
    (ordinary / "tracked.txt").write_bytes(b"second\r\n")
    for name in ("clean", "process", "info-attribute", "index-attribute"):
        repo = fixture / name
        kind = "process" if name == "process" else "clean"
        git(repo, "config", "filter.fixture." + kind, process if kind == "process" else clean)
        attributes = repo / ".gitattributes"
        if name == "info-attribute":
            attributes = repo / ".git/info/attributes"
            attributes.parent.mkdir(exist_ok=True)
        attributes.write_text("tracked.txt filter=fixture\n")
        if name == "index-attribute":
            git(repo, "add", ".gitattributes")
            attributes.unlink()
        (repo / "tracked.txt").write_text("dirty\n")
    (fixture / "untracked-only/.gitattributes").write_text("untracked.txt filter=lfs\n")
    (fixture / "untracked-only/untracked.txt").write_text("untracked\n")
    (fixture / "no-helper/.gitattributes").write_text("tracked.txt filter=undefined\n")
    for name in ("ordinary", "clean", "process", "untracked-only", "no-helper", "info-attribute", "index-attribute"):
        git(fixture / name, "config", "core.fsmonitor", monitor)
    git(ordinary, "diff", "HEAD")
    assert (fixture / "fsmonitor-ran").is_file(), "monitor sentinel positive control"
    (fixture / "fsmonitor-ran").unlink()
    for kind in ("clean", "process"):
        git(fixture / kind, "-c", "core.fsmonitor=false", "diff", "HEAD", check=False)
        assert (fixture / (kind + "-ran")).is_file(), kind + " sentinel positive control"
        (fixture / (kind + "-ran")).unlink()

    # A dirty submodule can execute helpers configured only in its own checkout.
    superproject = fixture / "submodules"
    shutil.copytree(ordinary, superproject)
    git(superproject, "config", "core.fsmonitor", "false")
    git(superproject, "submodule", "add", "-q", ordinary.as_uri(), "nested")
    git(superproject, "commit", "-qm", "submodule")
    nested = superproject / "nested"
    git(nested, "checkout", "-q", "--detach", "HEAD~1")
    git(nested, "config", "filter.nested.clean", clean)
    (nested / ".gitattributes").write_text("tracked.txt filter=nested\n")
    (nested / "tracked.txt").write_text("dirty submodule\n")
    git(superproject, "config", "diff.submodule", "diff")
    git(superproject, "--no-optional-locks", "--no-lazy-fetch", "-c", "core.fsmonitor=false",
        "-c", "diff.autoRefreshIndex=false", "diff", "--no-ext-diff", "--no-textconv", "HEAD")
    assert (fixture / "clean-ran").is_file(), "inline dirty submodule positive control"
    (fixture / "clean-ran").unlink()

    def snapshot():
        return {str(p.relative_to(fixture)): hashlib.sha256(p.read_bytes()).hexdigest()
                for repo in fixture.iterdir() if (repo / ".git").is_dir()
                for p in (repo / ".git").rglob("*") if p.is_file()}

    setup_markers = [p.name for p in fixture.glob("*-ran")]
    assert not setup_markers, "test setup left helper markers: " + repr(setup_markers)
    before = snapshot()
    with (root / "tests/git_safety_fixture.lua").open("rb") as source:
        result = subprocess.run(["wezterm", "--config-file", "/dev/stdin", "show-keys", "--lua"],
                                stdin=source, capture_output=True, env=env)
    assert result.returncode == 0, result.stderr.decode(errors="replace")
    assert b"PASS real Git safety fixture" in result.stderr, result.stderr.decode(errors="replace")
    assert b"action = act.SendString '__WEZMACS_GIT_SAFETY_VALIDATED__'" in result.stdout, "native config fallback"
    after = snapshot()
    changed = [key for key in before.keys() | after.keys() if before.get(key) != after.get(key)]
    assert not changed, "Git administrative files/object storage changed: " + repr(changed)
    runtime_markers = [p.name for p in fixture.glob("*-ran")]
    assert not runtime_markers, "configured helper or promisor transport executed: " + repr(runtime_markers)
    print("PASS real Git safety: fsmonitor, clean/process, effective attributes, unused LFS, CRLF semantics, gitlink-only submodules, local promisor, unchanged Git storage")
PY
