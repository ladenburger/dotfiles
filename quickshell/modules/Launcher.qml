import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "math.js" as Calc

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}

    property bool shown: false
    property string mode: "apps"
    property string query: ""

    property int selectedIndex: 0

    readonly property var calc: win.mode === "apps" ? Calc.analyse(win.query) : null
    readonly property bool calcReady: !!win.calc && win.calc.hasValue

    onQueryChanged: win.selectedIndex = win.calcReady ? -1 : 0
    onCalcReadyChanged: win.selectedIndex = win.calcReady ? -1 : 0

    property var dmenuItems: []
    property string dmenuPrompt: ""
    property string _dmenuOut: ""

    function fzScore(q, hay, primary) {
        if (!q)
            return 0;
        let hi = 0, score = 0, run = 0;
        for (let i = 0; i < q.length; i++) {
            const idx = hay.indexOf(q[i], hi);
            if (idx < 0)
                return -1e9;
            if (idx === hi && i > 0) {
                run++;
                score += 6 + run * 4;
            } else {
                run = 0;
                score += 1;
            }
            const prev = idx > 0 ? hay[idx - 1] : " ";
            if (prev === " " || prev === "-" || prev === "_" || prev === "/" || prev === ".")
                score += 12;
            score -= Math.min(idx - hi, 12) * 0.6;
            hi = idx + 1;
        }
        if (primary !== undefined) {
            if (primary.startsWith(q))
                score += 50;
            else if (primary.indexOf(q) >= 0)
                score += 18;
        }
        return score;
    }

    readonly property string _usagePath: Quickshell.statePath("launcher-usage.json")
    property var _usage: ({})
    property int _usageRev: 0

    Component.onCompleted: _usageDir.running = true
    Process {
        id: _usageDir
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")"', "launcher", win._usagePath]
    }

    FileView {
        id: usageFile
        path: win._usagePath
        blockLoading: true
        printErrors: false
        onLoaded: win._parseUsage()
        onLoadFailed: { win._usage = ({}); win._usageRev++; }
    }
    function _parseUsage() {
        try {
            const t = usageFile.text();
            win._usage = (t && t.trim().length) ? JSON.parse(t) : ({});
        } catch (e) {
            win._usage = ({});
        }
        win._usageRev++;
    }
    function _frecency(id) {
        const u = id ? win._usage[id] : null;
        if (!u || !u.n)
            return 0;
        const ageDays = (Date.now() - (u.t || 0)) / 86400000;
        const recency = ageDays < 1 ? 4 : ageDays < 7 ? 2 : ageDays < 30 ? 1 : 0.5;
        return u.n * recency;
    }
    function _bumpUsage(id) {
        if (!id)
            return;
        const u = win._usage[id] || { n: 0, t: 0 };
        u.n = (u.n || 0) + 1;
        u.t = Date.now();
        win._usage[id] = u;
        win._usageRev++;
        usageFile.setText(JSON.stringify(win._usage));
    }

    readonly property var results: {
        const q = win.query.trim().toLowerCase();

        if (win.mode === "dmenu") {
            const items = win.dmenuItems;
            if (!q)
                return items.map(t => ({ text: t, sub: "", entry: null }));
            return items
                .map(t => ({ text: t, sub: "", entry: null, _s: win.fzScore(q, t.toLowerCase(), t.toLowerCase()) }))
                .filter(r => r._s > -1e8)
                .sort((a, b) => b._s - a._s);
        }

        void win._usageRev;
        const model = DesktopEntries.applications;
        const apps = model ? model.values.filter(a => a && !a.noDisplay) : [];
        const mapped = apps.map(a => ({
            text: a.name || a.id,
            sub: a.genericName || a.comment || "",
            entry: a,
            _hay: ((a.name || "") + " " + (a.genericName || "") + " " + (a.comment || "") + " "
                   + ((a.keywords || []).join(" "))).toLowerCase()
        }));
        if (!q)
            return mapped.sort((a, b) => {
                const fa = win._frecency(a.entry.id), fb = win._frecency(b.entry.id);
                return fb !== fa ? fb - fa : a.text.localeCompare(b.text);
            });
        return mapped
            .map(r => Object.assign(r, {
                _s: win.fzScore(q, r._hay, r.text.toLowerCase())
                    + Math.min(win._frecency(r.entry.id) * 2, 45)
            }))
            .filter(r => r._s > -1e8)
            .sort((a, b) => b._s - a._s);
    }

    onResultsChanged: if (win.selectedIndex >= win.results.length)
        win.selectedIndex = 0

    function openApps() {
        win.mode = "apps";
        win._reset();
        win.shown = true;
    }
    function toggle() {
        if (win.shown)
            win.cancel();
        else
            win.openApps();
    }
    function cancel() {
        if (win.mode === "dmenu")
            win.finishDmenu("");
        win.shown = false;
        win._reset();
    }
    function accept(alt) {
        if (win.mode === "apps" && win.selectedIndex === -1 && win.calcReady) {
            Quickshell.execDetached(["wl-copy", "--", alt ? win.calc.tex : win.calc.copy]);
            win.shown = false;
            win._reset();
            return;
        }
        const r = win.results[win.selectedIndex] ?? null;

        if (win.mode === "dmenu") {
            win.finishDmenu(r ? r.text : win.query.trim());
            win.shown = false;
            win._reset();
            return;
        }

        if (r && r.entry) {
            win._bumpUsage(r.entry.id);
            try {
                r.entry.execute();
            } catch (e) {
                const cmd = (r.entry.command || []).filter(s => !/^%/.test(s));
                if (cmd.length)
                    Quickshell.execDetached(cmd);
            }
            win.shown = false;
            win._reset();
        }
    }
    function move(d) {
        const lo = win.calcReady ? -1 : 0;
        const n = win.results.length - lo;
        if (n === 0) {
            win.selectedIndex = 0;
            return;
        }
        win.selectedIndex = ((win.selectedIndex - lo + d) % n + n) % n + lo;
        if (win.selectedIndex >= 0)
            list.positionViewAtIndex(win.selectedIndex, ListView.Contain);
    }
    function _reset() {
        win.query = "";
        input.text = "";
        win.selectedIndex = 0;
    }

    FileView {
        id: dmenuIn
        blockLoading: true
    }
    function loadDmenu(prompt, inPath, outPath) {
        if (win._dmenuOut)
            win.finishDmenu("");
        win._dmenuOut = outPath;
        win.dmenuPrompt = prompt || "";
        dmenuIn.path = inPath;
        dmenuIn.reload();
        const raw = dmenuIn.text() || "";
        win.dmenuItems = raw.length ? raw.replace(/\n+$/, "").split("\n") : [];
        win.mode = "dmenu";
        win._reset();
        win.shown = true;
    }
    Process {
        id: dmenuWriter
    }
    function finishDmenu(value) {
        const out = win._dmenuOut;
        win._dmenuOut = "";
        if (!out)
            return;

        dmenuWriter.command = ["sh", "-c", 'printf %s "$2" > "$1"', "qs-dmenu", out, value];
        dmenuWriter.running = true;
    }

    screen: {
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            const m = Quickshell.screens.find(s => s.name === fm.name);
            if (m)
                return m;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: -1
    color: "transparent"
    visible: win.shown || closeHold.running

    Timer {
        id: closeHold
        interval: win.theme.durMed + 60
    }
    onShownChanged: {
        if (!shown)
            closeHold.restart();
        else
            Qt.callLater(input.forceActiveFocus);
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { win.toggle() }
        function open(): void { win.openApps() }
        function hide(): void { win.cancel() }
        function dmenu(prompt: string, inPath: string, outPath: string): void {
            win.loadDmenu(prompt, inPath, outPath);
        }
    }

    GlobalShortcut {
        name: "launcher"
        description: "Toggle the application launcher"
        onPressed: win.toggle()
    }

    ClickAway {
        active: win.shown
        onClicked: win.cancel()
    }

    Item {
        id: clipArea
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.topMargin: win.theme.barBottom
        height: win.theme.barHeight + 600
        clip: true

        Rectangle {
            id: panel

            readonly property int fullWidth: 640
            x: Math.round((parent.width - panel.fullWidth) / 2)

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: win.theme.radius
            bottomRightRadius: win.theme.radius

            color: win.theme.bg
            antialiasing: true

            clip: true

            height: layout.implicitHeight
            y: win.shown ? 0 : -panel.height
            width: win.shown ? panel.fullWidth : 0

            Behavior on y {
                NumberAnimation {
                    duration: win.shown ? win.theme.durMed : win.theme.durFast
                    easing.type: win.shown ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: win.shown ? win.theme.durMed : win.theme.durFast
                    easing.type: win.shown ? Easing.OutCubic : Easing.InCubic
                }
            }

            Behavior on height {
                enabled: win.shown && panel.y === 0
                NumberAnimation {
                    duration: win.theme.durMed
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }

            Column {
                id: layout
                width: panel.fullWidth

                Item {
                    width: parent.width
                    height: 48

                    Text {
                        id: mag
                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        text: "\u{f0349}"
                        color: win.theme.subtext
                        font.family: win.theme.fontFamily
                        font.pixelSize: 15
                    }

                    TextInput {
                        id: input
                        anchors {
                            left: mag.right
                            leftMargin: 10
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        color: win.theme.text
                        font.family: win.theme.fontFamily
                        font.pixelSize: 14
                        selectionColor: win.theme.highlight
                        selectedTextColor: win.theme.solidBg
                        selectByMouse: true
                        clip: true
                        onTextChanged: win.query = text

                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                win.cancel();
                                event.accepted = true;
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                win.accept(event.modifiers & Qt.ShiftModifier);
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                                win.move(-1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                win.move(1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Tab:
                                win.move(1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Backtab:
                                win.move(-1);
                                event.accepted = true;
                                break;
                            default:
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                                        win.move(1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                                        win.move(-1);
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.fill: input
                        verticalAlignment: Text.AlignVCenter
                        visible: input.text.length === 0
                        text: win.mode === "dmenu"
                              ? (win.dmenuPrompt.length ? win.dmenuPrompt : "Type and press Enter…")
                              : "Search apps or calculate…"
                        color: win.theme.muted
                        font.family: win.theme.fontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: win.theme.border
                    opacity: 0.4
                    visible: list.visible || calcCard.visible
                }

                Item {
                    width: parent.width
                    height: list.visible || calcCard.visible ? 6 : 0
                }

                Item {
                    id: calcCard
                    width: parent.width
                    height: visible ? mathView.height + 20 + (list.visible ? 4 : 0) : 0
                    visible: !!win.calc

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: 6
                            rightMargin: 6
                            bottomMargin: list.visible ? 4 : 0
                        }
                        radius: win.theme.radiusSmall
                        antialiasing: true
                        color: win.selectedIndex === -1 && win.calcReady ? win.theme.pillHover : "transparent"
                    }

                    MathView {
                        id: mathView
                        anchors {
                            left: parent.left
                            leftMargin: 18
                            top: parent.top
                            topMargin: 10
                        }
                        theme: win.theme
                        tree: win.calc ? win.calc.tree : null
                        maxWidth: parent.width - 36 - (calcHint.visible ? calcHint.width + 12 : 0)
                    }

                    Text {
                        id: calcHint
                        anchors {
                            right: parent.right
                            rightMargin: 20
                            verticalCenter: mathView.verticalCenter
                        }
                        visible: win.calcReady
                        text: "\u{f0311} copy   \u{f0636}\u{f0311} TeX"
                        color: win.theme.muted
                        font.family: win.theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: win.calcReady
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: win.selectedIndex = -1
                        onClicked: mouse => {
                            win.selectedIndex = -1;
                            win.accept(mouse.modifiers & Qt.ShiftModifier);
                        }
                    }
                }

                ListView {
                    id: list

                    readonly property int rowHeight: 36
                    readonly property int rowSpacing: 4
                    readonly property int rowsShown: Math.min(win.results.length, 9)

                    width: parent.width - 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: list.rowsShown * list.rowHeight
                            + Math.max(0, list.rowsShown - 1) * list.rowSpacing
                    spacing: list.rowSpacing
                    visible: win.results.length > 0
                    clip: true
                    model: win.results
                    currentIndex: win.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: rowDel
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: list.rowHeight
                        radius: win.theme.radiusSmall
                        antialiasing: true
                        color: index === win.selectedIndex ? win.theme.pillHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                visible: !!rowDel.modelData.entry && source.toString().length > 0
                                source: rowDel.modelData.entry
                                        ? (Quickshell.iconPath(rowDel.modelData.entry.icon, true) || "")
                                        : ""
                                sourceSize.width: 40
                                sourceSize.height: 40
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            Text {
                                text: rowDel.modelData.text
                                color: win.theme.text
                                font.family: win.theme.fontFamily
                                font.pixelSize: 13
                                font.bold: rowDel.index === win.selectedIndex
                                elide: Text.ElideRight
                                Layout.maximumWidth: 380
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                visible: !!rowDel.modelData.sub
                                text: rowDel.modelData.sub
                                color: win.theme.muted
                                font.family: win.theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.maximumWidth: 210
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: win.selectedIndex = rowDel.index
                            onClicked: {
                                win.selectedIndex = rowDel.index;
                                win.accept();
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: visible ? 40 : 0
                    visible: win.results.length === 0 && win.query.trim().length > 0 && win.mode === "apps" && !win.calc
                    Text {
                        anchors.centerIn: parent
                        text: "No matching applications"
                        color: win.theme.muted
                        font.family: win.theme.fontFamily
                        font.pixelSize: 12
                    }
                }

                Item {
                    width: parent.width
                    height: list.visible || calcCard.visible ? 6 : 0
                }
            }
        }

        component Fillet: Item {
            id: fillet
            required property int corner
            readonly property int r: Math.max(0, Math.min(win.theme.joinRadius, panel.height + panel.y))

            y: 0
            width: fillet.r
            height: fillet.r
            visible: fillet.r > 0

            CornerWedge {
                corner: fillet.corner
                wedgeRadius: fillet.r
                wedgeColor: panel.color
            }
        }

        Fillet {
            corner: 1
            x: panel.x - width
        }
        Fillet {
            corner: 0
            x: panel.x + panel.width
        }
    }
}
