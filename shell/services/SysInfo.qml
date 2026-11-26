pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/sysStats.mjs" as SysStats

// CPU and RAM usage (0-100) read from /proc; null until a sample is usable.
// Smoke runs never poll.
Singleton {
    id: root

    property var cpu: null
    property var lastCpu: null
    property var logicalCpuCount: null
    property var loadAverage: null
    property var memoryDetails: null
    property var rootFilesystem: null
    property string rootFilesystemStatus: "measuring"
    property var diskActivity: null
    property string diskActivityStatus: "measuring"
    property string rootMountInfo: ""
    property var lastDiskStats: null
    property var lastDiskSampleTime: null
    property var openControlCenters: ({})
    readonly property string mountInfoPath: Quickshell.env("NOTCH_SYSINFO_MOUNTINFO") || "/proc/self/mountinfo"
    readonly property string diskStatsPath: Quickshell.env("NOTCH_SYSINFO_DISKSTATS") || "/proc/diskstats"
    property string logicalCpuCountStatus: "measuring"
    property string loadAverageStatus: "measuring"
    property string memoryDetailsStatus: "measuring"
    readonly property var ram: root.memoryDetails ? Math.round((1 - root.memoryDetails.availableKiB / root.memoryDetails.totalKiB) * 100) : null
    readonly property bool diskPollingActive: !Flags.smoke && Object.keys(root.openControlCenters).length > 0

    function setControlCenterOpen(monitor, open) {
        const monitors = Object.assign({}, root.openControlCenters);
        if (open)
            monitors[monitor] = true;
        else
            delete monitors[monitor];
        root.openControlCenters = monitors;
        if (open && Object.keys(monitors).length === 1) {
            root.diskActivity = null;
            root.diskActivityStatus = "measuring";
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
        } else if (!open && Object.keys(monitors).length === 0) {
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
        }
    }

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: !Flags.smoke
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
        }
    }

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: !Flags.smoke && Object.keys(root.openControlCenters).length > 0
        triggeredOnStart: true
        onTriggered: if (!diskProcess.running)
            diskProcess.running = true
    }

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: root.diskPollingActive
        onTriggered: {
            mountInfo.reload();
            diskStats.reload();
        }
    }

    FileView {
        id: mountInfo

        path: root.diskPollingActive ? root.mountInfoPath : ""
        onLoaded: {
            if (!root.diskPollingActive) return;
            root.rootMountInfo = text();
        }
        onLoadFailed: {
            if (!root.diskPollingActive) return;
            root.rootMountInfo = "";
        }
    }

    FileView {
        id: diskStats

        path: root.diskPollingActive ? root.diskStatsPath : ""
        onLoaded: {
            if (!root.diskPollingActive) return;
            const now = Date.now();
            const current = text();
            if (root.lastDiskStats === null) {
                root.lastDiskStats = current;
                root.lastDiskSampleTime = now;
                return;
            }
            root.diskActivity = SysStats.parseDiskActivity(root.rootMountInfo, root.lastDiskStats, current, now - root.lastDiskSampleTime);
            root.diskActivityStatus = root.diskActivity ? "available" : "unavailable";
            root.lastDiskStats = current;
            root.lastDiskSampleTime = now;
        }
        onLoadFailed: {
            if (!root.diskPollingActive) return;
            root.diskActivity = null;
            root.diskActivityStatus = "unavailable";
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
        }
    }

    Process {
        id: diskProcess

        command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
        stdout: StdioCollector {
            id: diskOutput

            onStreamFinished: {
                root.rootFilesystem = SysStats.parseRootFilesystem(diskOutput.text);
                root.rootFilesystemStatus = root.rootFilesystem ? "available" : "unavailable";
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.rootFilesystem = null;
                root.rootFilesystemStatus = "unavailable";
            }
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            root.logicalCpuCount = SysStats.parseLogicalCpuCount(text());
            root.logicalCpuCountStatus = root.logicalCpuCount === null ? "unavailable" : "available";
            const sample = SysStats.parseCpu(text());
            if (sample === null) {
                console.warn("SysInfo: unreadable /proc/stat");
                return;
            }
            root.cpu = SysStats.cpuPercent(root.lastCpu, sample);
            root.lastCpu = sample;
        }
        onLoadFailed: {
            root.cpu = null;
            root.logicalCpuCount = null;
            root.logicalCpuCountStatus = "unavailable";
        }
    }

    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: {
            root.loadAverage = SysStats.parseLoadAverage(text());
            root.loadAverageStatus = root.loadAverage === null ? "unavailable" : "available";
        }
        onLoadFailed: {
            root.loadAverage = null;
            root.loadAverageStatus = "unavailable";
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            root.memoryDetails = SysStats.parseMemoryDetails(text());
            root.memoryDetailsStatus = root.memoryDetails === null ? "unavailable" : "available";
        }
        onLoadFailed: {
            root.memoryDetails = null;
            root.memoryDetailsStatus = "unavailable";
        }
    }
}
