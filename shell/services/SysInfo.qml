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
    property string cpuStatus: "measuring"
    property string ramStatus: "measuring"
    property var lastCpu: null
    property var logicalCpuCount: null
    property var loadAverage: null
    property var memoryDetails: null
    property var rootFilesystem: null
    property string rootFilesystemStatus: "measuring"
    property string rootMountInfoStatus: "measuring"
    property var diskActivity: null
    property string diskActivityStatus: "measuring"
    property var networkActivity: null
    property string networkActivityStatus: "measuring"
    property string rootMountInfo: ""
    property var lastDiskStats: null
    property var lastDiskSampleTime: null
    property string lastNetworkStats: ""
    property var lastNetworkSampleTime: null
    property var openControlCenters: ({})
    readonly property string mountInfoPath: Quickshell.env("NOTCH_SYSINFO_MOUNTINFO") || "/proc/self/mountinfo"
    readonly property string diskStatsPath: Quickshell.env("NOTCH_SYSINFO_DISKSTATS") || "/proc/diskstats"
    readonly property string networkStatsPath: Quickshell.env("NOTCH_SYSINFO_NETDEV") || "/proc/net/dev"
    property string logicalCpuCountStatus: "measuring"
    property string loadAverageStatus: "measuring"
    property string memoryDetailsStatus: "measuring"
    property string memorySwapStatus: "measuring"
    readonly property var ram: root.memoryDetails ? Math.round((1 - root.memoryDetails.availableKiB / root.memoryDetails.totalKiB) * 100) : null
    readonly property bool resourcePollingActive: !Flags.smoke && Object.keys(root.openControlCenters).length > 0

    function setControlCenterOpen(monitor, open) {
        const monitors = Object.assign({}, root.openControlCenters);
        if (open)
            monitors[monitor] = true;
        else
            delete monitors[monitor];
        root.openControlCenters = monitors;
        if (open && Object.keys(monitors).length === 1) {
            root.cpu = null;
            root.cpuStatus = "measuring";
            root.lastCpu = null;
            root.diskActivity = null;
            root.diskActivityStatus = "measuring";
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
            root.networkActivity = null;
            root.networkActivityStatus = "measuring";
            root.lastNetworkStats = "";
            root.lastNetworkSampleTime = null;
        } else if (!open && Object.keys(monitors).length === 0) {
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
            root.lastNetworkStats = "";
            root.lastNetworkSampleTime = null;
        }
    }

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: root.resourcePollingActive
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
        running: root.resourcePollingActive
        triggeredOnStart: true
        onTriggered: if (!diskProcess.running)
            diskProcess.running = true
    }

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: root.resourcePollingActive
        onTriggered: {
            mountInfo.reload();
            diskStats.reload();
            networkStats.reload();
        }
    }

    FileView {
        id: mountInfo

        path: root.resourcePollingActive ? root.mountInfoPath : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            root.rootMountInfo = text();
            root.rootMountInfoStatus = text().length > 0 ? "available" : "invalid";
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.rootMountInfo = "";
            root.rootMountInfoStatus = "unavailable";
        }
    }

    FileView {
        id: diskStats

        path: root.resourcePollingActive ? root.diskStatsPath : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            const now = Date.now();
            const current = text();
            if (root.lastDiskStats === null) {
                root.lastDiskStats = current;
                root.lastDiskSampleTime = now;
                if (root.rootMountInfoStatus === "unavailable") {
                    root.diskActivityStatus = "unavailable";
                } else if (root.rootMountInfoStatus === "measuring") {
                    root.diskActivityStatus = "measuring";
                } else {
                    const baseline = SysStats.parseDiskActivity(root.rootMountInfo, current, current, 1);
                    root.diskActivityStatus = baseline === null ? "invalid" : "measuring";
                }
                return;
            }
            root.diskActivity = SysStats.parseDiskActivity(root.rootMountInfo, root.lastDiskStats, current, now - root.lastDiskSampleTime);
            root.diskActivityStatus = SysStats.resourceReadingStatus({
                sourceAvailable: root.rootMountInfoStatus !== "unavailable",
                readingValid: root.diskActivity !== null,
                sampleReady: true
            });
            root.lastDiskStats = current;
            root.lastDiskSampleTime = now;
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.diskActivity = null;
            root.diskActivityStatus = "unavailable";
            root.lastDiskStats = null;
            root.lastDiskSampleTime = null;
        }
    }

    FileView {
        id: networkStats

        path: root.resourcePollingActive ? root.networkStatsPath : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            const now = Date.now();
            const current = text();
            if (root.lastNetworkSampleTime === null) {
                root.lastNetworkStats = current;
                root.lastNetworkSampleTime = now;
                const baseline = SysStats.parseNetworkActivity(current, current, 1);
                root.networkActivityStatus = baseline === null ? "invalid" : "measuring";
                return;
            }
            root.networkActivity = SysStats.parseNetworkActivity(root.lastNetworkStats, current, now - root.lastNetworkSampleTime);
            root.networkActivityStatus = SysStats.resourceReadingStatus({
                sourceAvailable: true,
                readingValid: root.networkActivity !== null,
                sampleReady: true
            });
            root.lastNetworkStats = current;
            root.lastNetworkSampleTime = now;
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.networkActivity = null;
            root.networkActivityStatus = "unavailable";
            root.lastNetworkStats = "";
            root.lastNetworkSampleTime = null;
        }
    }

    Process {
        id: diskProcess

        command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
        stdout: StdioCollector {
            id: diskOutput

            onStreamFinished: {
                root.rootFilesystem = SysStats.parseRootFilesystem(diskOutput.text);
                root.rootFilesystemStatus = SysStats.resourceReadingStatus({
                    sourceAvailable: true,
                    readingValid: root.rootFilesystem !== null,
                    sampleReady: true
                });
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

        path: root.resourcePollingActive ? "/proc/stat" : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            root.logicalCpuCount = SysStats.parseLogicalCpuCount(text());
            root.logicalCpuCountStatus = SysStats.resourceReadingStatus({
                sourceAvailable: true,
                readingValid: root.logicalCpuCount !== null,
                sampleReady: true
            });
            const sample = SysStats.parseCpu(text());
            if (sample === null) {
                root.cpu = null;
                root.lastCpu = null;
                root.cpuStatus = "invalid";
                console.warn("SysInfo: unreadable /proc/stat");
                return;
            }
            const previous = root.lastCpu;
            root.cpu = SysStats.cpuPercent(previous, sample);
            root.cpuStatus = SysStats.resourceReadingStatus({
                sourceAvailable: true,
                readingValid: previous === null || root.cpu !== null,
                sampleReady: previous !== null
            });
            root.lastCpu = sample;
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.cpu = null;
            root.cpuStatus = "unavailable";
            root.lastCpu = null;
            root.logicalCpuCount = null;
            root.logicalCpuCountStatus = "unavailable";
        }
    }

    FileView {
        id: loadavg

        path: root.resourcePollingActive ? "/proc/loadavg" : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            root.loadAverage = SysStats.parseLoadAverage(text());
            root.loadAverageStatus = SysStats.resourceReadingStatus({
                sourceAvailable: true,
                readingValid: root.loadAverage !== null,
                sampleReady: true
            });
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.loadAverage = null;
            root.loadAverageStatus = "unavailable";
        }
    }

    FileView {
        id: meminfo

        path: root.resourcePollingActive ? "/proc/meminfo" : ""
        onLoaded: {
            if (!root.resourcePollingActive)
                return;
            root.memoryDetails = SysStats.parseMemoryDetails(text());
            root.memoryDetailsStatus = SysStats.resourceReadingStatus({
                sourceAvailable: true,
                readingValid: root.memoryDetails !== null,
                sampleReady: true
            });
            root.ramStatus = root.memoryDetailsStatus;
            root.memorySwapStatus = root.memoryDetails === null ? root.memoryDetailsStatus : SysStats.parseMemorySwapStatus(text());
        }
        onLoadFailed: {
            if (!root.resourcePollingActive)
                return;
            root.memoryDetails = null;
            root.memoryDetailsStatus = "unavailable";
            root.ramStatus = "unavailable";
            root.memorySwapStatus = "unavailable";
        }
    }
}
