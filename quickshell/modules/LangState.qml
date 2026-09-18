pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property real anchorX: 0
    property string anchorScreen: ""

    property bool open: false

    property bool autoClose: false

    property bool hovered: false
    onHoveredChanged: root.retime()

    property bool armed: false

    function show(selfClosing) {
        root.autoClose = selfClosing;
        root.open = true;
        root.retime();
    }

    function hide() {
        hideTimer.stop();
        root.open = false;
    }

    function retime() {
        if (root.open && root.autoClose && !root.hovered)
            hideTimer.restart();
        else
            hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.open = false
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }
}
