import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, rm, realpath } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import * as api from "../src/workspace";

const fixture = () =>
  realpath(tmpdir()).then((base) => mkdtemp(join(base, "wezmacs-workspace-")));

test("workspace API exposes selection and independent-window launch only", () => {
  assert.deepEqual(Object.keys(api).sort(), [
    "openWorkspace",
    "workspaceSelection",
  ]);
});

test("folder selection validates existing directories and preserves live workspace identity", async () => {
  const home = await fixture();
  try {
    await mkdir(join(home, "folder space"));
    assert.deepEqual(await api.workspaceSelection("~/folder space", [], home), {
      workspace: "~/folder space",
      cwd: join(home, "folder space"),
    });
    assert.deepEqual(
      await api.workspaceSelection(
        join(home, "folder space"),
        ["~/folder space"],
        home,
      ),
      { workspace: "~/folder space" },
    );
    assert.deepEqual(await api.workspaceSelection("remote", ["remote"], home), {
      workspace: "remote",
    });
    await assert.rejects(
      api.workspaceSelection("~/missing", [], home),
      /directory|folder/i,
    );
    await assert.rejects(
      api.workspaceSelection("relative", [], home),
      /absolute/i,
    );
    await assert.rejects(
      api.workspaceSelection("bad\nname", ["bad\nname"], home),
      /control/i,
    );
    await writeFile(join(home, "file"), "x");
    await assert.rejects(
      api.workspaceSelection("~/file", [], home),
      /directory|folder/i,
    );
  } finally {
    await rm(home, { recursive: true, force: true });
  }
});
