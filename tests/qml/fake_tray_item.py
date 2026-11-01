import os

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName("org.kde.StatusNotifierItem.qstest", bus)


class Item(dbus.service.Object):
    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self.GetAll(interface)[prop]

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        properties = {
            "Category": "ApplicationStatus",
            "Id": "qs-test",
            "Title": "QS Test App",
            "Status": "Active",
            "IconName": "",
            "ItemIsMenu": False,
        }
        if os.environ.get("NOTCH_TEST_ICON") == "1":
            pixels = dbus.ByteArray(bytes([255, 0, 0, 255] * 4))
            pixmap = dbus.Struct((2, 2, pixels), signature="iiay")
            properties["IconPixmap"] = dbus.Array([pixmap], signature="(iiay)")
        return properties

    @dbus.service.method("org.kde.StatusNotifierItem", in_signature="ii")
    def Activate(self, x, y):
        print("FAKE_ACTIVATED", flush=True)


item = Item(bus, "/StatusNotifierItem")


def register():
    try:
        watcher = bus.get_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
        watcher.RegisterStatusNotifierItem(name.get_name(), dbus_interface="org.kde.StatusNotifierWatcher")
        print("FAKE_REGISTERED", flush=True)
        return False
    except dbus.DBusException:
        return True


GLib.timeout_add(100, register)
GLib.MainLoop().run()
