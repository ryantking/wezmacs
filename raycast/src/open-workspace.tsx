import {
  Action,
  ActionPanel,
  Icon,
  List,
  getPreferenceValues,
  type LaunchProps,
} from "@raycast/api";
import { useMemo, useState } from "react";
import {
  discoverWorkspaces,
  resolveSettings,
  type Choice,
  type Preferences,
} from "./backend";
import { openWorkspace, workspaceSelection } from "./workspace";
import {
  SourceStatus,
  UtilityActions,
  useAcceptance,
  useDiscovery,
} from "./ui";

export default function OpenWorkspace(
  props: LaunchProps<{ arguments: { path?: string } }>,
) {
  // Root arguments initialize the picker only. Every launch is an explicit action.
  const [search, setSearch] = useState(props.arguments.path ?? "");
  const source = useDiscovery(discoverWorkspaces);
  const { accept, pending } = useAcceptance();
  const live = source.data?.live ?? [];
  const { active, folders } = useMemo(() => {
    const live = new Set(source.data?.live);
    const active: Choice[] = [];
    const folders: Choice[] = [];
    for (const choice of source.data?.choices ?? []) {
      (live.has(choice.id) ? active : folders).push(choice);
    }
    return { active, folders };
  }, [source.data]);

  function actions(input: string, title: string, manual = false) {
    return (
      <ActionPanel>
        {!pending && (manual || !source.loading) && (
          <Action
            title={title}
            icon={Icon.Terminal}
            onAction={() =>
              accept("Opening new WezTerm window…", async () => {
                const settings =
                  source.settings ??
                  (await resolveSettings(getPreferenceValues<Preferences>()));
                // Path acceptance does not wait on inventory. Opaque names are
                // resolved against fresh local pane CWDs by openWorkspace.
                const selection = await workspaceSelection(input, live);
                await openWorkspace(selection, { settings });
              })
            }
          />
        )}
        <UtilityActions refresh={source.refresh} />
      </ActionPanel>
    );
  }

  return (
    <List
      navigationTitle="Open Workspace"
      searchBarPlaceholder="Find a workspace, or type /path/to/folder…"
      searchText={search}
      onSearchTextChange={setSearch}
      filtering={true}
      isLoading={source.loading || pending}
    >
      <List.Section
        title="Running Workspaces"
        subtitle={active.length ? "Open directory in a new window" : undefined}
      >
        {active.map((choice) => (
          <List.Item
            key={choice.id}
            id={`live:${choice.id}`}
            title={choice.label}
            icon={Icon.AppWindow}
            keywords={[choice.id]}
            accessories={[{ text: "Running" }]}
            actions={actions(choice.id, "Open Workspace in New Window")}
          />
        ))}
      </List.Section>
      <List.Section title="Folders" subtitle="WezMacs · zoxide · ~/Workspaces">
        {folders.map((choice) => (
          <List.Item
            key={choice.id}
            id={`folder:${choice.id}`}
            title={choice.label}
            icon={Icon.Folder}
            keywords={[choice.id]}
            actions={actions(choice.id, "Open Folder in New Window")}
          />
        ))}
      </List.Section>
      {search.length > 0 && (
        <List.Section title="Typed Folder">
          <List.Item
            id="typed-folder"
            title="Open Typed Folder in New Window"
            subtitle={search}
            icon={Icon.Folder}
            keywords={[search]}
            accessories={[
              {
                text: "Existing folder only",
                tooltip:
                  "Use an absolute path or ~/ path. No folder is created. Explicit acceptance opens a new independent window; existing windows are unchanged.",
              },
            ]}
            actions={actions(search, "Open Typed Folder in New Window", true)}
          />
        </List.Section>
      )}
      <SourceStatus
        error={source.error}
        status={
          source.loading
            ? "Reading workspace sources…"
            : live.length
              ? "Live workspaces and local folders"
              : "No running workspaces · select a folder to start WezTerm"
        }
        refresh={source.refresh}
      />
      <List.EmptyView
        title="No matching workspaces"
        description="Type an absolute folder path or ~/ path, then choose Open Typed Folder in New Window. ⌘R refreshes sources."
        icon={Icon.Folder}
        actions={
          <ActionPanel>
            <UtilityActions refresh={source.refresh} />
          </ActionPanel>
        }
      />
    </List>
  );
}
