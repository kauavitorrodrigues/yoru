import ".."
import QtQuick
import Quickshell.Services.UPower
import "../../common"

// Battery level from UPower's display device (aggregate of all laptop batteries).
// Hidden on machines without a laptop battery.
TopBarWidget {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device && device.ready && device.isLaptopBattery

    // UPower percentage is 0..1 in Quickshell; tolerate 0..100 just in case.
    readonly property int percent: {
        if (!present) return 0;
        const p = device.percentage;
        return Math.round(p <= 1 ? p * 100 : p);
    }
    // On AC power (charger plugged in), regardless of whether it is still charging.
    readonly property bool pluggedIn: present && !UPower.onBattery
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    readonly property bool low: present && !pluggedIn && percent <= 15

    readonly property var levelIcons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    visible: present

    // charging → bolt; plugged in but not charging (full / pending) → plug; on battery → level
    icon: charging ? "󰂄" : (pluggedIn ? "󰚥" : levelIcons[Math.min(10, Math.floor(percent / 10))])
    iconColor: low ? Appearance.colors.stateDanger : Appearance.colors.textPrimary
    label: percent + "%"
    labelColor: low ? Appearance.colors.stateDanger : Appearance.colors.textSecondary
}
