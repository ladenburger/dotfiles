import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: root

    required property Theme theme

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: !!(root.adapter && root.adapter.enabled)

    readonly property var devices: {
        const list = Bluetooth.devices ? Bluetooth.devices.values.slice() : [];
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        return list;
    }

    readonly property var connectedDevices: root.devices.filter(d => d.connected)

    function deviceGlyph(device) {
        const icon = device.icon ?? "";
        if (icon.includes("headset") || icon.includes("headphone") || icon.includes("audio")) return "󰋋";
        if (icon.includes("mouse")) return "󰍽";
        if (icon.includes("keyboard")) return "󰌌";
        if (icon.includes("phone")) return "󰄜";
        return "󰂯";
    }

    readonly property string pillIcon: {
        if (!root.powered) return "󰂲";
        if (root.connectedDevices.length > 0) return "󰂱";
        return "󰂯";
    }

    readonly property string pillLabel: {
        if (!root.powered) return "Off";
        if (root.connectedDevices.length === 1) return root.connectedDevices[0].name;
        if (root.connectedDevices.length > 1) return `${root.connectedDevices.length} connected`;
        return "Bluetooth";
    }

    readonly property color pillColor: {
        if (!root.powered) return root.theme.muted;
        if (root.connectedDevices.length > 0) return root.theme.bluetooth;
        return root.theme.subtext;
    }

    Pill {
        id: pill
        theme: root.theme
        icon: root.pillIcon
        label: root.pillLabel
        iconColor: root.pillColor
        active: popup.active
        onClicked: popup.active = !popup.active
    }

    BarMenu {
        id: popup
        anchorItem: pill
        theme: root.theme

        onActiveChanged: {
            if (root.adapter) root.adapter.discovering = popup.active && root.powered;
        }

        ColumnLayout {
            width: 300
            height: implicitHeight
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Bluetooth"
                    color: root.theme.text
                    font.family: root.theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40
                    height: 22
                    radius: height / 2
                    antialiasing: true
                    color: root.powered ? root.theme.bluetooth : root.theme.muted

                    Rectangle {
                        width: 16
                        height: 16
                        radius: height / 2
                        antialiasing: true
                        color: root.theme.bg
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.powered ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !!root.adapter
                        onClicked: root.adapter.enabled = !root.adapter.enabled
                    }
                }
            }

            Text {
                visible: !root.adapter
                text: "No adapter found"
                color: root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 12
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(deviceList.implicitHeight, 280)
                contentWidth: width
                contentHeight: deviceList.implicitHeight
                clip: true
                visible: root.powered

                ColumnLayout {
                    id: deviceList
                    width: parent.width
                    height: implicitHeight
                    spacing: 4

                    Repeater {
                        model: root.devices

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 36
                            radius: root.theme.radiusSmall
                            color: devMouse.containsMouse ? root.theme.pillHover : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: root.deviceGlyph(modelData)
                                    color: modelData.connected ? root.theme.highlight : root.theme.text
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 13
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.name
                                        color: modelData.connected ? root.theme.highlight : root.theme.text
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.connected
                                            ? (modelData.batteryAvailable ? `Connected · ${Math.round(modelData.battery * 100)}%` : "Connected")
                                            : (modelData.pairing ? "Pairing…" : (modelData.paired ? "Paired" : "Available"))
                                        color: root.theme.subtext
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    visible: modelData.paired && !modelData.connected
                                    text: "󰩹"
                                    color: root.theme.critical
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 13

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.forget()
                                    }
                                }
                            }

                            MouseArea {
                                id: devMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: -1
                                onClicked: {
                                    if (modelData.connected) {
                                        modelData.disconnect();
                                    } else if (modelData.paired || modelData.bonded) {
                                        modelData.connect();
                                    } else {
                                        modelData.pair();
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.devices.length === 0
                        text: "No devices found"
                        color: root.theme.subtext
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }
                }
            }
        }
    }
}
