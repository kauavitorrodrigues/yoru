import Quickshell.Io
import "../modules/wallpaper/state"

IpcHandler {
    target: "wallpaper"

    function toggle() {
        WallpaperState.toggle();
    }
}
