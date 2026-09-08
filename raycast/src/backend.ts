import { access, stat } from "node:fs/promises";
import { constants } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

import {
  execFile,
  spawn as spawnProcess,
  type ExecFileOptions,
  type SpawnOptions,
} from "node:child_process";
import { realpath } from "node:fs/promises";
import type { EventEmitter } from "node:events";

export type Spawn = (
  file: string,
  args: string[],
  options: SpawnOptions,
) => EventEmitter & { unref(): void };
export async function connectSSH(
  settings: Settings,
  selection: HostRow | { input: string },
  run: Run = runProcess,
  spawn: Spawn = spawnProcess,
): Promise<void> {
  const data = await bridge(settings, { op: "ssh-plan", selection }, run);
  if (
    !record(data) ||
    !Array.isArray(data.argv) ||
    data.argv.length < 3 ||
    !data.argv.every(
      (arg) => typeof arg === "string" && !/[\x00-\x1f\x7f]/.test(arg),
    ) ||
    data.argv[1] !== "ssh"
  )
    throw new Error(
      "Invalid SSH launch plan. Update WezMacs and refresh hosts.",
    );
  const argv = data.argv as string[];
  const sameExecutable =
    argv[0] === settings.executable ||
    (isAbsolute(argv[0]) &&
      (await realpath(argv[0])
        .then(async (path) => path === (await realpath(settings.executable)))
        .catch(() => false)));
  if (!sameExecutable)
    throw new Error(
      "SSH plan executable does not match the verified WezTerm path. Check preferences.",
    );
  await new Promise<void>((resolve, reject) => {
    const child = spawn(argv[0], argv.slice(1), {
      detached: true,
      stdio: "ignore",
      shell: false,
    });
    child.once("error", () =>
      reject(
        new Error(
          "Could not start WezTerm SSH. Check the executable path and try again.",
        ),
      ),
    );
    child.once("spawn", () => {
      child.unref();
      resolve();
    });
  });
}

export type Run = (
  file: string,
  args: string[],
  options: ExecFileOptions,
) => Promise<{ stdout: string; stderr: string }>;
export const runProcess: Run = (file, args, options) =>
  new Promise((resolve, reject) => {
    execFile(
      file,
      args,
      {
        ...options,
        shell: false,
        encoding: "utf8",
        maxBuffer: 1024 * 1024,
        killSignal: "SIGKILL",
      },
      (error, stdout, stderr) => {
        if (error) reject(Object.assign(error, { stdout, stderr }));
        else resolve({ stdout, stderr });
      },
    );
  });

export async function bridge(
  settings: Settings,
  request: object,
  run: Run = runProcess,
): Promise<unknown> {
  let result: { stdout: string; stderr: string };
  try {
    result = await run(
      settings.executable,
      [
        "--config-file",
        join(settings.repo, "scripts/raycast.lua"),
        "show-keys",
        "--lua",
      ],
      {
        timeout: "op" in request && request.op === "workspaces" ? 30000 : 20000,
        env: {
          ...process.env,
          WEZMACS_RAYCAST_ROOT: settings.repo,
          WEZMACS_RAYCAST_REQUEST: JSON.stringify(request),
        },
      },
    );
  } catch (error) {
    const stderr = (error as { stderr?: string }).stderr;
    const line = stderr
      ?.split(/\r?\n/)
      .find((line) => line.startsWith("WEZMACS_RAYCAST_RESULT "));
    if (line) {
      try {
        const value = JSON.parse(line.slice("WEZMACS_RAYCAST_RESULT ".length));
        if (value.ok === false && typeof value.error === "string")
          throw new Error(value.error);
      } catch (parsed) {
        if (!(parsed instanceof SyntaxError)) throw parsed;
      }
    }
    throw new Error(
      "WezTerm helper failed or timed out. Check the executable and repository preferences, then refresh.",
    );
  }
  const lines = result.stderr
    .split(/\r?\n/)
    .filter((line) => line.startsWith("WEZMACS_RAYCAST_RESULT "));
  if (lines.length !== 1)
    throw new Error(
      "Invalid helper result. Update your WezMacs checkout and refresh.",
    );
  let response;
  try {
    response = JSON.parse(lines[0].slice("WEZMACS_RAYCAST_RESULT ".length));
  } catch {
    throw new Error(
      "Invalid helper result JSON. Update your WezMacs checkout.",
    );
  }
  if (response?.ok === false)
    throw new Error(
      typeof response.error === "string"
        ? response.error
        : "WezTerm rejected the request.",
    );
  if (response?.ok !== true || !("data" in response))
    throw new Error("Invalid helper result envelope.");
  if (!result.stdout.includes("WEZMACS_RAYCAST_OK"))
    throw new Error(
      "WezTerm returned native fallback without the success sentinel. Check the helper configuration.",
    );
  return response.data;
}

