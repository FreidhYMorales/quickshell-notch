import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, keyboardMode: true, view: "resources" });
        }
    }
    TestCase {
        name: "ControlCenterResourceFocus"
        when: root.target !== null
        function test_tab_reaches_each_card_and_keeps_it_visible() {
            function collect(items, out) {
                for (const item of items) {
                    if (item.objectName && item.objectName.startsWith("cc-resource-card-")) out.push(item);
                    if (item.children && typeof item.children.length === "number") collect(item.children, out);
                }
            }
            const cards = [];
            collect(root.target.content, cards);
            const back = Visual.findNamed(root.target.content, "cc-resource-back");
            const viewport = Visual.findNamed(root.target.content, "cc-resource-grid-viewport");
            if (!back || !viewport || cards.length !== 13 || !back.activeFocusOnTab || cards.some(card => !card.activeFocusOnTab)) {
                console.error("resource keyboard: Back and all 13 cards must be in the Tab order");
                return Qt.exit(1);
            }
            back.forceActiveFocus();
            for (const card of cards) {
                keyClick(Qt.Key_Tab);
                if (!tryVerify(() => card.activeFocus, 500)) return Qt.exit(1);
                const y = card.mapToItem(viewport.contentItem, 0, 0).y;
                if (y < viewport.contentY || y + card.height > viewport.contentY + viewport.height) return Qt.exit(1);
            }
            for (let i = 0; i < cards.length; i++) keyClick(Qt.Key_Tab, Qt.ShiftModifier);
            if (!tryVerify(() => back.activeFocus, 500)) return Qt.exit(1);
            Qt.exit(0);
        }
    }
}
