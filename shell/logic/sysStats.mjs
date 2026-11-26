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

// Count online logical CPUs from the per-CPU lines in /proc/stat.
export function parseLogicalCpuCount(text) {
  const count =
    String(text || "").split(/\r?\n/).filter((line) =>
      /^cpu\d+\s+\d+(?:\s+\d+)*$/.test(line.trim())
    ).length;
  return count || null;
}

// The first three fields in /proc/loadavg are the 1, 5, and 15-minute averages.
export function parseLoadAverage(text) {
  const match = /^(\S+)\s+(\S+)\s+(\S+)/.exec(String(text || "").trim());
  if (!match) return null;
  const values = match.slice(1).map(Number);
  if (values.some((value) => !Number.isFinite(value) || value < 0)) return null;
  return { one: values[0], five: values[1], fifteen: values[2] };
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

// Memory and swap sizes from /proc/meminfo, in KiB. Swap is optional.
export function parseMemoryDetails(text) {
  const source = String(text || "");
  const total = kbField(source, "MemTotal");
  const available = kbField(source, "MemAvailable");
  if (total === null || available === null || total <= 0 || available > total) {
    return null;
  }
  const swapTotal = kbField(source, "SwapTotal");
  const swapFree = kbField(source, "SwapFree");
  const swapUsable = swapTotal !== null && swapFree !== null &&
    swapFree <= swapTotal;
  return {
    usedKiB: total - available,
    totalKiB: total,
    availableKiB: available,
    swapUsedKiB: swapUsable ? swapTotal - swapFree : null,
    swapTotalKiB: swapUsable ? swapTotal : null,
  };
}

// GNU df output requested with --output=size,used,avail,pcent, in bytes.
export function parseRootFilesystem(text) {
  const lines = String(text || "").trim().split(/\r?\n/);
  const row = lines[lines.length - 1] || "";
  const match = /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s*$/.exec(row);
  if (!match) return null;

  const totalBytes = Number(match[1]);
  const usedBytes = Number(match[2]);
  const availableBytes = Number(match[3]);
  const usedPercent = Number(match[4]);
  if (
    totalBytes <= 0 || usedBytes > totalBytes || availableBytes > totalBytes ||
    usedPercent > 100
  ) {
    return null;
  }
  return { totalBytes, usedBytes, availableBytes, usedPercent };
}
