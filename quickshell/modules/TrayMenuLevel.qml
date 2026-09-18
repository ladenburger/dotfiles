import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: level

    required property Theme theme
    property var handle: null
    property int depth: 0
    signal triggered

    Layout.fillWidth: true
    spacing: 0

    QsMenuOpener {
        id: opener
        menu: level.handle
    }

    Repeater {
        model: opener.children ? opener.children.values : []

        delegate: ColumnLayout {
            id: entryCol
            required property var modelData
            Layout.fillWidth: true
            spacing: 0

            property bool expanded: false

            Item {
                visible: entryCol.modelData && entryCol.modelData.isSeparator
                Layout.fillWidth: true
                implicitHeight: visible ? 7 : 0
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 1
                    color: level.theme.borderDim
                }
            }

            Rectangle {
                id: row
                visible: entryCol.modelData && !entryCol.modelData.isSeparator
                readonly property var entry: entryCol.modelData
                Layout.fillWidth: true
                implicitHeight: visible ? 28 : 0
                implicitWidth: rlabel.x + rlabel.implicitWidth + 32
                color: rmouse.containsMouse && row.entry && row.entry.enabled
                    ? level.theme.highlight : "transparent"

                readonly property bool checked: row.entry && row.entry.buttonType
                    && row.entry.checkState === Qt.Checked

                readonly property string iconSource: {
                    const i = row.entry && row.entry.icon ? row.entry.icon : "";
                    if (i.length === 0) return "";
                    if (i.indexOf("/") === 0 || i.indexOf(":") >= 0) return i;
                    return Quickshell.iconPath(i, true);
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 9 + level.depth * 12
                    width: 14
                    text: row.checked ? "\u{f00c}" : ""
                    color: rmouse.containsMouse ? level.theme.solidBg : level.theme.highlight
                    font.family: level.theme.fontFamily
                    font.pixelSize: 11
                }

                Image {
                    visible: row.iconSource.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    x: 25 + level.depth * 12
                    width: 15
                    height: 15
                    source: row.iconSource
                    sourceSize.width: 30
                    sourceSize.height: 30
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Text {
                    id: rlabel
                    anchors.verticalCenter: parent.verticalCenter
                    x: (row.iconSource.length > 0 ? 45 : 26) + level.depth * 12
                    text: row.entry && row.entry.text ? row.entry.text.replace("&", "") : ""
                    color: !(row.entry && row.entry.enabled) ? level.theme.muted
                        : (rmouse.containsMouse ? level.theme.solidBg : level.theme.text)
                    font.family: level.theme.fontFamily
                    font.pixelSize: 12
                }

                Text {
                    visible: row.entry && row.entry.hasChildren
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    text: entryCol.expanded ? "\u{f0140}" : "\u{f0142}"
                    color: rmouse.containsMouse ? level.theme.solidBg : level.theme.subtext
                    font.family: level.theme.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: rmouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: row.entry && row.entry.enabled
                    onClicked: {
                        if (row.entry.hasChildren) {
                            entryCol.expanded = !entryCol.expanded;
                            if (entryCol.expanded && row.entry.sendOpened) row.entry.sendOpened();
                            return;
                        }
                        if (row.entry.sendTriggered) row.entry.sendTriggered();
                        else if (row.entry.triggered) row.entry.triggered();
                        level.triggered();
                    }
                }
            }

            Loader {
                id: subLoader
                Layout.fillWidth: true
                active: entryCol.expanded && entryCol.modelData
                    && entryCol.modelData.hasChildren && level.depth < 4
                visible: active
                source: "TrayMenuLevel.qml"
                onLoaded: {
                    item.theme = level.theme;
                    item.handle = entryCol.modelData;
                    item.depth = level.depth + 1;
                    item.triggered.connect(level.triggered);
                }
            }
        }
    }
}
