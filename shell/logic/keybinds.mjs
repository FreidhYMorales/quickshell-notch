// Pure Hyprland bind registry mapping for the launcher keybinds view.
// No Qt imports.

// Hyprland modmask bits, in the order the cheat sheet shows them.
const MODIFIERS = [
  { mask: 4, label: "Ctrl" },
  { mask: 8, label: "Alt" },
  { mask: 1, label: "Shift" },
  { mask: 64, label: "Super" },
];

function keyLabel(bind) {
  const parts = [];
  for (const modifier of MODIFIERS) {
    if (bind.modmask & modifier.mask) parts.push(modifier.label);
  }
  parts.push(bind.key ?? "");
  return parts.join(" + ");
}

// `hyprctl binds -j` -> the cheat sheet rows. Binds without a description are
// hardware or self-evident ones and stay out, like the old bar did.
export function bindsFromJson(text) {
  const rows = [];
  let binds;
  try {
    binds = JSON.parse(text);
  } catch (_e) {
    return { available: false, rows: [] };
  }
  if (!Array.isArray(binds)) return { available: false, rows: [] };
  for (const bind of binds) {
    if (!bind?.description) continue;
    rows.push({ keys: keyLabel(bind), description: bind.description });
  }
  return { available: true, rows: rows };
}
