pragma Singleton

import Quickshell

Singleton {
    // Logical units, identical on every monitor.
    readonly property int idleHeight: 32
    readonly property int cornerWidth: 200
    // The workspaces window may grow past its slot so long strips are not
    // clipped; its shape stays content-sized.
    readonly property int cornerMaxWidth: 340
    readonly property int osdWidth: 220
    readonly property int gap: 8
    readonly property int earRadius: 12
    readonly property int cornerRadius: 18

    // Idle notch padding either side of the row, inside the ears. The width
    // itself follows the content (logic/centerLayout.mjs).
    readonly property int idlePad: 16

    // Centre width cap; layoutFor shrinks it further on narrow screens.
    readonly property int centerMaxWidth: 600
    readonly property var centerMaxWidthByMonitor: ({})

    // Idle row: arc meters, overlay dots and the gap between row items.
    readonly property int arcSize: 20
    readonly property real arcRing: 2.5
    readonly property int arcIcon: 9
    readonly property int dotSize: 6
    // Round `!` button for waiting criticals in the expanded notch.
    readonly property int criticalButton: 26
    readonly property int rowGap: 8

    // Idle media layer: mini album art on the left, mirrored bars on the right.
    readonly property int mediaArt: 22
    readonly property int mediaArtRadius: 6
    readonly property int mediaArtGlyph: 11
    readonly property int vizBarWidth: 3
    readonly property int vizGap: 2
    readonly property int vizMinHeight: 2
    readonly property int vizHeight: 18

    // Expanded centre notch: full width with a player, narrower clock card alone.
    readonly property int expandedHeight: 112
    readonly property int expandedWidth: 500
    readonly property int expandedClockWidth: 250

    // Power menu in the centre notch: one row of actions over the hold bar.
    readonly property int powerWidth: 360
    readonly property int powerHeight: 72
    readonly property int powerBarHeight: 3

    // Expanded content: padding inside the ears, gap between columns, the
    // clock card beside a player, and the album art.
    readonly property int expandedPad: 10
    readonly property int expandedGap: 12
    readonly property int clockCardWidth: 200
    readonly property int cardRadius: 14
    readonly property int artSize: 80
    readonly property int artRadius: 10
    readonly property int artGlyph: 28
    readonly property int controlGap: 12
    readonly property int weekCardPad: 4

    // Notification toast in the centre notch: compact row (idle height), and
    // the hovered card with body and action buttons.
    // The hovered card must stay within expandedHeight (the centre window).
    readonly property int toastWidth: 380
    readonly property int toastExpandedWidth: 480
    readonly property int toastExpandedHeight: 112
    readonly property int toastIcon: 20
    // Inner padding past the ears, bottom padding of the card, gap between items.
    readonly property int toastPad: 18
    readonly property int toastPadBottom: 14
    readonly property int toastGap: 10
    readonly property int toastButtonPad: 12
    readonly property int toastButtonHeight: 24

    // Workspaces notch (TL): the corner body is the idle row plus the ear.
    readonly property int cornerHeight: 44
    readonly property int wsSlot: 22
    readonly property int wsSlotActive: 28
    readonly property int wsIcon: 16
    readonly property int wsTrayIcon: 20
    readonly property int wsDivider: 1
    readonly property int wsHotZone: 24
    readonly property int wsPad: 10
    readonly property int wsGap: 4
    // Tray item menu inside the notch: option row, separator space and the
    // check mark shown for a checked option.
    readonly property int wsMenuRow: 24
    readonly property int wsMenuSeparator: 9
    readonly property int wsMenuGlyph: 12
    // Room around the options so the menu does not hug the notch edges.
    readonly property int wsMenuPad: 8
    readonly property int wsMenuPadBottom: 8

    // Control center (TR): its own fixed window anchored right, the corner
    // hot zone that opens it, and the profile header. The window only caps the
    // drawn shape (which follows its content), so it keeps room for the tray
    // and power rows on the way.
    readonly property int ccWidth: 320
    readonly property int ccHeight: 420
    readonly property int ccHotZone: 24
    readonly property int ccPad: 14
    readonly property int ccGap: 12
    readonly property int ccAvatar: 40
    // Round toggle buttons under the profile header.
    readonly property int ccTile: 40
    readonly property int ccTileGap: 8
    // Notifications section: list width, row height, icon and gaps.
    readonly property int ccListWidth: 280
    readonly property int ccRow: 30
    readonly property int ccRowRadius: 12
    readonly property int ccRowPad: 8
    readonly property int ccClearButton: 22
    // DND pill in the notifications subpage: track width and knob diameter.
    readonly property int ccPill: 40
    readonly property int ccKnob: 18
    readonly property int ccDivider: 1
    readonly property int ccRowIcon: 18
    readonly property int ccRowGap: 6
    readonly property int ccCardPad: 10
    // Notifications subpage: the smallest height of its scrolling list. The
    // list takes whatever the root lends it, so a subpage is never shorter.
    readonly property int ccListHeight: 180

    // OSDs (BL, VR): window height, slider thumb (also the track height),
    // inner padding, and the slot width under which an OSD is not drawn at all.
    readonly property int osdHeight: 36
    readonly property int sliderHeight: 24
    readonly property int osdPad: 12
    readonly property int osdMinWidth: 120

    // Bundle in the shape expected by logic/surfaceLayout.mjs.
    readonly property var tokens: ({
            idleHeight: idleHeight,
            cornerHeight: cornerHeight,
            osdHeight: osdHeight,
            cornerWidth: cornerWidth,
            osdWidth: osdWidth,
            gap: gap,
            centerMaxWidth: centerMaxWidth,
            centerMaxWidthByMonitor: centerMaxWidthByMonitor,
            expandedHeight: expandedHeight
        })
}
