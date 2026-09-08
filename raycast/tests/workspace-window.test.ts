import test from "node:test";
import assert from "node:assert/strict";
import {
  mkdtemp,
  mkdir,
  writeFile,
  chmod,
  realpath,
  rm,
  lstat,
  symlink,
} from "node:fs/promises";
import { tmpdir, hostname } from "node:os";
import { pathToFileURL } from "node:url";
import { join } from "node:path";
import { openWorkspace } from "../src/workspace";

async function fixture() {
  const home = await mkdtemp(join(await realpath(tmpdir()), "wezterm-window-"));
  const app = join(home, "Custom WezTerm.app");
  const bin = join(app, "Contents/MacOS");
  await mkdir(bin, { recursive: true });
  for (const name of ["wezterm", "wezterm-gui"]) {
    await writeFile(join(bin, name), "fixture only");
    await chmod(join(bin, name), 0o755);
  }
  await writeFile(join(app, "Contents/Info.plist"), "<plist></plist>");
  const cwd = join(home, "folder space ' $() 日本語");
  await mkdir(cwd);
  return {
    home,
    app,
    cwd,
    settings: { repo: home, executable: join(bin, "wezterm") },
  };
}

test("invalid app settings and LaunchServices failures are actionable without another app fallback", async () => {
  const f = await fixture();
  try {
    const run = async () => {
      throw new Error("launch denied");
    };
    await assert.rejects(
      openWorkspace(
        { workspace: "main", cwd: f.cwd },
        { settings: f.settings, run },
      ),
      /could not.*new.*window.*WezTerm|could not.*WezTerm.*window/i,
    );
    await rm(join(f.app, "Contents/Info.plist"));
    await assert.rejects(
      openWorkspace(
        { workspace: "main", cwd: f.cwd },
        { settings: f.settings, run },
      ),
      /Executable preference.*\.app/i,
    );
    await writeFile(join(f.home, "standalone"), "fixture");
    await chmod(join(f.home, "standalone"), 0o755);
    await assert.rejects(
      openWorkspace(
        { workspace: "main", cwd: f.cwd },
        {
          settings: { ...f.settings, executable: join(f.home, "standalone") },
          run,
        },
      ),
      /Executable preference.*\.app/i,
    );
  } finally {
    await rm(f.home, { recursive: true, force: true });
  }
});

test("path-based running workspaces and executable symlinks need no inventory", async () => {
  const f = await fixture();
  try {
    const alias = join(f.home, "wezterm");
    await symlink(f.settings.executable, alias);
    for (const workspace of [f.cwd, "~" + f.cwd.slice(f.home.length)]) {
      await openWorkspace(
        { workspace },
        {
          home: f.home,
          settings: { ...f.settings, executable: alias },
          run: async (file, args) => {
            assert.equal(file, "/usr/bin/open");
            assert.equal(args[2], f.app);
            assert.equal(args.at(-1), f.cwd);
            return { stdout: "", stderr: "" };
          },
        },
      );
    }
  } finally {
    await rm(f.home, { recursive: true, force: true });
  }
});

