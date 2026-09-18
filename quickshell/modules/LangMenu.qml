import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}

    readonly property bool live: LangState.open

    readonly property bool sticky: LangState.open && !LangState.autoClose

    screen: {
        const named = Quickshell.screens.find(s => s.name === LangState.anchorScreen);
        if (named) return named;
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            const m = Quickshell.screens.find(s => s.name === fm.name);
            if (m) return m;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-langmenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: LangState.open || panel.busy

    mask: Region {
        x: win.sticky ? 0 : Math.round(panel.x + panel.fillet)
        y: win.sticky ? 0 : Math.round(panel.y)
        width: win.sticky ? win.width : Math.ceil(panel.panelWidth)
        height: win.sticky ? win.height : Math.ceil(panel.panelHeight)
    }

    onVisibleChanged: if (!visible) {
        LangState.autoClose = false;
        LangState.hovered = false;
    }

    MouseArea {
        anchors.fill: parent
        enabled: win.sticky
        onClicked: LangState.hide()
    }

    MenuPanel {
        id: panel

        theme: win.theme
        open: LangState.open

        onHoveredChanged: LangState.hovered = panel.hovered
        y: win.theme.barBottom

        x: {
            const want = LangState.anchorX - panel.implicitWidth / 2;
            const max = win.width - panel.implicitWidth - win.theme.barMargin;
            return Math.round(Math.max(win.theme.barMargin, Math.min(want, max)));
        }
        width: implicitWidth
        height: implicitHeight

        ColumnLayout {
            width: 236
            spacing: 6

            Text {
                text: "Input method"
                color: win.theme.text
                font.family: win.theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Repeater {
                model: InputState.methods

                delegate: Rectangle {
                    id: imRow
                    required property var modelData
                    readonly property bool isCurrent: imRow.modelData.name === InputState.im

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: win.theme.radiusSmall
                    color: imRow.isCurrent ? win.theme.pill
                                           : (imMouse.containsMouse ? win.theme.pillHover : "transparent")
                    antialiasing: true
                    Behavior on color { ColorAnimation { duration: win.theme.durFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: InputState.glyph(imRow.modelData.name)
                            color: imRow.isCurrent ? win.theme.highlight : win.theme.subtext
                            font.family: win.theme.fontFamily
                            font.pixelSize: 14
                            Layout.preferredWidth: 18
                        }

                        Text {
                            text: InputState.imName(imRow.modelData.name)
                            color: imRow.isCurrent ? win.theme.highlight : win.theme.text
                            font.family: InputState.isJapanese(imRow.modelData.name)
                                         ? win.theme.cjkFontFamily : win.theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: imRow.isCurrent
                            text: "\u{f012c}"
                            color: win.theme.highlight
                            font.family: win.theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: imMouse
                        anchors.fill: parent
                        hoverEnabled: win.live
                        enabled: win.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            InputState.selectIm(imRow.modelData.name);
                            LangState.hide();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                color: win.theme.borderDim
            }

            Text {
                text: "Configure…"
                color: cfgMouse.containsMouse ? win.theme.highlight : win.theme.subtext
                font.family: win.theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true

                MouseArea {
                    id: cfgMouse
                    anchors.fill: parent
                    hoverEnabled: win.live
                    enabled: win.live
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configtool.running = true;
                        LangState.hide();
                    }
                }
            }
        }
    }

    Process {
        id: configtool
        command: ["fcitx5-configtool"]
    }
}
