import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, chmod, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

test("native bridge requires exactly one result and a rendered sentinel; passes request only in env", async () => {
  const api = await load();
  const settings = {
    repo: "/repo with spaces",
    executable: "/verified/wezterm",
  };
  const request = { op: "hosts" };
  let calls = 0;
  const run = async (
    file: string,
    args: string[],
    options: { env?: NodeJS.ProcessEnv; timeout?: number },
  ) => {
    calls++;
    assert.equal(file, settings.executable);
    assert.deepEqual(args, [
      "--config-file",
      "/repo with spaces/scripts/raycast.lua",
      "show-keys",
      "--lua",
    ]);
    assert.equal(options.env?.WEZMACS_RAYCAST_REQUEST, JSON.stringify(request));
    assert.equal(options.env?.WEZMACS_RAYCAST_ROOT, settings.repo);
    assert.equal(options.timeout, 20000);
    return {
      stdout: 'key="F24", SendString "WEZMACS_RAYCAST_OK"',
      stderr:
        'noise\nWEZMACS_RAYCAST_RESULT {"ok":true,"data":{"choices":[]}}\n',
    };
  };
  assert.deepEqual(await api.bridge(settings, request, run), { choices: [] });
  assert.equal(calls, 1);
  await assert.rejects(
    api.bridge(settings, request, async () => ({
      stdout: "native fallback",
      stderr: 'WEZMACS_RAYCAST_RESULT {"ok":true,"data":{}}',
    })),
    /sentinel|fallback/i,
  );
  await assert.rejects(
    api.bridge(settings, request, async () => ({
      stdout: "WEZMACS_RAYCAST_OK",
      stderr:
        'WEZMACS_RAYCAST_RESULT {"ok":false,"error":"Refresh hosts: tailnet changed"}',
    })),
    /tailnet changed/,
  );
  await assert.rejects(
    api.bridge(settings, request, async () => ({
      stdout: "WEZMACS_RAYCAST_OK",
      stderr: "WEZMACS_RAYCAST_RESULT {}\nWEZMACS_RAYCAST_RESULT {}",
    })),
    /result/i,
  );
});

test("discovery is read-only, preserves helper defaults and validates returned rows", async () => {
  const api = await load();
  const settings = { repo: "/repo", executable: "/wezterm" };
  const requests: unknown[] = [];
  const run: import("../src/backend").Run = async (_file, args, opts) => {
    if (args[0] === "cli") {
      assert.deepEqual(args, [
        "cli",
        "--no-auto-start",
        "list",
        "--format",
        "json",
      ]);
      return {
        stdout: JSON.stringify([
          { workspace: "main" },
          { workspace: "main" },
          { workspace: "other" },
        ]),
        stderr: "",
      };
    }
    const request = JSON.parse(opts.env!.WEZMACS_RAYCAST_REQUEST!);
    requests.push(request);
    const data =
      request.op === "hosts"
        ? {
            choices: [{ id: "a", label: "Alias" }],
            meta: {
              status: "Ready",
              targets: { a: { source: "config", target: "alias" } },
            },
          }
        : { choices: [{ id: "main", label: "main" }] };
    return {
      stdout: "WEZMACS_RAYCAST_OK",
      stderr: `WEZMACS_RAYCAST_RESULT ${JSON.stringify({ ok: true, data })}`,
    };
  };
  assert.equal(
    (await api.discoverWorkspaces(settings, run)).choices[0].id,
    "main",
  );
  assert.equal(
    (await api.discoverHosts(settings, run)).meta.targets.a.target,
    "alias",
  );
  assert.deepEqual(requests, [
    { op: "workspaces", workspaces: ["main", "other"] },
    { op: "hosts" },
  ]);
  assert.deepEqual(
    await api.liveWorkspaces(settings, async () => {
      throw new Error("failed to connect to GUI");
    }),
    [],
  );
  await assert.rejects(
    api.discoverHosts(settings, async () => ({
      stdout: "WEZMACS_RAYCAST_OK",
      stderr:
        'WEZMACS_RAYCAST_RESULT {"ok":true,"data":{"choices":[],"meta":null}}',
    })),
    /host.*result/i,
  );
});