test("missing, remote, malformed and failed inventory never launches a window", async () => {
  const f = await fixture();
  try {
    for (const cwd of [
      `file://remote.invalid${f.cwd}`,
      `ssh://localhost${f.cwd}`,
      f.cwd,
      "file:///missing",
      "file:///tmp?ignored",
      "not a url",
    ]) {
      await assert.rejects(
        openWorkspace(
          { workspace: "opaque" },
          {
            settings: f.settings,
            run: async (file) => {
              assert.equal(file, f.settings.executable);
              return {
                stdout: JSON.stringify([{ workspace: "opaque", cwd }]),
                stderr: "",
              };
            },
          },
        ),
        /No existing local directory.*Choose/i,
      );
    }
    for (const output of [
      "invalid",
      "{}",
      "null",
      "[]",
      '[null,false,7,"opaque",[],{}, {"workspace":"opaque","cwd":42}]',
    ]) {
      await assert.rejects(
        openWorkspace(
          { workspace: "opaque" },
          {
            settings: f.settings,
            run: async (file) => {
              assert.equal(file, f.settings.executable);
              return { stdout: output, stderr: "" };
            },
          },
        ),
        /No existing local directory/i,
      );
    }
    for (const failure of [
      new Error("timeout"),
      new Error("failed to connect to GUI"),
      Object.assign(new Error("failed to connect"), { code: "ENOENT" }),
      Object.assign(new Error("failed to connect"), { killed: true }),
      new SyntaxError("transport failure"),
    ]) {
      let calls = 0;
      await assert.rejects(
        openWorkspace(
          { workspace: "opaque" },
          {
            settings: f.settings,
            run: async (file) => {
              calls++;
              assert.equal(file, f.settings.executable);
              throw failure;
            },
          },
        ),
        /No existing local directory/i,
      );
      assert.equal(calls, 1, "Failed inventory must never launch");
    }
    for (const cwd of [join(f.home, "missing"), f.settings.executable]) {
      await assert.rejects(
        openWorkspace(
          { workspace: "main", cwd },
          {
            settings: f.settings,
            run: async () => {
              assert.fail("must not launch or query");
            },
          },
        ),
        /No existing local directory/i,
      );
    }
  } finally {
    await rm(f.home, { recursive: true, force: true });
  }
});

test("opaque workspace resolves only an existing local file URL from fresh inventory", async () => {
  const f = await fixture();
  try {
    for (const host of ["", "localhost", hostname()]) {
      const url = pathToFileURL(f.cwd);
      url.hostname = host;
      const calls: string[] = [];
      await openWorkspace(
        { workspace: "opaque" },
        {
          settings: f.settings,
          run: async (file, args, options) => {
            calls.push(file);
            if (file === f.settings.executable) {
              assert.deepEqual(args, [
                "cli",
                "--no-auto-start",
                "list",
                "--format",
                "json",
              ]);
              assert.equal(options.timeout, 2500);
              return {
                stdout: JSON.stringify([
                  null,
                  false,
                  7,
                  "opaque",
                  [],
                  {},
                  { workspace: "opaque", cwd: 42 },
                  { workspace: "unrelated", cwd: pathToFileURL(f.home).href },
                  { workspace: "opaque", cwd: `file://remote.invalid${f.cwd}` },
                  { workspace: "opaque", cwd: url.href },
                ]),
                stderr: "",
              };
            }
            assert.equal(file, "/usr/bin/open");
            assert.equal(args.at(-1), f.cwd);
            return { stdout: "", stderr: "" };
          },
        },
      );
      assert.deepEqual(calls, [f.settings.executable, "/usr/bin/open"]);
    }
  } finally {
    await rm(f.home, { recursive: true, force: true });
  }
});

test("each workspace acceptance requests a fresh independent app process with literal argv and no mailbox", async () => {
  const f = await fixture();
  try {
    const calls: unknown[] = [];
    for (let i = 0; i < 2; i++) {
      await openWorkspace(
        { workspace: "named ' $(literal)", cwd: f.cwd },
        {
          home: f.home,
          settings: f.settings,
          run: async (file, args, options) => {
            calls.push([file, args]);
            assert.equal(options.shell, false);
            assert.equal(options.timeout, 5000);
            return { stdout: "", stderr: "" };
          },
        },
      );
    }
    assert.deepEqual(
      calls,
      Array(2).fill([
        "/usr/bin/open",
        [
          "-n",
          "-a",
          f.app,
          "--env",
          "WEZMACS_RAYCAST_NEW_WINDOW=1",
          "--args",
          "start",
          "--always-new-process",
          "--no-auto-connect",
          "--domain",
          "local",
          "--workspace",
          "named ' $(literal)",
          "--cwd",
          f.cwd,
        ],
      ]),
    );
    await assert.rejects(lstat(join(f.home, ".cache")), { code: "ENOENT" });
  } finally {
    await rm(f.home, { recursive: true, force: true });
  }
});
