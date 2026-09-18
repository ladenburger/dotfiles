import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    required property Theme theme

    signal changed(int percent, bool muted)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.audio ? sink.audio : null
    readonly property int percent: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    function isDevice(node, kind) {
        if (!node || (node.type & PwNodeType.Stream))
            return false;
        return (node.type & kind) === kind;
    }
    readonly property var sinks: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        return all.filter(n => root.isDevice(n, PwNodeType.AudioSink));
    }
    readonly property var sources: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        return all.filter(n => root.isDevice(n, PwNodeType.AudioSource));
    }

    function nodeName(node) {
        if (!node) return "";
        return node.description || node.nickname || node.name || "";
    }

    PwObjectTracker {
        objects: {
            const list = root.sinks.concat(root.sources);
            if (root.sink && list.indexOf(root.sink) < 0) list.push(root.sink);
            return list;
        }
    }

    function setVolume(p) {
        if (!audio) return;
        audio.muted = false;
        audio.volume = Math.max(0, Math.min(1, p / 100));
    }

    function glyph() {
        if (muted || percent === 0) return "\u{f075f}";
        if (percent < 34) return "\u{f057f}";
        if (percent < 67) return "\u{f0580}";
        return "\u{f057e}";
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: theme.pillHeight

    onPercentChanged: root.changed(percent, muted)
    onMutedChanged: root.changed(percent, muted)

    Pill {
        id: pill
        theme: root.theme
        icon: root.glyph()
        iconColor: root.muted ? root.theme.text : root.theme.audio
        label: root.muted ? "muted" : root.percent + "%"
        pillColor: root.muted ? root.theme.criticalBg : root.theme.pill
        pillHoverColor: root.muted ? root.theme.criticalBg : root.theme.pillHover
        active: menu.active
        onClicked: menu.active = !menu.active
        onRightClicked: if (root.audio) root.audio.muted = !root.audio.muted
        onWheel: delta => root.setVolume(root.percent + (delta > 0 ? 5 : -5))
    }

    BarMenu {
        id: menu
        anchorItem: pill
        theme: root.theme

        ColumnLayout {
            width: 320
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Audio"
                    color: root.theme.text
                    font.family: root.theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 26
                    radius: root.theme.radiusSmall
                    color: root.muted ? root.theme.criticalBg
                                      : (muteMouse.containsMouse ? root.theme.pillHover : root.theme.pill)
                    antialiasing: true
                    Behavior on color { ColorAnimation { duration: root.theme.durFast } }

                    Text {
                        anchors.centerIn: parent
                        text: root.muted ? "\u{f075f}" : "\u{f057e}"
                        color: root.muted ? root.theme.text : root.theme.audio
                        font.family: root.theme.fontFamily
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: muteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
                    }
                }
            }

            Gauge {
                Layout.alignment: Qt.AlignHCenter
                theme: root.theme
                open: menu.opened
                glyph: root.glyph()
                caption: root.muted ? "muted" : root.nodeName(root.sink)
                captionWidth: 296
                accent: root.muted ? root.theme.muted : root.theme.audio
                value: root.percent / 100
                amount: root.percent
                suffix: "%"
            }

            Item {
                id: slider
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                readonly property real frac: Math.max(0, Math.min(1, root.percent / 100))

                function setFromX(px) {
                    root.setVolume(Math.round(Math.max(0, Math.min(1, px / slider.width)) * 100));
                }

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: height / 2
                    antialiasing: true
                    color: root.theme.pill

                    Rectangle {
                        height: parent.height
                        width: parent.width * slider.frac
                        radius: height / 2
                        antialiasing: true
                        color: root.muted ? root.theme.muted : root.theme.audio
                        Behavior on width { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: root.theme.durFast } }
                    }
                }

                Rectangle {
                    id: handle
                    width: 14
                    height: 14
                    radius: height / 2
                    antialiasing: true
                    color: root.theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.round(slider.frac * (slider.width - width))
                    scale: sliderMouse.pressed ? 1.25 : (sliderMouse.containsMouse ? 1.12 : 1)
                    Behavior on x { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => slider.setFromX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) slider.setFromX(mouse.x); }
                    onWheel: wheel => root.setVolume(root.percent + (wheel.angleDelta.y > 0 ? 5 : -5))
                }
            }

            Text {
                text: "Output"
                color: root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                Layout.topMargin: 2
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.sinks

                    delegate: DeviceRow {
                        required property var modelData
                        theme: root.theme
                        label: root.nodeName(modelData)
                        glyph: "\u{f057e}"
                        current: root.sink === modelData
                        onPicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }

            Text {
                text: "Input"
                color: root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                Layout.topMargin: 4
                visible: root.sources.length > 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.sources

                    delegate: DeviceRow {
                        required property var modelData
                        theme: root.theme
                        label: root.nodeName(modelData)
                        glyph: "\u{f036c}"
                        current: Pipewire.defaultAudioSource === modelData
                        onPicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                color: root.theme.borderDim
            }

            Text {
                text: "Sound settings…"
                color: cfgMouse.containsMouse ? root.theme.highlight : root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true

                MouseArea {
                    id: cfgMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pavu.running = true;
                        menu.active = false;
                    }
                }
            }
        }
    }

    component DeviceRow: Rectangle {
        id: dev
        required property Theme theme
        property string label: ""
        property string glyph: ""
        property bool current: false

        signal picked

        Layout.fillWidth: true
        implicitHeight: 30
        radius: dev.theme.radiusSmall
        color: devMouse.containsMouse ? dev.theme.pillHover : "transparent"
        antialiasing: true
        Behavior on color { ColorAnimation { duration: dev.theme.durFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: dev.glyph
                color: dev.current ? dev.theme.highlight : dev.theme.subtext
                font.family: dev.theme.fontFamily
                font.pixelSize: 13
                Layout.preferredWidth: 16
            }

            Text {
                text: dev.label
                color: dev.current ? dev.theme.highlight : dev.theme.text
                font.family: dev.theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: dev.current
                text: "\u{f012c}"
                color: dev.theme.highlight
                font.family: dev.theme.fontFamily
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: devMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dev.picked()
        }
    }

    Process { id: pavu; command: ["sh", "-c", "pavucontrol || pwvucontrol"] }
}
