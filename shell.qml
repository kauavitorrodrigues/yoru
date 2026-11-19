import "modules/topbar"
import "modules/dock"
import "modules/wallpaper"
import "modules/wallpaper/state"
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

    // Only instantiated while the picker is open (plus its fade-out), so the
    // window, model and carousel are freed when it is closed.
    LazyLoader {
        active: Settings.modules.wallpaper.enabled && WallpaperState.loaded
        component: WallpaperOverlay {}
    }

    LazyLoader {
        active: Settings.modules.wallpaper.enabled
        component: WallpaperController {}
    }
}