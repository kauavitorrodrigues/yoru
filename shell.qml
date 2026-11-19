import "modules/topbar"
import "modules/island"
import "modules/dock"
import "modules/wallpaper"
import "modules/wallpaper/state"
import "controllers"
import "services"
import Quickshell

ShellRoot {
    LazyLoader {
        active: Settings.layout.topbar.mode !== "island"
        component: TopBar {}
    }

    LazyLoader {
        active: Settings.layout.topbar.mode === "island"
        component: Island {}
    }

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