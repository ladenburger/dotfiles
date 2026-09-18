import QtQuick

Item {
    id: root

    property bool active: false

    signal clicked

    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: root.clicked()
    }
}
