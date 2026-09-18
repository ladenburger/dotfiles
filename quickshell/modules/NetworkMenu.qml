import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

Item {
    id: root

    required property Theme theme

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    readonly property var wifiDevice: {
        const devices = Networking.devices ? Networking.devices.values : [];
        return devices.find(d => d.type === DeviceType.Wifi) ?? null;
    }

    readonly property var wiredDevice: {
        const devices = Networking.devices ? Networking.devices.values : [];
        return devices.find(d => d.type === DeviceType.Wired) ?? null;
    }

    readonly property var wifiNetworks: {
        if (!root.wifiDevice) return [];
        const list = root.wifiDevice.networks.values.slice();
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return list;
    }

    readonly property var activeWifiNetwork: root.wifiNetworks.find(n => n.connected) ?? null
    readonly property bool wiredConnected: !!(root.wiredDevice && root.wiredDevice.network && root.wiredDevice.network.connected)

    function signalGlyph(strength) {
        if (strength >= 80) return "󰤨";
        if (strength >= 55) return "󰤥";
        if (strength >= 30) return "󰤢";
        if (strength > 0) return "󰤟";
        return "󰤯";
    }

    readonly property string pillIcon: {
        if (root.wiredConnected) return "󰈀";
        if (!Networking.wifiEnabled) return "󰤮";
        if (root.activeWifiNetwork) return root.signalGlyph(root.activeWifiNetwork.signalStrength);
        return "󰤭";
    }

    readonly property string pillLabel: {
        if (root.wiredConnected) return "Wired";
        if (!Networking.wifiEnabled) return "Wi-Fi off";
        if (root.activeWifiNetwork) return root.activeWifiNetwork.name;
        return "No network";
    }

    readonly property color pillColor: {
        if (root.wiredConnected || root.activeWifiNetwork) return root.theme.network;
        if (!Networking.wifiEnabled) return root.theme.muted;
        return root.theme.critical;
    }

    property var pendingNetwork: null

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
            if (root.wifiDevice) root.wifiDevice.scannerEnabled = popup.active;
            if (!popup.active) root.pendingNetwork = null;
        }

        ColumnLayout {
            width: 300
            height: implicitHeight
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Network"
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
                    color: Networking.wifiEnabled ? root.theme.network : root.theme.muted

                    Rectangle {
                        width: 16
                        height: 16
                        radius: height / 2
                        antialiasing: true
                        color: root.theme.bg
                        anchors.verticalCenter: parent.verticalCenter
                        x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: !!root.wiredDevice
                height: 32
                radius: root.theme.radiusSmall
                color: root.theme.pill

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "󰈀"
                        color: root.wiredConnected ? root.theme.network : root.theme.muted
                        font.family: root.theme.fontFamily
                        font.pixelSize: 14
                    }

                    Text {
                        text: root.wiredDevice ? root.wiredDevice.name : ""
                        color: root.theme.text
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.wiredConnected ? "Connected" : "No cable"
                        color: root.theme.subtext
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(networkList.implicitHeight, 260)
                contentWidth: width
                contentHeight: networkList.implicitHeight
                clip: true
                visible: Networking.wifiEnabled

                ColumnLayout {
                    id: networkList
                    width: parent.width
                    height: implicitHeight
                    spacing: 4

                    Repeater {
                        model: root.wifiNetworks

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: root.theme.radiusSmall
                                color: netMouse.containsMouse ? root.theme.pillHover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: root.signalGlyph(modelData.signalStrength)
                                        color: modelData.connected ? root.theme.highlight : root.theme.text
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        text: modelData.name
                                        color: modelData.connected ? root.theme.highlight : root.theme.text
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: modelData.security !== WifiSecurityType.Open
                                        text: "󰌾"
                                        color: root.theme.subtext
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        visible: modelData.connected
                                        text: "󰄬"
                                        color: root.theme.highlight
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    id: netMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) return;
                                        if (modelData.known || modelData.security === WifiSecurityType.Open) {
                                            modelData.connect();
                                        } else {
                                            root.pendingNetwork = modelData;
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                visible: root.pendingNetwork === modelData
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 26
                                    radius: root.theme.radiusSmall
                                    color: root.theme.pill
                                    border.color: root.theme.muted
                                    border.width: 1

                                    TextInput {
                                        id: pskInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: root.theme.text
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        echoMode: TextInput.Password
                                        clip: true
                                        focus: root.pendingNetwork === modelData
                                        onAccepted: {
                                            modelData.connectWithPsk(text);
                                            root.pendingNetwork = null;
                                        }
                                    }
                                }

                                Text {
                                    text: "Connect"
                                    color: root.theme.network
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelData.connectWithPsk(pskInput.text);
                                            root.pendingNetwork = null;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.wifiNetworks.length === 0
                        text: "No networks found"
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
