import "modules/topbar"
import "modules/dock"
import "modules/wallpaper"
import "controllers"
import "services"
import Quickshell

ShellRoot {
    TopBar {}
    Dock {}

    LazyLoader {
        active: Settings.speech.enabled
        component: SpeechController {}
    }

    LazyLoader {
        active: Settings.wallpaper.enabled
        component: WallpaperOverlay {}
    }

    LazyLoader {
        active: Settings.wallpaper.enabled
        component: WallpaperController {}
    }
}