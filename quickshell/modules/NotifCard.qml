import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property Theme theme
    required property var notif
    property bool showProgress: false
    property int timeout: 5000

    property color surface: theme.frame

    property bool flushRight: false

    signal closed

    signal expired

    signal activated

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property bool hovered: bodyMouse.containsMouse || closeMouse.containsMouse || actionRow.hovered
    readonly property var defaultAction: {
        if (!notif || !notif.actions) return null;
        for (const a of notif.actions)
            if (a.identifier === "default") return a;
        return null;
    }
    readonly property var visibleActions: {
        if (!notif || !notif.actions) return [];
        return [...notif.actions].filter(a => a.identifier !== "default" && a.text.length > 0);
    }

    property real _age: 0

    implicitHeight: layout.implicitHeight + 24
    topLeftRadius: theme.radius
    bottomLeftRadius: theme.radius
    topRightRadius: root.flushRight ? 0 : theme.radius
    bottomRightRadius: root.flushRight ? 0 : theme.radius

    color: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, 1)

    border.width: root.critical ? 1 : 0
    border.color: theme.critical
    antialiasing: true

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._age = Date.now() - Notifications.timeOf(root.notif)
    }

    function agoText() {
        const s = Math.max(0, Math.floor(root._age / 1000));
        if (s < 45) return "now";
        const m = Math.floor(s / 60);
        if (m < 60) return m + "m ago";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h ago";
        return Math.floor(h / 24) + "d ago";
    }

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        anchors.margins: 1
        width: 3
        radius: width / 2
        antialiasing: true
        color: root.critical ? root.theme.critical
            : (root.notif && root.notif.urgency === NotificationUrgency.Low ? root.theme.muted : root.theme.highlight)
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 16
        spacing: 11

        Rectangle {
            Layout.alignment: Qt.AlignTop
            visible: icon.hasContent
            width: 40
            height: 40
            radius: root.theme.radiusSmall
            antialiasing: true
            color: Qt.rgba(1, 1, 1, 0.05)
            clip: true

            Image {
                id: icon
                anchors.fill: parent
                readonly property bool hasContent: source.toString().length > 0
                source: {
                    if (!root.notif) return "";
                    if (root.notif.image && root.notif.image.length > 0) return root.notif.image;
                    if (root.notif.appIcon && root.notif.appIcon.length > 0)
                        return Quickshell.iconPath(root.notif.appIcon, true);
                    return "";
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 80
                sourceSize.height: 80
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.notif ? (root.notif.appName || "Notification") : ""
                    color: root.theme.subtext
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.agoText()
                    color: root.theme.muted
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }
            }

            Text {
                text: root.notif ? root.notif.summary : ""
                visible: text.length > 0
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.notif ? root.notif.body : ""
                visible: text.length > 0
                color: root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
                Layout.fillWidth: true
            }

            Flow {
                id: actionRow
                Layout.fillWidth: true
                Layout.topMargin: root.visibleActions.length > 0 ? 4 : 0
                spacing: 6
                property bool hovered: false

                Repeater {
                    model: root.visibleActions
                    delegate: Rectangle {
                        id: actBtn
                        required property var modelData
                        implicitWidth: actLabel.implicitWidth + 20
                        implicitHeight: 26
                        radius: root.theme.radiusSmall
                        antialiasing: true
                        color: actMouse.containsMouse ? root.theme.highlight : root.theme.pill
                        Behavior on color { ColorAnimation { duration: root.theme.durFast } }

                        Text {
                            id: actLabel
                            anchors.centerIn: parent
                            text: actBtn.modelData.text
                            color: actMouse.containsMouse ? root.theme.solidBg : root.theme.text
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: actionRow.hovered = true
                            onExited: actionRow.hovered = false
                            onClicked: {
                                Notifications.invokeAction(root.notif, actBtn.modelData);
                                root.closed();
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { top: parent.top; right: parent.right }
        anchors.margins: 6
        width: 20
        height: 20
        radius: height / 2
        antialiasing: true
        color: closeMouse.containsMouse ? root.theme.critical : Qt.rgba(1, 1, 1, 0.08)
        opacity: root.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.theme.durFast } }
        Behavior on color { ColorAnimation { duration: root.theme.durFast } }

        Text {
            anchors.centerIn: parent
            text: "\u{f00d}"
            color: root.theme.text
            font.family: root.theme.fontFamily
            font.pixelSize: 10
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closed()
        }
    }

    Timer {
        id: lifeTimer
        interval: root.timeout
        running: root.showProgress && !root.critical && !root.hovered
        onTriggered: root.expired()
    }

    Rectangle {
        visible: root.showProgress && !root.critical
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.margins: 2
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: 2
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.07)

        Rectangle {
            id: lifeBar
            height: parent.height
            radius: height / 2
            color: root.theme.highlight
            width: parent.width * lifeBar.frac
            property real frac: 1

            NumberAnimation on frac {
                running: lifeTimer.running
                from: 1
                to: 0
                duration: root.timeout
            }
        }
    }

    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.defaultAction) {
                Notifications.invokeAction(root.notif, root.defaultAction);
                root.activated();
                root.closed();
            }
        }
    }
}
