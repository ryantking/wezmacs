import {
  Action,
  ActionPanel,
  Icon,
  List,
  getPreferenceValues,
  type LaunchProps,
} from "@raycast/api";
import { useState } from "react";
import {
  connectSSH,
  discoverHosts,
  resolveSettings,
  type HostRow,
  type Preferences,
} from "./backend";
import {
  SourceStatus,
  UtilityActions,
  useAcceptance,
  useDiscovery,
} from "./ui";

const sections = [
  { source: "alias", title: "SSH Config", icon: Icon.Key },
  { source: "tailscale", title: "Tailscale", icon: Icon.Network },
  { source: "known-host", title: "Known Hosts", icon: Icon.Desktop },
];

export default function SSHToHost(
  props: LaunchProps<{ arguments: { target?: string } }>,
) {
  // A deeplink/root argument never starts a connection.
  const [search, setSearch] = useState(props.arguments.target ?? "");
  const source = useDiscovery(discoverHosts);
  const { accept, pending } = useAcceptance();
  const typed = search.trim();

  function actions(
    selection: HostRow | { input: string },
    title: string,
    manual = false,
  ) {
    return (
      <ActionPanel>
        {!pending && (manual || !source.loading) && (
          <Action
            title={title}
            icon={Icon.Terminal}
            onAction={() =>
              accept("Starting WezTerm SSH…", async () => {
                const settings =
                  source.settings ??
                  (await resolveSettings(getPreferenceValues<Preferences>()));
                // Lua validates input and rechecks selected tailnet identity at acceptance.
                await connectSSH(settings, selection);
              })
            }
          />
        )}
        <UtilityActions refresh={source.refresh} />
        {"target" in selection && (
          <Action.CopyToClipboard
            title="Copy SSH Target"
            content={selection.target}
          />
        )}
      </ActionPanel>
    );
  }

  return (
    <List
      navigationTitle="SSH to Host"
      searchBarPlaceholder="Find a host, or type [user@]host[:port]…"
      searchText={search}
      onSearchTextChange={setSearch}
      filtering={true}
      isLoading={source.loading || pending}
    >
      {sections.map((section) => (
        <List.Section
          key={section.source}
          title={section.title}
          subtitle={
            section.source === "tailscale"
              ? source.data?.meta.tailnet
              : undefined
          }
        >
          {source.data?.choices
            .filter(
              (choice) =>
                source.data?.meta.targets[choice.id].source === section.source,
            )
            .map((choice) => {
              const row = source.data!.meta.targets[choice.id];
              return (
                <List.Item
                  key={choice.id}
                  id={choice.id}
                  title={row.target}
                  subtitle={
                    choice.label === row.target ? undefined : choice.label
                  }
                  icon={section.icon}
                  keywords={[choice.label, row.target]}
                  actions={actions(row, "Connect in WezTerm")}
                />
              );
            })}
        </List.Section>
      ))}
      {typed && (
        <List.Section title="Typed Target">
          <List.Item
            id="typed-host"
            title="Connect to Typed Target"
            subtitle={typed}
            icon={Icon.Terminal}
            keywords={[typed]}
            accessories={[
              {
                text: "Explicit connection",
                tooltip:
                  "SSH alias or [user@]host[:port]. No passwords, options or remote commands. Use a configured alias for IPv6.",
              },
            ]}
            actions={actions(
              { input: search },
              "Connect to Typed Target",
              true,
            )}
          />
        </List.Section>
      )}
      <SourceStatus
        error={source.error}
        status={
          source.loading
            ? "Reading SSH sources…"
            : (source.data?.meta.status ?? "No sources available")
        }
        refresh={source.refresh}
      />
      <List.EmptyView
        title="No matching hosts"
        description="Type an SSH alias or [user@]host[:port], then explicitly connect. Use an alias for IPv6. ⌘R refreshes sources."
        icon={Icon.Network}
        actions={
          <ActionPanel>
            <UtilityActions refresh={source.refresh} />
          </ActionPanel>
        }
      />
    </List>
  );
}
