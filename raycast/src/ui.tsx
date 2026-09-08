import {
  Action,
  ActionPanel,
  Icon,
  List,
  Toast,
  closeMainWindow,
  getPreferenceValues,
  openExtensionPreferences,
  showToast,
} from "@raycast/api";
import { useCallback, useEffect, useRef, useState } from "react";
import { resolveSettings, type Preferences, type Settings } from "./backend";

export function useDiscovery<T>(discover: (settings: Settings) => Promise<T>) {
  const [data, setData] = useState<T>();
  const [settings, setSettings] = useState<Settings>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>();
  const [revision, setRevision] = useState(0);
  const refresh = useCallback(() => setRevision((value) => value + 1), []);
  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(undefined);
    setData(undefined);
    setSettings(undefined);
    void (async () => {
      try {
        const resolved = await resolveSettings(
          getPreferenceValues<Preferences>(),
        );
        if (!active) return;
        setSettings(resolved);
        const result = await discover(resolved);
        if (active) setData(result);
      } catch (failure) {
        if (active) setError(message(failure));
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, [discover, revision]);
  return { data, settings, loading, error, refresh };
}

export function message(error: unknown): string {
  return error instanceof Error
    ? error.message
    : "Unexpected error. Refresh and check extension preferences.";
}

export function useAcceptance() {
  const lock = useRef(false);
  const [pending, setPending] = useState(false);
  async function accept(title: string, action: () => Promise<void>) {
    if (lock.current) return;
    lock.current = true;
    setPending(true);
    let toast: Toast | undefined;
    try {
      toast = await showToast({ style: Toast.Style.Animated, title });
      await action();
      await toast.hide();
      await closeMainWindow();
    } catch (error) {
      if (!toast) throw error;
      toast.style = Toast.Style.Failure;
      toast.title = "WezTerm could not complete the request";
      toast.message = message(error);
    } finally {
      lock.current = false;
      setPending(false);
    }
  }
  return { accept, pending };
}

export function UtilityActions({ refresh }: { refresh: () => void }) {
  return (
    <ActionPanel.Section>
      <Action
        title="Refresh Sources"
        icon={Icon.ArrowClockwise}
        shortcut={{ modifiers: ["cmd"], key: "r" }}
        onAction={refresh}
      />
      <Action
        title="Extension Preferences"
        icon={Icon.Gear}
        shortcut={{ modifiers: ["cmd"], key: "," }}
        onAction={openExtensionPreferences}
      />
    </ActionPanel.Section>
  );
}

export function SourceStatus({
  error,
  status,
  refresh,
}: {
  error?: string;
  status: string;
  refresh: () => void;
}) {
  return (
    <List.Section title="Sources">
      <List.Item
        id="source-status"
        title={error ? "Sources unavailable" : status}
        subtitle={error ? "Open preferences or refresh" : undefined}
        icon={error ? Icon.ExclamationMark : Icon.Info}
        keywords={error ? [error] : [status]}
        accessories={
          error ? [{ text: "Needs attention", tooltip: error }] : undefined
        }
        actions={
          <ActionPanel>
            <UtilityActions refresh={refresh} />
            {error && (
              <Action.CopyToClipboard
                title="Copy Error Details"
                content={error}
              />
            )}
          </ActionPanel>
        }
      />
    </List.Section>
  );
}