export interface Choice {
  id: string;
  label: string;
}
export interface HostRow {
  target: string;
  source: string;
  identity?: string;
  peer_id?: string;
  key?: string;
  [key: string]: unknown;
}
export interface Hosts {
  choices: Choice[];
  meta: { status: string; tailnet?: string; targets: Record<string, HostRow> };
}
function record(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}
function choices(
  value: unknown,
): value is Record<string, unknown> & { choices: Choice[] } {
  return (
    record(value) &&
    Array.isArray(value.choices) &&
    value.choices.every(
      (row) =>
        record(row) &&
        typeof row.id === "string" &&
        typeof row.label === "string",
    )
  );
}
// Parse failures must remain distinct from native CLI transport failures.
class InvalidPaneInventoryError extends Error {}

export async function rawPaneInventory(
  settings: Settings,
  run: Run = runProcess,
): Promise<unknown[]> {
  const result = await run(
    settings.executable,
    ["cli", "--no-auto-start", "list", "--format", "json"],
    { timeout: 2500, shell: false },
  );
  let rows: unknown;
  try {
    rows = JSON.parse(result.stdout);
  } catch {
    throw new InvalidPaneInventoryError(
      "Invalid WezTerm workspace inventory. Refresh or update WezTerm.",
    );
  }
  if (!Array.isArray(rows))
    throw new InvalidPaneInventoryError("Invalid WezTerm workspace inventory.");
  return rows;
}

export async function liveWorkspaces(
  settings: Settings,
  run: Run = runProcess,
): Promise<string[]> {
  let rows;
  try {
    rows = await rawPaneInventory(settings, run);
  } catch (error) {
    if (error instanceof InvalidPaneInventoryError) throw error;
    const failure = error as NodeJS.ErrnoException & {
      stderr?: string;
      killed?: boolean;
    };
    if (
      failure.code !== "ENOENT" &&
      !failure.killed &&
      /failed to connect|unable to connect|could not connect|no running|gui is not running/i.test(
        failure.stderr ?? failure.message,
      )
    )
      return [];
    throw new Error(
      "Could not read WezTerm workspace inventory. Check the executable path or retry if the CLI timed out.",
    );
  }
  const workspaces: string[] = [];
  for (const row of rows) {
    if (record(row) && typeof row.workspace === "string")
      workspaces.push(row.workspace);
  }
  return [...new Set(workspaces)];
}
export async function discoverWorkspaces(
  settings: Settings,
  run: Run = runProcess,
): Promise<{ choices: Choice[]; live: string[] }> {
  const live = await liveWorkspaces(settings, run);
  const data = await bridge(
    settings,
    { op: "workspaces", workspaces: live },
    run,
  );
  if (!choices(data))
    throw new Error(
      "Invalid workspace result from helper. Update WezMacs and refresh.",
    );
  return { choices: data.choices, live };
}
export async function discoverHosts(
  settings: Settings,
  run: Run = runProcess,
): Promise<Hosts> {
  const data = await bridge(settings, { op: "hosts" }, run);
  if (
    !choices(data) ||
    !record(data) ||
    !record(data.meta) ||
    typeof data.meta.status !== "string" ||
    !record(data.meta.targets)
  )
    throw new Error(
      "Invalid host result from helper. Update WezMacs and refresh.",
    );
  for (const choice of data.choices) {
    const row = data.meta.targets[choice.id];
    if (
      !record(row) ||
      typeof row.target !== "string" ||
      typeof row.source !== "string"
    )
      throw new Error("Invalid host row in helper result. Refresh hosts.");
  }
  return data as unknown as Hosts;
}

export interface Settings {
  repo: string;
  executable: string;
}
export interface Preferences {
  repoPath?: string;
  weztermPath?: string;
}

export function expandPath(value: string, home = homedir()): string {
  const expanded =
    value === "~"
      ? home
      : value.startsWith("~/")
        ? join(home, value.slice(2))
        : value;
  if (!isAbsolute(expanded) || /[\x00-\x1f\x7f]/.test(expanded))
    throw new Error(
      "Use an absolute path or ~/ path without control characters.",
    );
  return resolve(expanded);
}

export async function resolveSettings(
  prefs: Preferences,
  home = homedir(),
): Promise<Settings> {
  const repo = expandPath(prefs.repoPath?.trim() || "~/.config/wezterm", home);
  try {
    if (
      !(await stat(repo)).isDirectory() ||
      !(await stat(join(repo, "scripts/raycast.lua"))).isFile()
    )
      throw new Error();
  } catch {
    throw new Error(
      "WezMacs repository is missing scripts/raycast.lua. Update the Repository preference to your framework checkout.",
    );
  }
  const candidates = prefs.weztermPath?.trim()
    ? [expandPath(prefs.weztermPath.trim(), home)]
    : [
        "/Applications/WezTerm.app/Contents/MacOS/wezterm",
        join(home, "Applications/WezTerm.app/Contents/MacOS/wezterm"),
        "/opt/homebrew/bin/wezterm",
        "/usr/local/bin/wezterm",
        "/usr/bin/wezterm",
      ];
  for (const executable of candidates) {
    try {
      if ((await stat(executable)).isFile()) {
        await access(executable, constants.X_OK);
        return { repo, executable };
      }
    } catch {
      /* try next known path */
    }
  }
  throw new Error(
    "WezTerm executable not found or not executable. Install WezTerm or set its absolute Executable path in preferences.",
  );
}
