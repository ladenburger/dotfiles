import Quickshell
import "./modules" as Modules

ShellRoot {

    Variants {
        model: Quickshell.screens

        Modules.Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Modules.DesktopClock {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Modules.ScreenCorners {
            required property var modelData
            screen: modelData
        }
    }

    Modules.NotifPopups {
        theme: Modules.Notifications.theme
    }

    Modules.NotifCenter {
        theme: Modules.Notifications.theme
    }

    Modules.PowerMenu {}

    Modules.AltTab {}

    Modules.LangMenu {}

    Modules.Launcher {}
}
