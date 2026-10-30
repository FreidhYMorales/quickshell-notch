pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../config"
import "../logic/notifQueue.mjs" as NotifQueue

// Owns the DBus notification server and the global toast queue. Every
// notification is tracked so its actions and dismiss reach the app. The server
// is never created under Flags.smoke (it would take the session's DBus name).
Singleton {
    id: root

    property var queue: NotifQueue.emptyQueue()
    readonly property var current: queue.current
    readonly property int waiting: queue.waiting.length
    // Critical notifications that timed out, newest first: the `!` indicator.
    property var pinned: []
    // Ids for shell-made notifications; negative so they never meet DBus ids.
    property int nextLocalId: -1
    readonly property bool currentCritical: current?.urgency === NotificationUrgency.Critical
    // Do-not-disturb: normal toasts are muted (session only, starts off).
    property bool dnd: false

    // Something arrived since the last markSeen (drives the unread dot).
    property bool unread: false

    function toggleDnd() {
        dnd = !dnd;
    }

    function markSeen() {
        unread = false;
    }

    // The shown toast ended without closing the notification (timeout).
    function advance() {
        queue = NotifQueue.advance(queue);
    }

    // The shown toast timed out or was muted: a critical one waits as a pin.
    function collapse() {
        const result = NotifQueue.collapse(queue, pinned, currentCritical);
        pinned = result.pinned;
        queue = result.queue;
    }

    // A click on the `!`: the newest waiting critical shows again.
    function reopen() {
        const result = NotifQueue.reopen(queue, pinned);
        pinned = result.pinned;
        queue = result.queue;
    }

    // ✕ on the toast: closes the notification for the app too; `closed` drops it.
    function dismiss(id: int) {
        if (current?.id === id)
            current.dismiss();
    }

    // An action button or the body click (`null`: no default action). The
    // toast closes; a resident notification stays open for the app.
    function activate(action) {
        const shown = current;
        if (action)
            action.invoke();
        if (current === shown)
            advance();
    }

    // A shell-made critical notification (the battery warning). It behaves like
    // a DBus one in the toast, with no actions; dismiss only closes it here.
    function post(appName: string, summary: string, body: string, appIcon: string) {
        const id = nextLocalId--;
        queue = NotifQueue.receive(queue, {
            id: id,
            appName: appName,
            summary: summary,
            body: body,
            appIcon: appIcon,
            image: "",
            actions: [],
            urgency: NotificationUrgency.Critical,
            dismiss: () => root.closed(id)
        });
        unread = true;
    }

    // A notification closed (by its app, or ✕ on a shell-made one).
    function closed(id: int) {
        queue = NotifQueue.close(queue, id);
        pinned = NotifQueue.unpin(pinned, id);
    }

    function receive(notification) {
        const id = notification.id;
        notification.tracked = true;
        notification.closed.connect(() => root.closed(id));
        queue = NotifQueue.receive(queue, notification);
        unread = true;
    }

    // `qs -c notch ipc call notifs <fn>`; keybinds and the control center reuse these.
    IpcHandler {
        target: "notifs"

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function markSeen(): void {
            root.markSeen();
        }
    }

    LazyLoader {
        active: !Flags.smoke

        NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodySupported: true
            imageSupported: true
            inlineReplySupported: false
            onNotification: notification => root.receive(notification)
        }
    }
}
