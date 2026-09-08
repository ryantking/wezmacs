import test from "node:test";
import assert from "node:assert/strict";
import { build } from "esbuild";
import { runInNewContext } from "node:vm";
import { resolve } from "node:path";

interface Element {
  type: string;
  props: Record<string, any>;
}
function elements(value: unknown): Element[] {
  if (!value || typeof value !== "object") return [];
  if (Array.isArray(value)) return Array.from(value).flatMap(elements);
  const node = value as Element;
  return [
    node,
    ...elements(node.props?.children),
    ...elements(node.props?.actions),
  ];
}

async function loadCommand<T = (props: object) => Element>(
  command: string,
  stubs: Record<string, string>,
  globals: Record<string, unknown>,
  exportName = "default",
) {
  const output = await build({
    entryPoints: [resolve("src", command + ".tsx")],
    bundle: true,
    write: false,
    format: "cjs",
    jsx: "automatic",
    plugins: [
      {
        name: "narrow-ui-seams",
        setup(builder) {
          builder.onResolve({ filter: /.*/ }, (args) =>
            args.path in stubs
              ? { path: args.path, namespace: "fixture" }
              : undefined,
          );
          builder.onLoad({ filter: /.*/, namespace: "fixture" }, (args) => ({
            contents: stubs[args.path],
            loader: "js",
          }));
        },
      },
    ],
  });
  const module = { exports: {} as Record<string, T> };
  runInNewContext(output.outputFiles[0].text, {
    module,
    exports: module.exports,
    ...globals,
  });
  return module.exports[exportName];
}

interface Acceptance {
  pending: boolean;
  accept(title: string, action: () => Promise<void>): Promise<void>;
}

async function loadAcceptance(showToast: (options: object) => Promise<object>) {
  const events: string[] = [];
  const render = await loadCommand<() => Acceptance>(
    "ui",
    {
      "@raycast/api": `export const Action={};export const ActionPanel={};export const Icon={};export const List={};export const Toast={Style:{Animated:"animated",Failure:"failure"}};export const showToast=globalThis.showToast;export const closeMainWindow=async()=>{globalThis.events.push("close")};export const getPreferenceValues=()=>({});export const openExtensionPreferences=()=>{};`,
      react: `let ref;let state;export const useRef=(initial)=>ref??={current:initial};export const useState=(initial)=>[state??=initial,(value)=>{state=value}];export const useCallback=(callback)=>callback;export const useEffect=()=>{};`,
      "react/jsx-runtime": `export const jsx=(type,props)=>({type,props});export const jsxs=jsx;`,
      "./backend": `export const resolveSettings=async()=>({});`,
    },
    { showToast, events, Error },
    "useAcceptance",
  );
  return { render, events };
}

test("acceptance releases pending and lock after initial toast rejection, preserving failure for retry", async () => {
  const failure = new Error("Toast unavailable");
  let attempts = 0;
  let actions = 0;
  let hides = 0;
  const { render, events } = await loadAcceptance(async () => {
    if (++attempts === 1) throw failure;
    return {
      hide: async () => {
        hides++;
      },
    };
  });
  const action = async () => {
    actions++;
  };
  assert.equal(render().pending, false);
  const rejected = render().accept("Open", action);
  assert.equal(render().pending, true);
  await assert.rejects(rejected, (error) => error === failure);
  assert.equal(actions, 0, "Toast failure must prevent launching");
  assert.deepEqual([...events], []);
  assert.equal(hides, 0);
  assert.equal(render().pending, false, "Toast failure must release pending");
  await render().accept("Retry", action);
  assert.equal(attempts, 2);
  assert.equal(actions, 1, "Retry must acquire the released lock");
  assert.equal(hides, 1);
  assert.deepEqual(events, ["close"]);
  assert.equal(render().pending, false);
});

