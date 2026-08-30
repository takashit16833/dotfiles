import { Action, ActionPanel, Icon, List } from "@raycast/api";
import { execFile } from "node:child_process";
import { useEffect, useState } from "react";

type Repository = {
  name: string;
  fullName: string;
  url: string;
};

function run(file: string, args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    execFile(file, args, { encoding: "utf8", maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(stderr.trim() || error.message));
        return;
      }

      resolve(stdout);
    });
  });
}

async function findGhPath(): Promise<string> {
  const output = await run("/bin/zsh", ["-lc", "command -v gh"]);
  const ghPath = output.trim();

  if (!ghPath.startsWith("/")) {
    throw new Error("gh command was not found. Install GitHub CLI and run gh auth login first.");
  }

  return ghPath;
}

async function fetchRepositories(): Promise<Repository[]> {
  const ghPath = await findGhPath();
  const output = await run(ghPath, [
    "api",
    "user/repos",
    "--paginate",
    "--jq",
    ".[] | [.name, .full_name, .html_url] | @tsv",
  ]);

  return output
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [name, fullName, url] = line.split("\t");
      return { name, fullName, url };
    });
}

export default function Command() {
  const [repositories, setRepositories] = useState<Repository[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string>();

  useEffect(() => {
    void fetchRepositories()
      .then(setRepositories)
      .catch((cause: unknown) => {
        setError(cause instanceof Error ? cause.message : String(cause));
      })
      .finally(() => setIsLoading(false));
  }, []);

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search GitHub repositories...">
      {error ? (
        <List.EmptyView icon={Icon.Warning} title="Could not load repositories" description={error} />
      ) : repositories.length === 0 && !isLoading ? (
        <List.EmptyView title="No repositories found" />
      ) : (
        repositories.map((repository) => (
          <List.Item
            key={repository.fullName}
            title={repository.name}
            subtitle={repository.fullName}
            keywords={[repository.fullName]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser title="Open Repository" url={repository.url} />
              </ActionPanel>
            }
          />
        ))
      )}
    </List>
  );
}
