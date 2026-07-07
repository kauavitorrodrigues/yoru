import "modules/topbar"
import "modules/dock"
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
}