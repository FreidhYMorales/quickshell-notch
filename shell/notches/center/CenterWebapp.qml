pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../config"
import "../../services"
import "../../logic/webapp.mjs" as WebappLogic

// Webapp sub-view of the launcher: the name and the URL of the site to turn
// into a desktop web app, the action that installs it and one status line.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)

    signal back
    signal applied

    // Empty while the form waits; otherwise the line beside the action.
    property string status: ""
    property bool statusError: false

    implicitHeight: Layout.webappViewHeight

    // What each refused field says: the name never reaches the helper with a
    // path in it, and the URL must be one a browser opens.
    function message(error) {
        switch (error) {
        case "nameMissing":
            return Strings.webappNameMissing;
        case "nameUnsafe":
            return Strings.webappNameUnsafe;
        case "urlMissing":
            return Strings.webappUrlMissing;
        case "urlInvalid":
            return Strings.webappUrlInvalid;
        }
        return "";
    }

    // The helper writes the desktop entry and fetches the favicon; it gets the
    // name and the URL as separate arguments, never through a shell.
    function submit() {
        if (install.running)
            return;
        const checked = WebappLogic.validateInstall(nameField.text, urlField.text);
        statusError = checked.error !== "";
        if (statusError) {
            status = message(checked.error);
            return;
        }
        status = "";
        install.didStart = false;
        install.command = [Strings.webappHelper, checked.name, checked.url];
        install.running = true;
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            back();
            break;
        case Qt.Key_Tab:
            // Focus starts on the view, so Tab enters the form at the name.
            if (nameField.activeFocus)
                urlField.forceActiveFocus();
            else
                nameField.forceActiveFocus();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            submit();
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    onVisibleChanged: {
        if (!visible)
            return;
        status = "";
    }

    Process {
        id: install

        // A helper that cannot start never emits `exited`: `onStarted` stays
        // false and `running` drops back, which is the unavailable signal.
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (running || didStart)
                return;
            root.statusError = true;
            root.status = Strings.webappUnavailable;
        }
        onExited: code => {
            if (code !== 0) {
                root.statusError = true;
                root.status = Strings.webappInstallFailed;
                return;
            }
            root.status = Strings.webappInstalled;
            confirm.restart();
        }
    }

    Timer {
        id: confirm

        interval: Timings.webappConfirm
        onTriggered: root.applied()
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
            Keys.onReturnPressed: root.submit()
            Keys.onEnterPressed: root.submit()
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
            Keys.onReturnPressed: root.submit()
            Keys.onEnterPressed: root.submit()
        }

        Item {
            width: parent.width
            height: Layout.webappFieldHeight

            Rectangle {
                id: installButton

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

                TapHandler {
                    onTapped: root.submit()
                }
            }

            Text {
                objectName: "webapp-status"
                anchors.left: installButton.right
                anchors.leftMargin: Layout.launcherGap
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.status !== ""
                text: root.status
                color: root.statusError ? root.scheme.onSurface : root.scheme.primary
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }
        }
    }
}
