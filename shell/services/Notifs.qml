pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
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

    // The shown toast ended without closing the notification (timeout).
    function advance() {
        queue = NotifQueue.advance(queue);
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

    function receive(notification) {
        const id = notification.id;
        notification.tracked = true;
        notification.closed.connect(() => root.queue = NotifQueue.close(root.queue, id));
        queue = NotifQueue.receive(queue, notification);
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
