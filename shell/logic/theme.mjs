// Pure theme model: the matugen scheme types the launcher offers, in the
// display order the old config used.

export const MODES = [
  "scheme-tonal-spot",
  "scheme-monochrome",
  "scheme-vibrant",
  "scheme-expressive",
  "scheme-fidelity",
  "scheme-content",
  "scheme-neutral",
  "scheme-rainbow",
  "scheme-fruit-salad",
];

const HEX = /^#[0-9a-fA-F]{6}$/;

// matugen --dry-run --json hex nests each colour as { default: { color } },
// unlike the { hex } shape of the colors.json it writes for the apps.
export function parseDryPalette(jsonText) {
  if (typeof jsonText !== "string") return null;
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (_error) {
    return null;
  }
  const colors = data?.colors;
  if (typeof colors !== "object" || colors === null) return null;
  const primary = colors.primary?.default?.color;
  const onSurface = colors.on_surface?.default?.color;
  const muted = colors.on_surface_variant?.default?.color;
  if (!HEX.test(primary) || !HEX.test(onSurface) || !HEX.test(muted)) {
    return null;
  }
  return { primary, onSurface, muted };
}
