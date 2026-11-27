import { test } from "node:test";
import assert from "node:assert/strict";
import * as SysStats from "../shell/logic/sysStats.mjs";

const { cpuPercent, parseCpu, parseRam } = SysStats;

const STAT = "cpu  100 5 50 800 40 3 2 0 0 0\ncpu0 50 2 25 400 20 1 1 0 0 0\n";
const MEMINFO = "MemTotal:       16000000 kB\nMemFree:         2000000 kB\n" +
  "MemAvailable:    4000000 kB\nBuffers:          100000 kB\n";

test("resource status distinguishes measuring, unavailable, invalid, and valid zero", () => {
  assert.equal(
    SysStats.resourceReadingStatus({
      sourceAvailable: true,
      readingValid: true,
      sampleReady: false,
    }),
    "measuring",
  );
  assert.equal(
    SysStats.resourceReadingStatus({
      sourceAvailable: false,
      readingValid: false,
      sampleReady: false,
    }),
    "unavailable",
  );
  assert.equal(
    SysStats.resourceReadingStatus({
      sourceAvailable: true,
      readingValid: false,
      sampleReady: true,
    }),
    "invalid",
  );
  assert.equal(
    SysStats.resourceReadingStatus({
      sourceAvailable: true,
      readingValid: true,
      sampleReady: true,
      value: 0,
    }),
    "available",
  );
});

test("parseCpu reads the aggregate line: idle includes iowait", () => {
  assert.deepEqual(parseCpu(STAT), { idle: 840, total: 1000 });
});

test("parseCpu handles a different sample", () => {
  assert.deepEqual(parseCpu("cpu  10 0 10 70 10 0 0 0\n"), {
    idle: 80,
    total: 100,
  });
});

test("parseCpu returns null for malformed input", () => {
  assert.equal(parseCpu(""), null);
  assert.equal(parseCpu(undefined), null);
  assert.equal(parseCpu("cpu0 1 2 3 4 5 6 7 8\n"), null);
  assert.equal(parseCpu("cpu  1 2 x 4 5 6 7 8\n"), null);
  assert.equal(parseCpu("cpu  1 2 3\n"), null);
});

test("CPU details count online processors and parse load averages", () => {
  const stat =
    "cpu 1 2 3 4 5 6 7 8\ncpu0 1 2 3 4 5 6 7 8\ncpu1 1 2 3 4 5 6 7 8\n";
  const loadavg = "0.45 0.32 0.12 1/234 1234\n";
  assert.equal(typeof SysStats.parseLogicalCpuCount, "function");
  assert.equal(SysStats.parseLogicalCpuCount(stat), 2);
  assert.deepEqual(SysStats.parseLoadAverage(loadavg), {
    one: 0.45,
    five: 0.32,
    fifteen: 0.12,
  });
  assert.equal(SysStats.parseLogicalCpuCount("cpu 1 2 3 4\n"), null);
  assert.equal(SysStats.parseLoadAverage("0.1 invalid 0.3 1/4 5\n"), null);
});

test("cpuPercent is the busy share between two samples", () => {
  assert.equal(
    cpuPercent({ idle: 840, total: 1000 }, { idle: 900, total: 1100 }),
    40,
  );
  assert.equal(
    cpuPercent({ idle: 0, total: 0 }, { idle: 0, total: 50 }),
    100,
  );
});

test("cpuPercent returns null without two usable samples", () => {
  const a = { idle: 10, total: 100 };
  assert.equal(cpuPercent(null, a), null);
  assert.equal(cpuPercent(a, null), null);
  assert.equal(cpuPercent(a, a), null);
  assert.equal(cpuPercent(a, { idle: 5, total: 90 }), null);
});

test("parseRam is used memory as a rounded percentage", () => {
  assert.equal(parseRam(MEMINFO), 75);
  assert.equal(
    parseRam("MemTotal: 3 kB\nMemAvailable: 1 kB\n"),
    67,
  );
});

test("memory details include available memory and optional swap in KiB", () => {
  const meminfo = "MemTotal: 16000000 kB\nMemAvailable: 4000000 kB\n" +
    "SwapTotal: 8000000 kB\nSwapFree: 6000000 kB\n";
  assert.equal(typeof SysStats.parseMemoryDetails, "function");
  assert.deepEqual(SysStats.parseMemoryDetails(meminfo), {
    usedKiB: 12000000,
    totalKiB: 16000000,
    availableKiB: 4000000,
    swapUsedKiB: 2000000,
    swapTotalKiB: 8000000,
  });
  assert.deepEqual(
    SysStats.parseMemoryDetails("MemTotal: 1000 kB\nMemAvailable: 250 kB\n"),
    {
      usedKiB: 750,
      totalKiB: 1000,
      availableKiB: 250,
      swapUsedKiB: null,
      swapTotalKiB: null,
    },
  );
});

test("parseRam returns null for malformed input", () => {
  assert.equal(parseRam(""), null);
  assert.equal(parseRam(undefined), null);
  assert.equal(parseRam("MemTotal: 100 kB\n"), null);
  assert.equal(parseRam("MemTotal: 0 kB\nMemAvailable: 0 kB\n"), null);
  assert.equal(parseRam("MemTotal: 100 kB\nMemAvailable: 200 kB\n"), null);
});