test("SSH acceptance delegates full selection to Lua, rejects stale errors and spawns without waiting for exit", async () => {
  const api = await load();
  const { EventEmitter } = await import("node:events");
  const settings = { repo: "/repo", executable: "/verified/wezterm" };
  const selection = {
    target: "node",
    source: "tailscale",
    identity: "one",
    peer_id: "p",
    key: "k",
  };
  let launched = 0;
  let unref = 0;
  const spawn: import("../src/backend").Spawn = (file, args, opts) => {
    launched++;
    assert.equal(file, settings.executable);
    assert.deepEqual(args, ["ssh", "--", "node:22"]);
    assert.deepEqual(opts, { detached: true, stdio: "ignore", shell: false });
    const child = Object.assign(new EventEmitter(), {
      unref: () => {
        unref++;
      },
    });
    queueMicrotask(() => child.emit("spawn"));
    return child;
  };
  await api.connectSSH(
    settings,
    selection,
    async (_file, _args, opts) => {
      assert.deepEqual(JSON.parse(opts.env!.WEZMACS_RAYCAST_REQUEST!), {
        op: "ssh-plan",
        selection,
      });
      return {
        stdout: "WEZMACS_RAYCAST_OK",
        stderr:
          'WEZMACS_RAYCAST_RESULT {"ok":true,"data":{"argv":["/verified/wezterm","ssh","--","node:22"]}}',
      };
    },
    spawn,
  );
  assert.equal(launched, 1);
  assert.equal(unref, 1);
  await assert.rejects(
    api.connectSSH(
      settings,
      selection,
      async () => {
        throw Object.assign(new Error("exit1"), {
          stderr:
            'WEZMACS_RAYCAST_RESULT {"ok":false,"error":"Tailnet changed; refresh hosts"}',
        });
      },
      spawn,
    ),
    /Tailnet changed/,
  );
  assert.equal(launched, 1);
  await assert.rejects(
    api.connectSSH(
      settings,
      { input: "node" },
      async () => ({
        stdout: "WEZMACS_RAYCAST_OK",
        stderr:
          'WEZMACS_RAYCAST_RESULT {"ok":true,"data":{"argv":["/bin/sh","-c","bad"]}}',
      }),
      spawn,
    ),
    /plan/i,
  );
  assert.equal(launched, 1);
});

test("raw pane inventory preserves rows, queries freshly and leaves transport failures intact", async () => {
  const api = await load();
  assert.equal(typeof api.rawPaneInventory, "function");
  const settings = { repo: "/repo", executable: "/verified/wezterm" };
  const rows = [
    null,
    false,
    7,
    "opaque",
    [],
    {},
    { workspace: "opaque", cwd: "file:///tmp" },
  ];
  let calls = 0;
  const run: import("../src/backend").Run = async (file, args, options) => {
    calls++;
    assert.equal(file, settings.executable);
    assert.deepEqual(args, [
      "cli",
      "--no-auto-start",
      "list",
      "--format",
      "json",
    ]);
    assert.deepEqual(options, { timeout: 2500, shell: false });
    return { stdout: JSON.stringify(rows), stderr: "" };
  };
  for (let i = 0; i < 2; i++)
    assert.deepEqual(await api.rawPaneInventory(settings, run), rows);
  assert.equal(calls, 2, "Inventory must not be cached");
  for (const failure of [
    new Error("failed to connect to GUI"),
    Object.assign(new Error("failed to connect"), { code: "ENOENT" }),
    Object.assign(new Error("failed to connect"), { killed: true }),
    new SyntaxError("transport failure"),
  ]) {
    await assert.rejects(
      api.rawPaneInventory(settings, async () => {
        throw failure;
      }),
      (error) => error === failure,
    );
  }
  for (const stdout of ["not json", "null", "{}", "1", '"failed to connect"']) {
    await assert.rejects(
      api.rawPaneInventory(settings, async () => ({ stdout, stderr: "" })),
      /Invalid WezTerm workspace inventory/,
    );
  }
});

