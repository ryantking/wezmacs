import { access, realpath, stat } from "node:fs/promises";
import { homedir, hostname } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import {
  expandPath,
  rawPaneInventory,
  runProcess,
  type Run,
  type Settings,
} from "./backend";
import { constants } from "node:fs";

export async function openWorkspace(
  selection: WorkspaceSelection,
  deps: { settings: Settings; home?: string; run?: Run },
): Promise<void> {
  validName(selection.workspace);
  let app: string;
  try {
    const executable = await realpath(deps.settings.executable);
    app = dirname(dirname(dirname(executable)));
    if (
      !app.endsWith(".app") ||
      executable !== join(app, "Contents/MacOS/wezterm") ||
      !(await stat(app)).isDirectory() ||
      !(await stat(executable)).isFile() ||
      !(await stat(join(app, "Contents/Info.plist"))).isFile() ||
      !(await stat(join(app, "Contents/MacOS/wezterm-gui"))).isFile()
    )
      throw new Error("Invalid app bundle");
    await access(executable, constants.X_OK);
    await access(join(app, "Contents/MacOS/wezterm-gui"), constants.X_OK);
  } catch {
    throw new Error(
      "Set the WezTerm Executable preference to a valid WezTerm.app/Contents/MacOS/wezterm executable (or a symlink to it). A standalone CLI cannot open an independent app window.",
    );
  }
  const cwd = await workspaceDirectory(
    selection,
    deps.settings,
    deps.run ?? runProcess,
    deps.home,
  );
  try {
    await (deps.run ?? runProcess)(
      "/usr/bin/open",
      [
        "-n",
        "-a",
        app,
        "--env",
        "WEZMACS_RAYCAST_NEW_WINDOW=1",
        "--args",
        "start",
        "--always-new-process",
        "--no-auto-connect",
        "--domain",
        "local",
        "--workspace",
        selection.workspace,
        "--cwd",
        cwd,
      ],
      { timeout: 5000, shell: false },
    );
  } catch {
    throw new Error(
      "Could not open a new WezTerm window. Check the WezTerm Executable preference and macOS app permissions, then retry.",
    );
  }
}

async function workspaceDirectory(
  selection: WorkspaceSelection,
  settings: Settings,
  run: Run,
  home = homedir(),
): Promise<string> {
  const candidates: string[] = [];
  if (selection.cwd !== undefined || /^(\/|~\/|~$)/.test(selection.workspace)) {
    candidates.push(expandPath(selection.cwd ?? selection.workspace, home));
  } else {
    try {
      const rows = await rawPaneInventory(settings, run);
      for (const row of rows) {
        if (
          !row ||
          typeof row !== "object" ||
          !("workspace" in row) ||
          row.workspace !== selection.workspace ||
          !("cwd" in row) ||
          typeof row.cwd !== "string"
        )
          continue;
        try {
          const url = new URL(row.cwd);
          if (
            url.protocol !== "file:" ||
            url.search ||
            url.hash ||
            !["", "localhost", hostname().toLowerCase()].includes(
              url.hostname.toLowerCase(),
            )
          )
            continue;
          url.hostname = "";
          candidates.push(expandPath(fileURLToPath(url), home));
        } catch {
          /* Ignore malformed or nonlocal pane directories. */
        }
      }
    } catch {
      /* No usable live inventory: fail closed below. */
    }
  }
  for (const path of candidates) {
    try {
      if ((await stat(path)).isDirectory()) return path;
    } catch {
      /* Try another local pane. */
    }
  }
  throw new Error(
    "No existing local directory is available for this workspace. Choose an existing absolute or ~/ folder path; remote pane directories are never used. Refresh if workspace inventory is unavailable.",
  );
}

export interface WorkspaceSelection {
  workspace: string;
  cwd?: string;
}
function validName(value: string): void {
  if (
    !value ||
    Buffer.byteLength(value) > 4096 ||
    /[\x00-\x1f\x7f]/.test(value)
  )
    throw new Error(
      "Workspace names and paths must be nonempty, at most 4096 bytes, and contain no control characters.",
    );
}
export async function workspaceSelection(
  input: string,
  live: string[],
  home = homedir(),
): Promise<WorkspaceSelection> {
  validName(input);
  const exact = live.find((name) => name === input);
  if (exact) return { workspace: exact };
  const cwd = expandPath(input, home);
  const existing = live.find((name) => {
    try {
      return expandPath(name, home) === cwd;
    } catch {
      return false;
    }
  });
  if (existing) return { workspace: existing };
  try {
    if (!(await stat(cwd)).isDirectory()) throw new Error();
  } catch {
    throw new Error(
      "Folder does not exist or is not a directory. Choose an existing folder; no folders are created.",
    );
  }
  const workspace =
    cwd === home
      ? "~"
      : cwd.startsWith(home + "/")
        ? "~" + cwd.slice(home.length)
        : cwd;
  return { workspace, cwd };
}
