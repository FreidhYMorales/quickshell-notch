import { test } from "node:test";
import assert from "node:assert/strict";
import * as SysStats from "../shell/logic/sysStats.mjs";

const { cpuPercent, parseCpu, parseRam } = SysStats;

const STAT = "cpu  100 5 50 800 40 3 2 0 0 0\ncpu0 50 2 25 400 20 1 1 0 0 0\n";
const MEMINFO = "MemTotal:       16000000 kB\nMemFree:         2000000 kB\n" +
  "MemAvailable:    4000000 kB\nBuffers:          100000 kB\n";

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