test("inventory preserves discovery error policies and ignores malformed raw rows", async () => {
  const api = await load();
  const settings = { repo: "/repo", executable: "/wezterm" };
  assert.deepEqual(
    await api.liveWorkspaces(settings, async () => ({
      stdout: JSON.stringify([
        null,
        false,
        7,
        "opaque",
        [],
        {},
        { workspace: 42 },
        { workspace: " named " },
        { workspace: "named" },
        { workspace: " named " },
      ]),
      stderr: "",
    })),
    [" named ", "named"],
  );
  for (const failure of [
    new Error("unable to connect to GUI"),
    Object.assign(new Error("exit 1"), { stderr: "GUI is not running" }),
  ])
    assert.deepEqual(
      await api.liveWorkspaces(settings, async () => {
        throw failure;
      }),
      [],
    );
  for (const failure of [
    Object.assign(new Error("failed to connect"), { code: "ENOENT" }),
    Object.assign(new Error("failed to connect"), { killed: true }),
    new Error("permission denied"),
    new SyntaxError("transport failure"),
  ])
    await assert.rejects(
      api.liveWorkspaces(settings, async () => {
        throw failure;
      }),
      {
        message:
          "Could not read WezTerm workspace inventory. Check the executable path or retry if the CLI timed out.",
      },
    );
  for (const [stdout, message] of [
    [
      "not json",
      "Invalid WezTerm workspace inventory. Refresh or update WezTerm.",
    ],
    [
      "failed to connect",
      "Invalid WezTerm workspace inventory. Refresh or update WezTerm.",
    ],
    ["null", "Invalid WezTerm workspace inventory."],
    ["{}", "Invalid WezTerm workspace inventory."],
  ])
    await assert.rejects(
      api.liveWorkspaces(settings, async () => ({ stdout, stderr: "" })),
      { message },
    );
});

test("inventory does not disguise missing executables, timeouts or malformed output as a cold GUI", async () => {
  const api = await load();
  const settings = { repo: "/repo", executable: "/wezterm" };
  await assert.rejects(
    api.liveWorkspaces(settings, async () => {
      throw Object.assign(new Error("missing"), { code: "ENOENT" });
    }),
    /inventory|executable/i,
  );
  await assert.rejects(
    api.liveWorkspaces(settings, async () => {
      throw Object.assign(new Error("timeout"), { killed: true });
    }),
    /inventory|timed out/i,
  );
  await assert.rejects(
    api.liveWorkspaces(settings, async () => ({
      stdout: "not json",
      stderr: "",
    })),
    /inventory/i,
  );
});

test("runProcess hard timeout rejects a SIGTERM-resistant child within a bound", async () => {
  const api = await load();
  const started = performance.now();
  await assert.rejects(
    api.runProcess(
      "/usr/bin/perl",
      [
        "-e",
        '$SIG{TERM} = sub {}; $SIG{ALRM} = sub { exit 0 }; $| = 1; print "SIGTERM_HANDLER_READY"; alarm 15; while (1) { sleep 60 }',
      ],
      { timeout: 5000, killSignal: "SIGTERM" },
    ),
    (error: unknown) => {
      const failure = error as Error & {
        signal?: string;
        killed?: boolean;
        stdout?: string;
      };
      assert.match(failure.stdout ?? "", /SIGTERM_HANDLER_READY/);
      assert.equal(failure.signal, "SIGKILL");
      assert.equal(failure.killed, true);
      return true;
    },
  );
  assert.ok(
    performance.now() - started < 12000,
    "hard timeout must settle before the child's fallback exit",
  );
});

const load = async () => {
  const module = await import("../src/backend").catch(() => null);
  assert.ok(module, "Backend must exist and load");
  return module;
};

test("settings expand tilde and resolve only validated executable paths", async () => {
  const api = await load();
  const home = await mkdtemp(join(tmpdir(), "wezterm-test-"));
  try {
    await mkdir(join(home, "repo/scripts"), { recursive: true });
    await writeFile(join(home, "repo/scripts/raycast.lua"), "-- fixture");
    await writeFile(join(home, "wezterm"), "fixture", { mode: 0o700 });
    const settings = await api.resolveSettings(
      { repoPath: "~/repo", weztermPath: "~/wezterm" },
      home,
    );
    assert.deepEqual(settings, {
      repo: join(home, "repo"),
      executable: join(home, "wezterm"),
    });
    await assert.rejects(
      api.resolveSettings({ repoPath: "relative" }, home),
      /absolute|~\//,
    );
    await chmod(join(home, "wezterm"), 0o600);
    await assert.rejects(
      api.resolveSettings(
        { repoPath: "~/repo", weztermPath: "~/wezterm" },
        home,
      ),
      /executable/i,
    );
    await assert.rejects(
      api.resolveSettings({ repoPath: "~/missing" }, home),
      /repository|Repository/,
    );
  } finally {
    await rm(home, { recursive: true, force: true });
  }
});
