import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    required property Theme theme
    required property var wall

    readonly property var g: root.wall.geo

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        let idle = null;
        for (const p of root.players) {
            if (!p) continue;
            if (p.isPlaying) return p;
            if (idle === null) idle = p;
        }
        return idle;
    }

    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property bool showing: root.g !== null && root.title.length > 0

    readonly property int band: root.g ? root.g.controlsBand : 0
    readonly property real bandH: root.g
        ? root.g.slats[root.band + 1].y - root.g.slats[root.band].y : 1
    readonly property real glyph: root.bandH * 0.32
    readonly property real step: root.bandH * 0.70
    readonly property real button: root.glyph * 1.35
    readonly property real rowY: root.bandH * 0.50
    readonly property real centreX: root.g ? (root.g.left + root.g.right) / 2 : 0

    readonly property rect hits: root.showing
        ? Qt.rect(root.wall.sx(root.centreX - root.step - root.button / 2),
                  root.wall.sy(root.wall.slatY(root.g.slats[root.band], root.centreX)
                               + root.rowY - root.button / 2),
                  (2 * root.step + root.button) * root.wall.fit,
                  root.button * root.wall.fit)
        : Qt.rect(0, 0, 0, 0)

    component Band: Item {
        required property int index
        x: root.wall.bandX(index)
        y: root.wall.bandY(index)
        width: root.wall.bandW(index)
        height: root.wall.bandH(index)
        transformOrigin: Item.TopLeft
        rotation: root.wall.bandTilt(index)

        readonly property real pad: height * 0.14
    }

    component Key: Item {
        id: key
        required property string glyph
        required property bool usable
        signal activated

        width: root.button * root.wall.fit
        height: width

        Text {
            anchors.centerIn: parent
            text: key.glyph
            color: root.theme.subtext
            opacity: !key.usable ? 0.2 : (hover.containsMouse ? 1 : 0.7)
            Behavior on opacity { NumberAnimation { duration: root.theme.durFast } }
            font.family: root.theme.fontFamily
            font.pixelSize: Math.max(1, Math.round(root.glyph * root.wall.fit))
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            enabled: key.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: key.activated()
        }
    }

    Loader {
        anchors.fill: parent
        active: root.g !== null
        sourceComponent: board
    }

    Component {
        id: board

        Item {
            anchors.fill: parent

            opacity: root.showing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: root.theme.durSlow } }

            Band {
                id: nowPlaying
                index: root.g.mediaBand

                Text {
                    id: trackTitle
                    x: nowPlaying.pad
                    y: nowPlaying.height * 0.22
                    width: parent.width - nowPlaying.pad * 2
                            - noteMark.width - nowPlaying.pad
                    text: root.title
                    elide: Text.ElideRight
                    color: root.theme.subtext
                    opacity: 0.85
                    font.family: root.theme.fontFamily
                    font.pixelSize: Math.max(1, Math.round(nowPlaying.height * 0.27))
                }

                Text {
                    x: nowPlaying.pad
                    y: trackTitle.y + trackTitle.height + nowPlaying.height * 0.04
                    width: trackTitle.width
                    text: root.artist
                    elide: Text.ElideRight
                    color: root.theme.subtext
                    opacity: 0.5
                    font.family: root.theme.fontFamily
                    font.pixelSize: Math.max(1, Math.round(nowPlaying.height * 0.175))
                }

                Text {
                    id: noteMark
                    x: parent.width - nowPlaying.pad - width
                    y: trackTitle.y
                    text: "󰎇"
                    color: root.theme.subtext
                    opacity: 0.35
                    font.family: root.theme.fontFamily
                    font.pixelSize: Math.max(1, Math.round(nowPlaying.height * 0.21))
                }
            }

            Band {
                id: controls
                index: root.band

                Row {
                    y: root.rowY * root.wall.fit - height / 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    spacing: (root.step - root.button) * root.wall.fit

                    Key {
                        glyph: "󰒮"
                        usable: root.player !== null && root.player.canGoPrevious
                        onActivated: root.player.previous()
                    }

                    Key {
                        glyph: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                        usable: root.player !== null && root.player.canTogglePlaying
                        onActivated: root.player.togglePlaying()
                    }

                    Key {
                        glyph: "󰒭"
                        usable: root.player !== null && root.player.canGoNext
                        onActivated: root.player.next()
                    }
                }
            }
        }
    }
}
