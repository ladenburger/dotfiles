import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: theme.barHeight
    exclusiveZone: theme.barHeight
    color: "transparent"

    readonly property Theme theme: Theme {}

    readonly property string monitorName: bar.screen ? bar.screen.name : ""

    readonly property bool climbing: LangState.open
        && LangState.anchorScreen === bar.monitorName
        && Hypr.fullscreenOn(bar.monitorName)

    WlrLayershell.layer: bar.climbing ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    readonly property int islandWidth:
        bar.theme.islandWidth(bar.screen ? bar.screen.width : 1920)

    mask: Region {
        x: Math.round((bar.width - bar.islandWidth) / 2)
        y: 0
        width: bar.islandWidth
        height: bar.theme.barHeight
    }

    Rectangle {
        anchors.fill: parent
        color: bar.theme.frame
    }

    Item {
        id: content
        width: bar.islandWidth
        height: bar.theme.barHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        opacity: 0

        transform: Translate { id: slideIn; y: -bar.theme.barBottom }

        Component.onCompleted: {
            content.opacity = 1;
            introY.start();
        }
        NumberAnimation {
            id: introY
            target: slideIn
            property: "y"
            from: -bar.theme.barBottom
            to: 0
            duration: bar.theme.durSlow
            easing.type: Easing.OutCubic
        }
        Behavior on opacity { NumberAnimation { duration: bar.theme.durSlow } }

        Rectangle {
            anchors.fill: parent
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: bar.theme.barRadius
            bottomRightRadius: bar.theme.barRadius
            color: bar.theme.bg
            antialiasing: true
        }

        component Flare: CornerWedge {
            wedgeRadius: bar.theme.joinRadius
            wedgeColor: bar.theme.bg
            y: 0
        }

        Flare {
            corner: 1
            x: -width
        }
        Flare {
            corner: 0
            x: content.width
        }

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            spacing: 12

            DistroLogo {
                theme: bar.theme
            }

            Workspaces {
                theme: bar.theme
                screen: bar.screen
            }

            ActiveWindow {
                theme: bar.theme
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            spacing: 8

            Tray {
                theme: bar.theme
                barWindow: bar
                Layout.rightMargin: 4
            }

            SysPill {
                theme: bar.theme
            }

            Ime {
                theme: bar.theme
                screen: bar.screen
            }

            Volume {
                theme: bar.theme
                onChanged: (p, m) => osd.show(p, m)
            }

            NetworkMenu {
                theme: bar.theme
            }

            BluetoothMenu {
                theme: bar.theme
            }

            Battery {
                theme: bar.theme
            }

            NotifBell {
                theme: bar.theme
            }

            Clock {
                theme: bar.theme
            }
        }
    }

    VolumeOsd {
        id: osd
        theme: bar.theme
        screen: bar.screen
    }
}