test("acceptance displays action failure on the existing toast and permits retry", async () => {
  let hides = 0;
  let attempts = 0;
  const toast = {
    style: "animated",
    title: "Open",
    message: "",
    hide: async () => {
      hides++;
    },
  };
  const { render, events } = await loadAcceptance(async () => {
    attempts++;
    return toast;
  });
  await render().accept("Open", async () => {
    throw new Error("Launch failed");
  });
  assert.equal(toast.style, "failure");
  assert.equal(toast.title, "WezTerm could not complete the request");
  assert.equal(toast.message, "Launch failed");
  assert.equal(attempts, 1, "Failure updates the existing toast");
  assert.equal(hides, 0);
  assert.deepEqual([...events], []);
  assert.equal(render().pending, false);
  await render().accept("Retry", async () => {
    events.push("action");
  });
  assert.equal(attempts, 2);
  assert.equal(hides, 1);
  assert.deepEqual(events, ["action", "close"]);
  assert.equal(render().pending, false);
});

test("acceptance suppresses duplicates while toast and action are pending, then succeeds in order", async () => {
  let releaseToast!: (toast: object) => void;
  const toastReady = new Promise<object>((resolve) => {
    releaseToast = resolve;
  });
  let releaseAction!: () => void;
  const actionReady = new Promise<void>((resolve) => {
    releaseAction = resolve;
  });
  let markActionStarted!: () => void;
  const actionStarted = new Promise<void>((resolve) => {
    markActionStarted = resolve;
  });
  let attempts = 0;
  const { render, events } = await loadAcceptance((options) => {
    assert.equal((options as { style: string }).style, "animated");
    assert.equal((options as { title: string }).title, "Open");
    attempts++;
    return toastReady;
  });
  const duplicate = async () => {
    assert.fail("Duplicate must not launch");
  };
  const accepted = render().accept("Open", async () => {
    events.push("action");
    markActionStarted();
    await actionReady;
  });
  assert.equal(render().pending, true);
  await render().accept("Duplicate toast", duplicate);
  assert.equal(attempts, 1);
  assert.deepEqual([...events], []);
  releaseToast({
    hide: async () => {
      events.push("hide");
    },
  });
  await actionStarted;
  assert.deepEqual(events, ["action"]);
  assert.equal(render().pending, true);
  await render().accept("Duplicate action", duplicate);
  assert.equal(attempts, 1);
  assert.deepEqual(events, ["action"]);
  releaseAction();
  await accepted;
  assert.deepEqual(events, ["action", "hide", "close"]);
  assert.equal(render().pending, false);
});

// Single-component hook seam: retain search and memo dependencies across renders.
const workspaceStubs = {
  "@raycast/api": `export const List=Object.assign("List",{Section:"Section",Item:"Item",EmptyView:"EmptyView"});export const Action=Object.assign("Action",{CopyToClipboard:"Copy"});export const ActionPanel="ActionPanel";export const Icon=new Proxy({}, {get:(_,key)=>key});export const getPreferenceValues=()=>({});`,
  react: `let search;let dependencies;let memo;export const useState=(initial)=>[search??=initial,(value)=>{search=value}];export const useMemo=(compute,next)=>{if(!dependencies||next.some((value,i)=>!Object.is(value,dependencies[i]))){memo=compute();dependencies=next;}return memo;};`,
  "react/jsx-runtime": `export const jsx=(type,props)=>({type,props});export const jsxs=jsx;`,
  "./ui": `export const SourceStatus="SourceStatus";export const UtilityActions="UtilityActions";export const useAcceptance=()=>({pending:false,accept:(_title,action)=>action()});export const useDiscovery=()=>globalThis.source;`,
  "./backend": `export const discoverWorkspaces=()=>{};export const resolveSettings=async()=>{globalThis.events.push("resolveSettings");return globalThis.settings;};`,
  "./workspace": `export const workspaceSelection=async(input,live)=>{globalThis.inputs.push({input,live});return {workspace:input};};export const openWorkspace=async(selection,deps)=>{globalThis.launches.push({selection,settings:deps.settings});};`,
};

function sectionItems(view: Element, title: string) {
  const section = elements(view).find(
    (node) => node.type === "Section" && node.props.title === title,
  );
  assert.ok(section, `Missing section: ${title}`);
  return elements(section.props.children).filter(
    (node) => node.type === "Item",
  );
}

function primaryAction(item: Element) {
  return elements(item.props.actions).find(
    (node) => typeof node.props.onAction === "function",
  );
}

