pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"

// Webapp sub-view of the launcher: the name and the URL of the site to turn
// into a desktop web app, with the action that installs it.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)

    signal back

    implicitHeight: Layout.webappViewHeight

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            back();
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            id: title

            width: parent.width
            text: Strings.webappTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        TextInput {
            id: nameField

            objectName: "webapp-name"
            width: parent.width
            height: Layout.webappFieldHeight
            focus: root.visible
            color: root.scheme.onSurface
            clip: true
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
            // Each opening starts from an empty form.
            onVisibleChanged: if (visible) {
                clear();
                forceActiveFocus();
            }
            Keys.onTabPressed: event => {
                urlField.forceActiveFocus();
                event.accepted = true;
            }
        }

        TextInput {
            id: urlField

            objectName: "webapp-url"
            width: parent.width
            height: Layout.webappFieldHeight
            color: root.scheme.onSurface
            clip: true
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
            Keys.onTabPressed: event => {
                nameField.forceActiveFocus();
                event.accepted = true;
            }
        }

        Item {
            width: parent.width
            height: Layout.webappFieldHeight

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: installLabel.width + 2 * Layout.webappButtonPad
                height: Layout.webappFieldHeight
                radius: height / 2
                color: Colours.cardFor(root.screen)

                Text {
                    id: installLabel

                    objectName: "webapp-install"
                    anchors.centerIn: parent
                    text: Strings.webappInstall
                    color: root.scheme.primary
                    font.family: Fonts.family
                    font.pixelSize: Fonts.launcherItem
                }
            }
        }
    }
}
