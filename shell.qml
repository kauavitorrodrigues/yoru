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
        active: Settings.modules.speech.enabled
        component: SpeechController {}
    }

    LazyLoader {
        active: Settings.modules.wallpaper.enabled
        component: WallpaperOverlay {}
    }

    LazyLoader {
        active: Settings.modules.wallpaper.enabled
        component: WallpaperController {}
    }
}