test("workspace sections preserve exact IDs, source order and launch inputs; search reuses the partition", async () => {
  const choices = [
    { id: "/folder/Z", label: "First folder" },
    { id: " named ' $(literal) 日本語 ", label: "Opaque running" },
    { id: "Main", label: "Case differs" },
    { id: "main", label: "Running main" },
    { id: "~/Workspaces/a", label: "Running path" },
    { id: "/folder/A", label: "Last folder" },
  ];
  const live = ["~/Workspaces/a", "main", choices[1].id, "main", "absent"];
  let reads = 0;
  const source = {
    loading: false,
    settings: { repo: "/repo", executable: "/wezterm" },
    refresh() {},
    data: {
      live,
      get choices() {
        reads++;
        return choices;
      },
    },
  };
  const inputs: { input: string; live: string[] }[] = [];
  const launches: { selection: { workspace: string }; settings: object }[] = [];
  const render = await loadCommand("open-workspace", workspaceStubs, {
    source,
    inputs,
    launches,
  });
  const view = render({ arguments: {} });
  const running = sectionItems(view, "Running Workspaces");
  const folders = sectionItems(view, "Folders");
  assert.deepEqual(
    running.map((node) => node.props.id),
    [choices[1], choices[3], choices[4]].map((c) => `live:${c.id}`),
  );
  assert.deepEqual(
    folders.map((node) => node.props.id),
    [choices[0], choices[2], choices[5]].map((c) => `folder:${c.id}`),
  );
  assert.deepEqual(
    running.map((node) => node.props.title),
    [choices[1].label, choices[3].label, choices[4].label],
  );
  assert.deepEqual(
    folders.map((node) => node.props.title),
    [choices[0].label, choices[2].label, choices[5].label],
  );
  assert.equal(launches.length, 0, "Rendering is read-only");
  const beforeSearch = reads;
  view.props.onSearchTextChange("a fuzzy query");
  const searched = render({ arguments: {} });
  assert.equal(searched.props.searchText, "a fuzzy query");
  assert.equal(
    reads,
    beforeSearch,
    "Search-only renders must reuse the section partition",
  );
  for (const item of [...running, ...folders]) {
    const action = primaryAction(item);
    assert.ok(action);
    await action.props.onAction();
  }
  const expected = [
    choices[1],
    choices[3],
    choices[4],
    choices[0],
    choices[2],
    choices[5],
  ].map((c) => c.id);
  assert.deepEqual(
    inputs.map((entry) => entry.input),
    expected,
  );
  assert.deepEqual(
    launches.map((entry) => entry.selection.workspace),
    expected,
  );
  for (const entry of inputs) assert.equal(entry.live, live);
  for (const entry of launches) assert.equal(entry.settings, source.settings);
  source.data = { live: ["Main"], choices };
  const refreshed = render({ arguments: {} });
  assert.deepEqual(
    sectionItems(refreshed, "Running Workspaces").map((node) => node.props.id),
    ["live:Main"],
  );
  assert.deepEqual(
    sectionItems(refreshed, "Folders").map((node) => node.props.id),
    choices.filter((c) => c.id !== "Main").map((c) => `folder:${c.id}`),
  );
});

