import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}

    readonly property real fill: 0.94
    readonly property real sink: 0.20

    property var cut: null

    readonly property string cacheDir:
        (Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`)
            .replace(/\/+$/, "") + "/quickshell"

    FileView {
        id: meta
        path: `${win.cacheDir}/wallpaper-cutout.json`
        watchChanges: true
        onFileChanged: this.reload()
        onLoadFailed: win.cut = null
        onLoaded: {
            let parsed = null;
            try {
                parsed = JSON.parse(this.text());
            } catch (e) {
                console.warn("desktop clock: bad wallpaper-cutout.json:", e);
            }
            win.cut = (parsed && parsed.pocket && parsed.roofline && parsed.rows
                       && parsed.width > 0 && parsed.height > 0) ? parsed : null;
        }
    }

    readonly property real fit: win.cut
        ? Math.max(win.width / win.cut.width, win.height / win.cut.height) : 1
    readonly property real originX: win.cut ? (win.width - win.cut.width * win.fit) / 2 : 0
    readonly property real originY: win.cut ? (win.height - win.cut.height * win.fit) / 2 : 0

    function sx(x: real): real { return win.originX + x * win.fit; }
    function sy(y: real): real { return win.originY + y * win.fit; }
    function imageY(y: real): real { return (y - win.originY) / win.fit; }

    function skyRoom(top: real, bottom: real, centre: real): real {
        if (!win.cut) return 0;
        const r = win.cut.rows;
        let room = -1;
        for (let i = 0; i < r.left.length; i++) {
            const y = r.y + i * r.step;
            if (y < top || y > bottom || r.right[i] < r.left[i]) continue;
            const here = 2 * Math.min(centre - r.left[i], r.right[i] - centre);
            if (room < 0 || here < room) room = here;
        }
        return room < 0 ? win.cut.pocket.width : Math.max(0, room);
    }

    property date now: new Date()

    Timer {
        interval: 1000
        running: win.visible
        repeat: true
        onTriggered: win.now = new Date()
    }

    readonly property string timeLabel: Qt.formatDateTime(win.now, "h:mm")

    readonly property string lang: {
        if (InputState.isJapanese(InputState.im)) return "ja";
        const code = InputState.layoutOfIm(InputState.im);
        return (code.length > 0 ? code : InputState.layout) || "us";
    }

    readonly property var languages: ({
        us: { locale: "en_US", format: "dddd  d MMMM", upper: true },
        gb: { locale: "en_GB", format: "dddd  d MMMM", upper: true },
        de: { locale: "de_DE", format: "dddd  d. MMMM", upper: true },
        ja: { locale: "ja_JP", format: "M月d日  dddd", upper: false }
    })

    readonly property var language: win.languages[win.lang]
        ?? ({ locale: win.lang, format: "dddd  d MMMM", upper: true })

    readonly property string dateLabel: {
        const written = win.now.toLocaleDateString(Qt.locale(win.language.locale),
                                                   win.language.format);
        return win.language.upper ? written.toUpperCase() : written;
    }

    readonly property int refSize: 200

    TextMetrics {
        id: ruler
        font.family: win.theme.fontFamily
        font.pixelSize: win.refSize
        font.weight: Font.Bold
        text: "88:88"
    }

    TextMetrics {
        id: inkRuler
        font: ruler.font
        text: win.timeLabel
    }

    readonly property real timeSize: (win.cut && ruler.advanceWidth > 0)
        ? win.refSize * (win.cut.pocket.width * win.fit * win.fill) / ruler.advanceWidth
        : 0

    readonly property real capHeight: ruler.tightBoundingRect.height * (win.timeSize / win.refSize)
    readonly property real inkWidth: inkRuler.advanceWidth * (win.timeSize / win.refSize)

    readonly property string dateFamily: win.lang === "ja"
        ? win.theme.cjkFontFamily : win.theme.fontFamily

    readonly property real dateTracking: 0.22

    TextMetrics {
        id: dateRuler
        font.family: win.dateFamily
        font.pixelSize: win.refSize
        font.weight: Font.Medium
        font.letterSpacing: win.refSize * win.dateTracking
        text: win.dateLabel
    }

    readonly property real dateNatural: win.timeSize * 0.17
    readonly property real pocketCentre:
        win.cut ? win.cut.pocket.x + win.cut.pocket.width / 2 : 0

    readonly property real dateBandBottom: win.imageY(win.baselineY - win.capHeight)
    readonly property real dateBandTop:
        win.dateBandBottom - (win.dateNatural * 2.2) / win.fit

    readonly property real dateSize: {
        if (!win.cut || dateRuler.advanceWidth <= 0) return Math.round(win.dateNatural);
        const room = win.skyRoom(win.dateBandTop, win.dateBandBottom, win.pocketCentre)
                     * win.fit * win.fill;
        return Math.round(Math.min(win.dateNatural,
                                   win.refSize * room / dateRuler.advanceWidth));
    }

    readonly property real roofY: {
        if (!win.cut) return 0;
        const rl = win.cut.roofline;
        const centre = win.cut.pocket.x + win.cut.pocket.width / 2;
        const half = (win.inkWidth / win.fit) / 2;
        const under = [];
        for (let i = 0; i < rl.y.length; i++) {
            const x = rl.x + i * rl.step;
            if (x >= centre - half && x <= centre + half) under.push(rl.y[i]);
        }
        if (under.length === 0) return win.cut.pocket.y + win.cut.pocket.height;
        under.sort((a, b) => a - b);
        return under[Math.floor(under.length / 2)];
    }

    readonly property real baselineY: win.sy(win.roofY) + win.sink * win.capHeight

    readonly property color ink: {
        const sky = (win.cut && win.cut.skyColour) || "#000000";
        const c = Qt.color(sky);
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.5
            ? win.theme.solidBg : win.theme.text;
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop-clock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    exclusiveZone: -1
    color: "transparent"
    visible: win.cut !== null

    mask: Region {
        x: wall.hits.x
        y: wall.hits.y
        width: wall.hits.width
        height: wall.hits.height
    }

    Item {
        anchors.fill: parent

        opacity: 0
        Component.onCompleted: this.opacity = 1
        Behavior on opacity { NumberAnimation { duration: win.theme.durSlow } }

        Text {
            id: dateText
            x: win.cut ? win.sx(win.cut.pocket.x) : 0
            width: win.cut ? win.cut.pocket.width * win.fit : 0

            y: win.baselineY - win.capHeight - win.dateSize * 1.5
            horizontalAlignment: Text.AlignHCenter
            text: win.dateLabel
            color: win.ink
            opacity: 0.7
            font.family: win.dateFamily
            font.pixelSize: win.dateSize
            font.weight: Font.Medium
            font.letterSpacing: win.dateSize * win.dateTracking
        }

        Text {
            id: timeText
            x: dateText.x
            width: dateText.width

            y: win.baselineY - baselineOffset
            horizontalAlignment: Text.AlignHCenter
            text: win.timeLabel
            color: win.ink
            font.family: ruler.font.family
            font.weight: ruler.font.weight
            font.pixelSize: Math.round(win.timeSize)
        }

        Image {
            anchors.fill: parent
            source: win.cut ? `file://${win.cut.cutout}?${win.cut.generated}` : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            smooth: true
        }

        DesktopWall {
            id: wall
            anchors.fill: parent
            theme: win.theme
            cut: win.cut
            fit: win.fit
            originX: win.originX
            originY: win.originY
        }
    }
}
