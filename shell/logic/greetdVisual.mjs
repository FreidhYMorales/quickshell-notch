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