test("workspace loading suppresses stale choice actions but keeps manual settings fallback after discovery errors", async () => {
  const source: {
    loading: boolean;
    data?: { live: string[]; choices: { id: string; label: string }[] };
    error?: string;
    refresh(): void;
  } = {
    loading: true,
    data: {
      live: ["opaque"],
      choices: [
        { id: "opaque", label: "Running" },
        { id: "/folder", label: "Folder" },
      ],
    },
    refresh() {},
  };
  const input = "~/folder space ' 日本語";
  const settings = { repo: "/repo", executable: "/fallback/wezterm" };
  const events: string[] = [];
  const inputs: { input: string; live: string[] }[] = [];
  const launches: { selection: { workspace: string }; settings: object }[] = [];
  const render = await loadCommand("open-workspace", workspaceStubs, {
    source,
    settings,
    events,
    inputs,
    launches,
  });
  const view = render({ arguments: { path: input } });
  assert.equal(view.props.isLoading, true);
  for (const title of ["Running Workspaces", "Folders"]) {
    const items = sectionItems(view, title);
    assert.equal(items.length, 1);
    assert.equal(primaryAction(items[0]), undefined);
  }
  const manual = primaryAction(sectionItems(view, "Typed Folder")[0]);
  assert.ok(manual);
  await manual.props.onAction();
  assert.deepEqual(events, ["resolveSettings"]);
  assert.equal(inputs[0].input, input);
  assert.equal(launches[0].selection.workspace, input);
  assert.equal(launches[0].settings, settings);
  source.loading = false;
  source.data = undefined;
  source.error = "Inventory unavailable";
  const failed = render({ arguments: {} });
  assert.equal(failed.props.isLoading, false);
  for (const title of ["Running Workspaces", "Folders"])
    assert.equal(sectionItems(failed, title).length, 0);
  assert.equal(
    elements(failed).find((node) => node.type === "SourceStatus")?.props.error,
    source.error,
  );
  assert.ok(elements(failed).some((node) => node.type === "EmptyView"));
  const fallback = primaryAction(sectionItems(failed, "Typed Folder")[0]);
  assert.ok(fallback);
  await fallback.props.onAction();
  assert.deepEqual(events, ["resolveSettings", "resolveSettings"]);
  assert.equal(inputs[1].input, input);
  assert.equal(inputs[1].live.length, 0);
  assert.equal(launches[1].selection.workspace, input);
  assert.equal(launches[1].settings, settings);
});

for (const [command, arg, input, title, expected] of [
  [
    "open-workspace",
    "path",
    "~/Workspaces/example",
    "Open Typed Folder in New Window",
    "workspace",
  ],
  [
    "ssh-to-host",
    "target",
    "user@alias:2222",
    "Connect to Typed Target",
    "ssh",
  ],
]) {
  test(`${command}: optional argument only initializes fuzzy picker; typed acceptance works during slow discovery`, async () => {
    const events: string[] = [];
    const stubs: Record<string, string> = {
      "@raycast/api": `export const List=Object.assign("List",{Section:"Section",Item:"Item",EmptyView:"EmptyView"});export const Action=Object.assign("Action",{CopyToClipboard:"Copy"});export const ActionPanel="ActionPanel";export const Icon=new Proxy({}, {get:(_,key)=>key});export const getPreferenceValues=()=>({});`,
      react: `export const useState=(value)=>[value,()=>{}];export const useMemo=(compute)=>compute();`,
      "react/jsx-runtime": `export const jsx=(type,props)=>({type,props});export const jsxs=jsx;`,
      "./ui": `export const SourceStatus="SourceStatus";export const UtilityActions="UtilityActions";export const useAcceptance=()=>({pending:false,accept:(_title,action)=>action()});export const useDiscovery=()=>({loading:true,settings:{repo:"/repo",executable:"/wezterm"},refresh:()=>{}});`,
      "./backend": `export const discoverWorkspaces=()=>{};export const discoverHosts=()=>{};export const resolveSettings=async()=>({});export const liveWorkspaces=async()=>{throw new Error("slow inventory must not block typed folder")};export const connectSSH=async()=>{globalThis.events.push("ssh")};`,
      "./workspace": `export const workspaceSelection=async(input)=>({workspace:input});export const openWorkspace=async(selection,deps)=>{if(deps.settings.executable!=="/wezterm")throw new Error("must use selected executable");globalThis.events.push("workspace")};`,
    };
    const render = await loadCommand(command, stubs, { events });
    const view = render({ arguments: { [arg]: input } });
    assert.equal(view.props.searchText, input);
    assert.equal(view.props.filtering, true);
    assert.deepEqual(events, [], "Root arguments and render must never launch");
    const action = elements(view).find(
      (node) =>
        node.props?.title === title &&
        typeof node.props.onAction === "function",
    );
    assert.ok(
      action,
      "Explicit typed action remains usable while discovery is loading",
    );
    await action.props.onAction();
    assert.deepEqual(events, [expected]);
  });
}
