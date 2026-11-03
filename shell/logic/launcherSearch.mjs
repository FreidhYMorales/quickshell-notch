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

// Generic name and keywords only count on a prefix or word start (scattered
// in-order hits there are noise) and rank after every name match.
const FALLBACK = 3;
const fallbackMatch = (app, query) => {
  const texts = [app.genericName ?? ""].concat(app.keywords ?? []);
  for (const text of texts) {
    const t = tier(text, query);
    if (t === 0 || t === 1) return true;
  }
  return false;
};

const rank = (app, query) => {
  const t = tier(app.name, query);
  if (t >= 0) return t;
  return fallbackMatch(app, query) ? FALLBACK : -1;
};

export function rankApps(apps, query) {
  const q = query.toLowerCase();
  const ranked = [];
  for (const app of apps) {
    const t = rank(app, q);
    if (t >= 0) ranked.push({ app, t });
  }
  ranked.sort((a, b) => a.t - b.t || byName(a.app, b.app));
  return ranked.map((r) => r.app);
}
