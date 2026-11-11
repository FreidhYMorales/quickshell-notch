// Read only the greeter's visual tokens; no authentication configuration.
export function previewTheme(base, override) {
  const values = {};
  for (const text of [base, override]) {
    let section = "";
    for (const line of String(text || "").split(/\r?\n/)) {
      const entry = line.trim();
      if (!entry || entry[0] === "#" || entry[0] === ";") continue;
      if (entry[0] === "[" && entry[entry.length - 1] === "]") {
        section = entry.slice(1, -1);
        continue;
      }
      const at = entry.indexOf("=");
      if (section === "General" && at > 0) {
        values[entry.slice(0, at).trim()] = entry.slice(at + 1).trim();
      }
    }
  }
  function width(value, fallback) {
    const parsed = Number(value);
    return isFinite(parsed) && parsed > 0 ? Math.max(80, parsed) : fallback;
  }
  function colour(value, fallback) {
    return /^#(?:[a-f0-9]{6}|[a-f0-9]{8})$/i.test(value || "")
      ? value
      : fallback;
  }
  const normal = width(values.normalNotchWidth, 300);
  const charging = Math.max(normal, width(values.chargingNotchWidth, 420));
  const low = Math.max(normal, width(values.lowBatteryNotchWidth, 420));
  return {
    notchWidth: values.notchMode === "charging"
      ? charging
      : values.notchMode === "low"
      ? low
      : normal,
    accent: colour(values.accent, "#c6c6c6"),
    foreground: colour(values.foreground, "#e4e4e4"),
  };
}

export function visualSettings(themeText, wallpaperText, baseThemeText) {
  const theme = previewTheme(baseThemeText || "", themeText);
  const path = String(wallpaperText || "").split(/\r?\n/)[0].trim();
  const background = path[0] === "/"
    ? "file://" +
      path.split("/").map((part, index) =>
        index === 0 ? "" : encodeURIComponent(part)
      ).join("/")
    : "";
  return {
    background: background,
    accent: theme.accent,
    foreground: theme.foreground,
    notchWidth: theme.notchWidth,
  };
}

// The manifest is one atomic snapshot; the image name is content-addressed.
export function manifestSettings(text, directory) {
  let value;
  try {
    value = JSON.parse(text);
  } catch (_error) {
    return null;
  }
  if (
    !value || value.version !== 1 || typeof directory !== "string" ||
    directory[0] !== "/" || typeof value.background !== "string" ||
    !/^background-[a-f0-9]{64}\.(png|jpg|jpeg|webp|gif|mp4|mkv|webm|mov|avi|m4v)$/
      .test(value.background) ||
    !/^#[a-f0-9]{6}$/i.test(value.accent || "") ||
    !/^#[a-f0-9]{6}$/i.test(value.foreground || "")
  ) return null;
  const path = directory.replace(/\/+$/, "") + "/" + value.background;
  // The shell publishes its live idle width; a manifest from an older shell
  // has none, so keep the former preset.
  const rawWidth = value.notchWidth;
  const width = Number(rawWidth);
  return {
    background: "file://" +
      path.split("/").map((part, index) =>
        index === 0 ? "" : encodeURIComponent(part)
      ).join("/"),
    accent: value.accent,
    foreground: value.foreground,
    notchWidth: typeof rawWidth === "number" && isFinite(width) &&
        width % 1 === 0 && width >= 80 && width <= 4096
      ? width
      : 300,
  };
}
