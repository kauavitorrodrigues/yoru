import ".."
import QtQuick
import Quickshell.Bluetooth
import "../../common"

// Shown only while at least one Bluetooth device is connected.
TopBarWidget {
    id: root

    readonly property var connectedDevices: {
        const list = Bluetooth.devices ? Bluetooth.devices.values : [];
        return list.filter(d => d.connected);
    }
    readonly property bool active: connectedDevices.length > 0

    visible: active
    icon: "󰂱"
    iconColor: Appearance.colors.textPrimary
    label: connectedDevices.length > 1 ? connectedDevices.length + " devices" : (active ? connectedDevices[0].name : "")
}
