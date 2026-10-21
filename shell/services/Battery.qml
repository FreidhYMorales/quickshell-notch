pragma Singleton

import Quickshell
import QtQml
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

    function refresh() {
        const d = root.device;
        const real = BatteryLogic.fromUPower({
            present: !!d && d.ready && d.isLaptopBattery && d.isPresent,
            onBattery: UPower.onBattery,
            state: d ? stateName(d.state) : "unknown",
            fraction: d ? d.percentage : 0
        });
        const next = BatteryLogic.applyOverride(real, Flags.batteryOverride);
        const limits = {
            low: Limits.batteryLow,
            critical: Limits.batteryCritical
        };

        const step = BatteryLogic.criticalStep({
            armed: armed
        }, next, limits);
        const edge = previous ? BatteryLogic.edges(previous, next) : null;

        present = next.present;
        plugged = next.plugged;
        charging = next.charging;
        full = next.full;
        percentage = next.percentage;
        layer = BatteryLogic.classify(next, limits);
        armed = step.armed;
        previous = next;

        if (edge && edge.pluggedIn)
            pluggedIn();
        if (edge && edge.unplugged)
            unplugged();
        if (edge && edge.fullReached)
            fullReached();
        if (step.fire)
            criticalReached();
    }

    Component.onCompleted: refresh()

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

        target: root.device
    }

    Connections {
        function onOnBatteryChanged() {
            root.refresh();
        }

        target: UPower
    }
}
