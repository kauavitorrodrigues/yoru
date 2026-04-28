import ".."
import Quickshell
import "../../common"

TopBarWidget {
    id: root

    label: Qt.formatDateTime(clock.date, "hh:mm")
    labelColor: Appearance.colors.textPrimary
    hPadding: 30

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}