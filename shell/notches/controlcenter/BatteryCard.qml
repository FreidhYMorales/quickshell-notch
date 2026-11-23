import QtQuick
import "../../config"
import "../../logic/format.mjs" as Format
import "../../services"

// Control center battery card. The top line carries the charge, what the pack
// is doing and how long it lasts; below a hairline, three aligned stats: draw,
// stored energy and wear. Hidden on a machine without a battery.
Rectangle {
    id: root

    property var scheme

    readonly property color tint: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }
    readonly property string glyph: Battery.layer === "low" ? Strings.glyphBatteryLow : (Battery.plugged ? Strings.glyphBatteryFull : Strings.glyphBatteryHalf)
    // The layer label, plus the charge cap that explains a plugged pack that is
    // not charging ("Plugged in · limit 80%").
    readonly property string stateText: {
        const state = Strings.batteryStates[Battery.layer] ?? "";
        if (Battery.plugged && !Battery.charging && !Battery.full && Battery.chargeLimit > 0)
            return state + Strings.batteryDetailSeparator + Strings.batteryLimit.arg(Battery.chargeLimit);
        return state;
    }
    // Time to empty or to full; empty when UPower has no estimate.
    readonly property string timeDetail: {
        if (Battery.charging && Battery.timeToFull > 0)
            return Strings.batteryTimeToFull.arg(Format.formatUptime(Battery.timeToFull));
        if (!Battery.plugged && Battery.timeToEmpty > 0)
            return Strings.batteryTimeLeft.arg(Format.formatUptime(Battery.timeToEmpty));
        return "";
    }
    readonly property string drawValue: Battery.rate >= 0.1 ? Strings.batteryRate.arg(Format.formatDecimal(Battery.rate)) : Strings.batteryUnknown
    readonly property string energyValue: Battery.energyFull > 0 ? Strings.batteryWh.arg(Format.formatDecimal(Battery.energyNow), Format.formatDecimal(Battery.energyFull)) : Strings.batteryUnknown
    readonly property string wearValue: {
        const parts = [];
        if (Battery.health > 0)
            parts.push(Format.formatPercent(Battery.health));
        if (Battery.cycles > 0)
            parts.push(Strings.batteryCycles.arg(Battery.cycles));
        return parts.length > 0 ? parts.join(Strings.batteryDetailSeparator) : Strings.batteryUnknown;
    }

    visible: Battery.present
    width: Layout.ccListWidth
    height: content.implicitHeight + 2 * Layout.ccCardPad
    radius: Layout.cardRadius
    color: root.tint

    Column {
        id: content

        x: Layout.ccCardPad
        y: Layout.ccCardPad
        width: root.width - 2 * Layout.ccCardPad
        spacing: Layout.ccRowGap

        // One line, one baseline: glyph, charge, state, time.
        Item {
            width: parent.width
            implicitHeight: Math.max(charge.implicitHeight, time.implicitHeight)

            Text {
                id: charge

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: root.scheme.primary
                font.family: Fonts.family
                font.pixelSize: Fonts.control
            }

            Text {
                id: percent

                anchors.left: charge.right
                anchors.leftMargin: Layout.ccRowPad
                anchors.verticalCenter: parent.verticalCenter
                text: Format.formatPercent(Battery.percentage)
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.control
            }

            Text {
                anchors.left: percent.right
                anchors.leftMargin: Layout.ccRowPad
                anchors.right: time.left
                anchors.rightMargin: Layout.ccRowPad
                anchors.verticalCenter: parent.verticalCenter
                text: root.stateText
                elide: Text.ElideRight
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.small
            }

            Text {
                id: time

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeDetail
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.title
            }
        }

        Rectangle {
            width: parent.width
            height: Layout.ccDivider
            color: root.scheme.muted
            opacity: Colours.dividerAlpha
        }

        // Three columns sized by their content, with one equal gap between
        // them: the row spans the card exactly, captions and values share
        // each column's left edge.
        Item {
            id: stats

            width: parent.width
            implicitHeight: Math.max(drawStat.implicitHeight, energyStat.implicitHeight, wearStat.implicitHeight)

            readonly property real gap: Math.max(Layout.ccRowGap, (width - drawStat.implicitWidth - energyStat.implicitWidth - wearStat.implicitWidth) / 2)

            Column {
                id: drawStat

                x: 0

                Text {
                    text: Strings.batteryDrawLabel
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.caption
                }

                Text {
                    text: root.drawValue
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }
            }

            Column {
                id: energyStat

                x: drawStat.x + drawStat.implicitWidth + stats.gap

                Text {
                    text: Strings.batteryEnergyLabel
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.caption
                }

                Text {
                    text: root.energyValue
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }
            }

            Column {
                id: wearStat

                x: energyStat.x + energyStat.implicitWidth + stats.gap

                Text {
                    text: Strings.batteryWearLabel
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.caption
                }

                Text {
                    text: root.wearValue
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }
            }
        }
    }
}
