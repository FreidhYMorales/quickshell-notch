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
    totalBytes <= 0 || totalBytes > 9007199254740991 ||
    usedBytes > totalBytes || availableBytes > totalBytes ||
    usedBytes + availableBytes > totalBytes || usedPercent > 100
  ) {
    return null;
  }
  return { totalBytes, usedBytes, availableBytes, usedPercent };
}

function diskStatsForDevice(text, majorMinor) {
  let result = null;
  for (const line of String(text || "").trim().split(/\r?\n/)) {
    const fields = line.trim().split(/\s+/);
    if (fields.length < 14 || `${fields[0]}:${fields[1]}` !== majorMinor) {
      continue;
    }
    if (result !== null) return null;
    const readSectors = Number(fields[5]);
    const writeSectors = Number(fields[9]);
    if (
      !Number.isSafeInteger(readSectors) || readSectors < 0 ||
      !Number.isSafeInteger(writeSectors) || writeSectors < 0
    ) return null;
    result = { device: fields[2], readSectors, writeSectors };
  }
  return result;
}

// Derive root-device byte rates from consecutive /proc/diskstats snapshots.
export function parseDiskActivity(mountInfo, previous, current, elapsedMs) {
  let majorMinor = null;
  for (const line of String(mountInfo || "").split(/\r?\n/)) {
    const fields = line.trim().split(/\s+/);
    if (fields[4] !== "/") continue;
    const separator = fields.indexOf("-");
    if (separator < 6 || separator + 3 >= fields.length) return null;
    if (majorMinor !== null || !/^\d+:\d+$/.test(fields[2] || "")) return null;
    majorMinor = fields[2];
  }
  if (majorMinor === null || !Number.isFinite(elapsedMs) || elapsedMs <= 0) {
    return null;
  }
  const before = diskStatsForDevice(previous, majorMinor);
  const after = diskStatsForDevice(current, majorMinor);
  if (
    !before || !after || before.device !== after.device ||
    after.readSectors < before.readSectors ||
    after.writeSectors < before.writeSectors
  ) return null;
  return {
    device: after.device,
    readBytesPerSecond: Math.round(
      (after.readSectors - before.readSectors) * 512000 / elapsedMs,
    ),
    writeBytesPerSecond: Math.round(
      (after.writeSectors - before.writeSectors) * 512000 / elapsedMs,
    ),
  };
}

function networkCounters(text) {
  const counters = {};
  for (const line of String(text || "").split(/\r?\n/)) {
    const separator = line.indexOf(":");
    if (separator < 0) continue;
    const name = line.slice(0, separator).trim();
    if (!name || name === "lo") continue;
    if (Object.prototype.hasOwnProperty.call(counters, name)) return null;
    const fields = line.slice(separator + 1).trim().split(/\s+/);
    const receiveBytes = Number(fields[0]);
    const transmitBytes = Number(fields[8]);
    if (
      fields.length < 16 ||
      !Number.isSafeInteger(receiveBytes) || receiveBytes < 0 ||
      !Number.isSafeInteger(transmitBytes) || transmitBytes < 0
    ) return null;
    counters[name] = { receiveBytes, transmitBytes };
  }
  return Object.keys(counters).length > 0 ? counters : null;
}

// Derive aggregate non-loopback receive/transmit byte rates from /proc/net/dev.
export function parseNetworkActivity(previous, current, elapsedMs) {
  if (!Number.isFinite(elapsedMs) || elapsedMs <= 0) return null;
  const before = networkCounters(previous);
  const after = networkCounters(current);
  if (!before || !after) return null;
  const names = Object.keys(before);
  if (names.length !== Object.keys(after).length) return null;

  let receiveBytes = 0;
  let transmitBytes = 0;
  for (const name of names) {
    if (!Object.prototype.hasOwnProperty.call(after, name)) return null;
    const previousCounters = before[name];
    const currentCounters = after[name];
    if (
      currentCounters.receiveBytes < previousCounters.receiveBytes ||
      currentCounters.transmitBytes < previousCounters.transmitBytes
    ) return null;
    receiveBytes += currentCounters.receiveBytes -
      previousCounters.receiveBytes;
    transmitBytes += currentCounters.transmitBytes -
      previousCounters.transmitBytes;
  }
  return {
    receiveBytesPerSecond: Math.round(receiveBytes * 1000 / elapsedMs),
    transmitBytesPerSecond: Math.round(transmitBytes * 1000 / elapsedMs),
  };
}
