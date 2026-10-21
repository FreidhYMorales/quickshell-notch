// Pure parsing of matugen's colors.json into the three colours the notch uses.
// Returns null on any problem so the caller falls back to its defined palette.

const HEX = /^#[0-9a-fA-F]{6}$/;

// palette field -> matugen colour name
const FIELDS = {
  primary: "primary",
  onSurface: "on_surface",
  muted: "on_surface_variant",
};

/** parsePalette(jsonText) -> { primary, onSurface, muted } | null */
export function parsePalette(jsonText) {
  if (typeof jsonText !== "string") return null;
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (_error) {
    return null;
  }
  const colors = data?.colors;
  if (typeof colors !== "object" || colors === null) return null;
  const palette = {};
  for (const [field, name] of Object.entries(FIELDS)) {
    const hex = colors[name]?.hex;
    if (typeof hex !== "string" || !HEX.test(hex)) return null;
    palette[field] = hex.toLowerCase();
  }
  return palette;
}
