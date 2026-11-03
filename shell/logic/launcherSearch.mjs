// Pure app ranking for the launcher. No Qt imports.

const byName = (a, b) =>
  a.name.toLowerCase().localeCompare(b.name.toLowerCase());

export function rankApps(apps, _query) {
  return apps.slice().sort(byName);
}
