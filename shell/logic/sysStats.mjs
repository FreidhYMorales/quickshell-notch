// Pure parsers for /proc/stat and /proc/meminfo. Malformed input gives null.

const CPU_FIELDS = 8; // user nice system idle iowait irq softirq steal

// Aggregate "cpu" line -> { idle, total } in jiffies (idle includes iowait).
export function parseCpu(text) {
  const match = /^cpu\s+(.+)$/m.exec(String(text || ""));
  if (!match) return null;
  const parts = match[1].trim().split(/\s+/).slice(0, CPU_FIELDS).map(Number);
  if (parts.length < CPU_FIELDS || parts.some((n) => !Number.isFinite(n))) {
    return null;
  }
  const total = parts.reduce((sum, n) => sum + n, 0);
  return { idle: parts[3] + parts[4], total };
}

// Busy share (0-100) between two samples, or null without a usable delta.
export function cpuPercent(prev, next) {
  if (!prev || !next) return null;
  const total = next.total - prev.total;
  const idle = next.idle - prev.idle;
  if (total <= 0 || idle < 0 || idle > total) return null;
  return Math.round((1 - idle / total) * 100);
}

function kbField(text, name) {
  const match = new RegExp("^" + name + ":\\s+(\\d+)", "m").exec(text);
  return match ? Number(match[1]) : null;
}

// Used memory (0-100) from MemTotal and MemAvailable, or null.
export function parseRam(text) {
  const source = String(text || "");
  const total = kbField(source, "MemTotal");
  const available = kbField(source, "MemAvailable");
  if (total === null || available === null) return null;
  if (total <= 0 || available > total) return null;
  return Math.round((1 - available / total) * 100);
}
