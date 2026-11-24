pragma Singleton

import Quickshell
import QtQml
import Quickshell.Io
import Quickshell.Services.UPower
import "../config"
import "../logic/battery.mjs" as BatteryLogic

// Normalises the UPower display device for the idle notch. UPower starts
// lazily on first access, so the device is touched at startup and every value
// follows its change signals; there is no timer.
Singleton {
    id: root

    signal pluggedIn
    signal unplugged
    signal fullReached
    signal criticalReached

    readonly property var device: UPower.displayDevice

    property bool present: false
    property bool plugged: false
    property bool charging: false
    property bool full: false
    property int percentage: 0
    // none, charging, plugged, full or low (see logic/battery.mjs).
    property string layer: "none"

    // Extra figures for the control center card; 0 when UPower has no value.
    property int timeToEmpty: 0
    property int timeToFull: 0
    // Watts, positive in both directions.
    property real rate: 0

    // Wear, capacity and the charge limit read from sysfs: UPower has them on
    // D-Bus but Quickshell exposes none of them through UPower.
    property int health: 0
    property int cycles: 0
    property real energyNow: 0
    property real energyFull: 0
    property int chargeLimit: 0
    property bool infoVisible: false
    property int infoMilestone: 0
    property bool previousAtChargeLimit: false
    readonly property string chargeStage: BatteryLogic.chargeStage(percentage, {
        low: Limits.batteryLow,
        high: Limits.batteryHigh
    })

    readonly property string sysfsDir: "/sys/class/power_supply/" + (device && device.nativePath ? device.nativePath : "BAT0")

    property var previous: null
    property bool armed: true

    function stateName(value): string {
        switch (value) {
        case UPowerDeviceState.Charging:
            return "charging";
        case UPowerDeviceState.Discharging:
            return "discharging";
        case UPowerDeviceState.Empty:
            return "empty";
        case UPowerDeviceState.FullyCharged:
            return "full";
        case UPowerDeviceState.PendingCharge:
            return "pending-charge";
        case UPowerDeviceState.PendingDischarge:
            return "pending-discharge";
        default:
            return "unknown";
        }
    }

    // UPower counts in seconds; anything unusable reads as 0 (unknown).
    function seconds(value): int {
        return Number.isFinite(value) ? Math.max(0, Math.round(value)) : 0;
    }

    function readSysfs() {
        const values = BatteryLogic.parseSysfs({
            cycles: cyclesFile.text(),
            energyNow: energyNowFile.text(),
            energyFull: energyFullFile.text(),
            energyFullDesign: designFile.text(),
            endThreshold: limitFile.text()
        });
        health = values.health;
        cycles = values.cycles;
        energyNow = values.energyNow;
        energyFull = values.energyFull;
        chargeLimit = values.limit;
        refresh();
    }

    // sysfs sends no change events, so re-read it when the plug changes.
    function reloadSysfs() {
        cyclesFile.reload();
        energyNowFile.reload();
        energyFullFile.reload();
        designFile.reload();
        limitFile.reload();
    }

    function refresh() {
        const d = root.device;
        const real = BatteryLogic.fromUPower({
            present: !!d && d.ready && d.isLaptopBattery && d.isPresent,
            onBattery: UPower.onBattery,
            state: d ? stateName(d.state) : "unknown",
            fraction: d ? d.percentage : 0
        });

        // The card's extra figures; UPower sends 0 for anything unknown.
        const ready = !!d && d.ready;
        timeToEmpty = ready ? seconds(d.timeToEmpty) : 0;
        timeToFull = ready ? seconds(d.timeToFull) : 0;
        rate = ready && Number.isFinite(d.changeRate) ? Math.abs(d.changeRate) : 0;

        const next = BatteryLogic.applyOverride(real, Flags.batteryOverride);
        const limits = {
            low: Limits.batteryLow,
            high: Limits.batteryHigh,
            critical: Limits.batteryCritical
        };

        const step = BatteryLogic.criticalStep({
            armed: armed
        }, next, limits);
        const edge = previous ? BatteryLogic.edges(previous, next) : null;
        let milestone = BatteryLogic.infoMilestone(previous, next, chargeLimit, limits);
        const atChargeLimit = next.present && next.plugged && chargeLimit > 0 && next.percentage >= chargeLimit;
        if (atChargeLimit && !previousAtChargeLimit)
            milestone = chargeLimit;

        present = next.present;
        plugged = next.plugged;
        charging = next.charging;
        full = next.full;
        percentage = next.percentage;
        layer = BatteryLogic.classify(next, limits);
        armed = step.armed;
        previous = next;
        previousAtChargeLimit = atChargeLimit;
        if (milestone !== null) {
            infoMilestone = milestone;
            infoVisible = true;
            infoTimer.restart();
        }

        if (edge && edge.pluggedIn)
            pluggedIn();
        if (edge && edge.unplugged)
            unplugged();
        if (edge && edge.fullReached)
            fullReached();
        if (edge && (edge.pluggedIn || edge.unplugged))
            reloadSysfs();
        if (step.fire)
            criticalReached();
    }

    Component.onCompleted: refresh()

    Timer {
        id: infoTimer
        interval: Timings.batteryMilestone
        onTriggered: root.infoVisible = false
    }

    // One FileView per sysfs attribute: plain text, no process and no poll.
    FileView {
        id: cyclesFile

        path: root.sysfsDir + "/cycle_count"
        blockLoading: true
        printErrors: false
        onTextChanged: root.readSysfs()
    }

    FileView {
        id: energyNowFile

        path: root.sysfsDir + "/energy_now"
        blockLoading: true
        printErrors: false
        onTextChanged: root.readSysfs()
    }

    FileView {
        id: energyFullFile

        path: root.sysfsDir + "/energy_full"
        blockLoading: true
        printErrors: false
        onTextChanged: root.readSysfs()
    }

    FileView {
        id: designFile

        path: root.sysfsDir + "/energy_full_design"
        blockLoading: true
        printErrors: false
        onTextChanged: root.readSysfs()
    }

    FileView {
        id: limitFile

        path: root.sysfsDir + "/charge_control_end_threshold"
        blockLoading: true
        printErrors: false
        onTextChanged: root.readSysfs()
    }

    Connections {
        function onReadyChanged() {
            root.refresh();
        }
        function onIsPresentChanged() {
            root.refresh();
        }
        function onStateChanged() {
            root.refresh();
        }
        function onPercentageChanged() {
            root.refresh();
        }
        function onIsLaptopBatteryChanged() {
            root.refresh();
        }
        function onTimeToEmptyChanged() {
            root.refresh();
        }
        function onTimeToFullChanged() {
            root.refresh();
        }
        function onChangeRateChanged() {
            root.refresh();
        }

        target: root.device
    }

    Connections {
        function onOnBatteryChanged() {
            root.refresh();
        }

        target: UPower
    }
}
