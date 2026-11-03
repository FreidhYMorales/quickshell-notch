// Pure app ranking for the launcher. No Qt imports.

const byName = (a, b) =>
  a.name.toLowerCase().localeCompare(b.name.toLowerCase());

// True when every character of `query` appears in `text`, in order.
const inOrder = (text, query) => {
  let at = 0;
  for (let i = 0; i < text.length && at < query.length; i++) {
    if (text[i] === query[at]) at++;
  }
  return at === query.length;
};

// 0 = name prefix, 1 = word start, 2 = any in-order match, -1 = no match.
const tier = (name, query) => {
  const text = name.toLowerCase();
  if (text.startsWith(query)) return 0;
  const words = text.split(/\s+/);
  for (let i = 1; i < words.length; i++) {
    if (words[i].startsWith(query)) return 1;
  }
  return inOrder(text, query) ? 2 : -1;
};

export function rankApps(apps, query) {
  const q = query.toLowerCase();
  const ranked = [];
  for (const app of apps) {
    const t = tier(app.name, q);
    if (t >= 0) ranked.push({ app, t });
  }
  ranked.sort((a, b) => a.t - b.t || byName(a.app, b.app));
  return ranked.map((r) => r.app);
}
