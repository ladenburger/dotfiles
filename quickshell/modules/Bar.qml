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

    readonly property int leftMargin: 10
    readonly property int rightMargin: 12

    // The island is sized by ratio on a wide screen, but a narrow one cannot
    // hold the preferred width's worth of content: grow it to whatever the two
    // groups actually need, up to the full screen minus the frame margins.
    readonly property int islandBase:
        bar.theme.islandWidth(bar.screen ? bar.screen.width : 1920)
    readonly property int islandMax:
        Math.max(bar.theme.barMinWidth, bar.width - 2 * bar.theme.barMargin)

    // Everything but the window title, which is the one item allowed to shrink.
    readonly property int fixedWidth: Math.ceil(
        bar.leftMargin + logo.implicitWidth + workspaces.implicitWidth
        + 2 * leftGroup.spacing + bar.theme.barGroupGap
        + rightGroup.implicitWidth + bar.rightMargin)

    readonly property int islandWidth: Math.min(
        bar.islandMax,
        Math.max(bar.islandBase, bar.fixedWidth + activeWindow.implicitWidth))

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
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: bar.leftMargin
            spacing: 12

            DistroLogo {
                id: logo
                theme: bar.theme
            }

            Workspaces {
                id: workspaces
                theme: bar.theme
                screen: bar.screen
            }

            ActiveWindow {
                id: activeWindow
                theme: bar.theme
                maxWidth: Math.max(0, Math.min(460, bar.islandMax - bar.fixedWidth))
            }
        }

        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: bar.rightMargin
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
