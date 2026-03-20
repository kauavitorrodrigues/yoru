import ".."
import Quickshell

TopBarWidget {
    id: root

    label: Qt.formatDateTime(clock.date, "hh:mm")
    labelColor: '#ffffff'
    hPadding: 30

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}