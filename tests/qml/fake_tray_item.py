import os

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName("org.kde.StatusNotifierItem.qstest", bus)


class Item(dbus.service.Object):
    def __init__(self, path, identifier, title):
        super().__init__(bus, path)
        self.identifier = identifier
        self.title = title

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self.GetAll(interface)[prop]

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        properties = {
            "Category": "ApplicationStatus",
            "Id": self.identifier,
            "Title": self.title,
            "Status": "Active",
            "IconName": "",
            "ItemIsMenu": False,
        }
        if os.environ.get("NOTCH_TEST_ICON") == "1":
            pixels = dbus.ByteArray(bytes([255, 0, 0, 255] * 4))
            pixmap = dbus.Struct((2, 2, pixels), signature="iiay")
            properties["IconPixmap"] = dbus.Array([pixmap], signature="(iiay)")
        elif os.environ.get("NOTCH_TEST_ICON") == "missing":
            properties["IconName"] = "notch-test-missing-icon-83db4939"
        return properties

    @dbus.service.method("org.kde.StatusNotifierItem", in_signature="ii")
    def Activate(self, x, y):
        print("FAKE_ACTIVATED", flush=True)


paths = ["/StatusNotifierItem"]
items = [Item(paths[0], "qs-test", "QS Test App")]
if os.environ.get("NOTCH_TEST_COUNT") == "2":
    paths.append("/StatusNotifierItem2")
    items.append(Item(paths[1], "qs-test-2", "QS Test App 2"))


def register():
    try:
        watcher = bus.get_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
        for path in paths:
            watcher.RegisterStatusNotifierItem(name.get_name() + path, dbus_interface="org.kde.StatusNotifierWatcher")
        print("FAKE_REGISTERED", flush=True)
        return False
    except dbus.DBusException:
        return True


GLib.timeout_add(100, register)
GLib.MainLoop().run()