test("root filesystem capacity parses the fixed-byte df output", () => {
  assert.deepEqual(
    SysStats.parseRootFilesystem(
      "1B-blocks Used Available Use%\n100000 25000 70000 25%\n",
    ),
    {
      totalBytes: 100000,
      usedBytes: 25000,
      availableBytes: 70000,
      usedPercent: 25,
    },
  );
});

test("root filesystem capacity rejects missing and impossible df readings", () => {
  assert.equal(SysStats.parseRootFilesystem(""), null);
  assert.equal(SysStats.parseRootFilesystem("df failed\n"), null);
  assert.equal(
    SysStats.parseRootFilesystem("1B-blocks Used Available Use%\n"),
    null,
  );
  assert.equal(
    SysStats.parseRootFilesystem("100000 50000 70000 42%\n"),
    null,
  );
  assert.equal(
    SysStats.parseRootFilesystem(
      "999999999999999999 1 1 1%\n",
    ),
    null,
  );
});

test("disk activity resolves the root device and calculates byte rates", () => {
  const mountInfo = "31 22 259:2 / / rw,relatime - ext4 /dev/nvme0n1p2 rw\n";
  const before = "259 0 nvme0n1 0 0 1000 0 0 0 2000 0 0 0 0\n" +
    "259 2 nvme0n1p2 100 0 10 1 20 0 20 2 0 0 0\n";
  const after = "259 0 nvme0n1 0 0 2000 0 0 0 4000 0 0 0 0\n" +
    "259 2 nvme0n1p2 110 0 15 2 24 0 24 3 0 0 0\n";
  assert.deepEqual(
    SysStats.parseDiskActivity(mountInfo, before, after, 1000),
    {
      device: "nvme0n1p2",
      readBytesPerSecond: 2560,
      writeBytesPerSecond: 2048,
    },
  );
});

test("disk activity rejects incomplete and unusable root samples", () => {
  const mountInfo = "31 22 259:2 / / rw,relatime - ext4 /dev/nvme0n1p2 rw\n";
  const incompleteMount = "31 22 259:2 / / rw,relatime\n";
  const before = "259 2 nvme0n1p2 100 0 10 1 20 0 20 2 0 0 0\n";
  const after = "259 2 nvme0n1p2 110 0 15 2 24 0 24 3 0 0 0\n";
  assert.equal(
    SysStats.parseDiskActivity(incompleteMount, before, after, 1000),
    null,
  );
  assert.equal(SysStats.parseDiskActivity(mountInfo, before, "", 1000), null);
  assert.equal(SysStats.parseDiskActivity(mountInfo, before, after, 0), null);
  assert.equal(
    SysStats.parseDiskActivity(mountInfo, after, before, 1000),
    null,
  );
  assert.equal(
    SysStats.parseDiskActivity(mountInfo + mountInfo, before, after, 1000),
    null,
  );
});

test("network activity aggregates receive and transmit rates without loopback", () => {
  const before = "Inter-| Receive | Transmit\n" +
    " face |bytes packets errs drop fifo frame compressed multicast|bytes packets errs drop fifo colls carrier compressed\n" +
    "    lo: 100000 0 0 0 0 0 0 0 100000 0 0 0 0 0 0 0\n" +
    "  eth0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0\n" +
    " wlan0: 3000 0 0 0 0 0 0 0 5000 0 0 0 0 0 0 0\n";
  const after = "Inter-| Receive | Transmit\n" +
    " face |bytes packets errs drop fifo frame compressed multicast|bytes packets errs drop fifo colls carrier compressed\n" +
    "    lo: 900000 0 0 0 0 0 0 0 900000 0 0 0 0 0 0 0\n" +
    "  eth0: 1100 0 0 0 0 0 0 0 2200 0 0 0 0 0 0 0\n" +
    " wlan0: 3400 0 0 0 0 0 0 0 5500 0 0 0 0 0 0 0\n";

  assert.deepEqual(SysStats.parseNetworkActivity(before, after, 2000), {
    receiveBytesPerSecond: 250,
    transmitBytesPerSecond: 350,
  });
});

test("network activity rejects missing, malformed, reset, or invalid samples", () => {
  const before = "  eth0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0\n" +
    " wlan0: 3000 0 0 0 0 0 0 0 5000 0 0 0 0 0 0 0\n";
  const after = "  eth0: 1100 0 0 0 0 0 0 0 2200 0 0 0 0 0 0 0\n" +
    " wlan0: 3400 0 0 0 0 0 0 0 5500 0 0 0 0 0 0 0\n";
  const reset = "  eth0: 10 0 0 0 0 0 0 0 2200 0 0 0 0 0 0 0\n" +
    " wlan0: 3400 0 0 0 0 0 0 0 5500 0 0 0 0 0 0 0\n";
  const malformed = "  eth0: invalid 0 0 0 0 0 0 0 2200 0 0 0 0 0 0 0\n";

  assert.equal(SysStats.parseNetworkActivity(null, after, 1000), null);
  assert.equal(SysStats.parseNetworkActivity(before, malformed, 1000), null);
  assert.equal(SysStats.parseNetworkActivity(before, reset, 1000), null);
  assert.equal(SysStats.parseNetworkActivity(before, after, 0), null);
});
