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

    // Calculator cheat sheet, toggled by the ƒ(x) button or F1.
    property bool showMathHelp: false
    readonly property var mathHelp: [
        { title: "Basics", rows: [
            ["+  -  *  /", "arithmetic", "2*(3+4)/7"],
            ["^  **", "power", "2^10"],
            ["!", "factorial", "6!"],
            ["mod  %", "remainder", "17 mod 5"],
            ["|x|  abs(x)", "absolute value", "|-3.5|"],
            ["2pi  3(4+1)", "implicit multiplication", "2pi"]
        ] },
        { title: "Fractions", rows: [
            ["1/3 + 1/4", "exact fraction result", "1/3 + 1/4"],
            ["3 1/2", "mixed number (space between)", "3 1/2 + 1/4"],
            ["0.125 + 0.5", "decimals shown as fractions", "0.125 + 0.5"],
            ["\\frac{a}{b}", "LaTeX fraction", "\\frac{22}{7}"]
        ] },
        { title: "Roots & powers", rows: [
            ["sqrt(x)", "square root", "sqrt(72)"],
            ["cbrt(x)", "cube root", "cbrt(27)"],
            ["root(x, n)", "n-th root", "root(32, 5)"],
            ["exp(x)  e^x", "exponential", "exp(1)"],
            ["hypot(a, b, …)", "sqrt(a^2 + b^2 + …)", "hypot(3, 4)"]
        ] },
        { title: "Logarithms", rows: [
            ["ln(x)", "natural log", "ln(e^3)"],
            ["log(x)  lg(x)", "base 10", "log(1000)"],
            ["log2(x)", "base 2", "log2(1024)"],
            ["log_b x", "any base", "log_3 81"]
        ] },
        { title: "Trigonometry (radians)", rows: [
            ["sin cos tan", "basic trig", "sin(pi/6)"],
            ["sec csc cot", "reciprocal trig", "sec(pi/3)"],
            ["asin acos atan", "inverse (arcsin… too)", "atan(1)"],
            ["sinh cosh tanh", "hyperbolic", "cosh(0)"],
            ["asinh acosh atanh", "inverse hyperbolic", "asinh(1)"],
            ["deg(x)  rad(x)", "radians→degrees / degrees→radians", "sin(rad(30))"]
        ] },
        { title: "Integers & combinatorics", rows: [
            ["gcd(a, b, …)", "greatest common divisor", "gcd(84, 36)"],
            ["lcm(a, b, …)", "least common multiple", "lcm(4, 6, 10)"],
            ["nCr(n, k)  binom", "combinations", "nCr(49, 6)"],
            ["nPr(n, k)", "permutations", "nPr(10, 3)"],
            ["mod(a, b)", "remainder (function form)", "mod(-7, 3)"]
        ] },
        { title: "Rounding & lists", rows: [
            ["floor ceil round", "round down / up / nearest", "floor(7/2)"],
            ["trunc(x)", "drop the decimals", "trunc(-2.7)"],
            ["sgn(x)", "sign: −1, 0 or 1", "sgn(-4)"],
            ["min max", "smallest / largest", "max(3, 9, 4)"],
            ["sum mean avg", "total / average", "mean(2, 3, 7)"]
        ] },
        { title: "Constants", rows: [
            ["pi", "3.14159…", "=pi"],
            ["tau", "2·pi", "=tau"],
            ["e", "2.71828…", "=e"],
            ["phi", "golden ratio", "=phi"]
        ] },
        { title: "Results", rows: [
            ["Enter", "copy the result", ""],
            ["Shift+Enter", "copy as LaTeX", ""],
            ["=…", "force calculation", "=pi"]
        ] }
    ]
    function insertExample(ex) {
        if (!ex)
            return;
        input.text = ex;
        input.cursorPosition = ex.length;
        input.forceActiveFocus();
    }

    readonly property var calc: win.mode === "apps" ? Calc.analyse(win.query) : null
    readonly property bool calcReady: !!win.calc && win.calc.hasValue

    onQueryChanged: win.selectedIndex = win.calcReady ? -1 : 0

    // Hover only selects when the pointer really moves. Qt also sends hover
    // events when results change or scroll under a stationary cursor, and
    // those would override the "first entry" reset after typing.
    property point _lastPointer: Qt.point(-1, -1)
    function hoverSelect(item, mouse, index) {
        const p = item.mapToItem(null, mouse.x, mouse.y);
        if (p.x === win._lastPointer.x && p.y === win._lastPointer.y)
            return;
        win._lastPointer = p;
        win.selectedIndex = index;
    }
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
        if (!shown) {
            closeHold.restart();
        } else {
            // Help never carries over between openings. Cleared on open, not
            // on close, so the panel doesn't jump in height mid-slide.
            win.showMathHelp = false;
            Qt.callLater(input.forceActiveFocus);
        }
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
                            right: helpBtn.visible ? helpBtn.left : parent.right
                            rightMargin: helpBtn.visible ? 8 : 14
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
                            case Qt.Key_Shift:
                            case Qt.Key_Control:
                            case Qt.Key_Alt:
                            case Qt.Key_Meta:
                            case Qt.Key_Super_L:
                            case Qt.Key_Super_R:
                                break;
                            default:
                                edgeGlow.flash();
                            }
                            switch (event.key) {
                            case Qt.Key_F1:
                                if (win.mode === "apps")
                                    win.showMathHelp = !win.showMathHelp;
                                event.accepted = true;
                                break;
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

                    Rectangle {
                        id: helpBtn
                        anchors {
                            right: parent.right
                            rightMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        width: 30
                        height: 30
                        radius: win.theme.radiusSmall
                        antialiasing: true
                        visible: win.mode === "apps"
                        color: win.showMathHelp || helpMouse.containsMouse ? win.theme.pillHover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: win.theme.durFast }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u{f0871}"
                            color: win.showMathHelp ? win.theme.highlight
                                 : helpMouse.containsMouse ? win.theme.text : win.theme.subtext
                            font.family: win.theme.fontFamily
                            font.pixelSize: 17
                        }

                        MouseArea {
                            id: helpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.showMathHelp = !win.showMathHelp;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: win.theme.border
                    opacity: 0.4
                    visible: list.visible || calcCard.visible || mathHelp.visible
                }

                Item {
                    width: parent.width
                    height: list.visible || calcCard.visible || mathHelp.visible ? 6 : 0
                }

                Flickable {
                    id: mathHelp
                    width: parent.width
                    visible: win.showMathHelp && win.mode === "apps"
                    // Leave room for the calc card / results when something is typed.
                    height: visible ? Math.min(helpCol.implicitHeight, win.query.trim().length ? 200 : 440) : 0
                    contentHeight: helpCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: helpCol
                        width: parent.width
                        bottomPadding: 6

                        Repeater {
                            model: win.mathHelp

                            Column {
                                id: helpSection
                                required property var modelData
                                width: helpCol.width

                                Text {
                                    leftPadding: 20
                                    topPadding: 8
                                    bottomPadding: 4
                                    text: helpSection.modelData.title
                                    color: win.theme.highlight
                                    font.family: win.theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Repeater {
                                    model: helpSection.modelData.rows

                                    Rectangle {
                                        id: helpRow
                                        required property var modelData
                                        readonly property bool clickable: helpRow.modelData[2].length > 0

                                        x: 6
                                        width: helpSection.width - 12
                                        height: 26
                                        radius: win.theme.radiusSmall
                                        antialiasing: true
                                        color: rowMouse.containsMouse && helpRow.clickable ? win.theme.pillHover : "transparent"

                                        Text {
                                            id: helpSyntax
                                            anchors {
                                                left: parent.left
                                                leftMargin: 14
                                                verticalCenter: parent.verticalCenter
                                            }
                                            width: 170
                                            text: helpRow.modelData[0]
                                            color: win.theme.text
                                            font.family: win.theme.fontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            anchors {
                                                left: helpSyntax.right
                                                leftMargin: 10
                                                right: helpEx.left
                                                rightMargin: 10
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: helpRow.modelData[1]
                                            color: win.theme.subtext
                                            font.family: win.theme.fontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            id: helpEx
                                            anchors {
                                                right: parent.right
                                                rightMargin: 14
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: helpRow.modelData[2]
                                            color: rowMouse.containsMouse ? win.theme.highlight : win.theme.muted
                                            font.family: win.theme.fontFamily
                                            font.pixelSize: 11
                                        }

                                        MouseArea {
                                            id: rowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: helpRow.clickable
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: win.insertExample(helpRow.modelData[2])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: mathHelp.visible && (list.visible || calcCard.visible) ? 6 : 0
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
                        onPositionChanged: mouse => win.hoverSelect(calcCard, mouse, -1)
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
                            onPositionChanged: mouse => win.hoverSelect(rowDel, mouse, rowDel.index)
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
                    height: list.visible || calcCard.visible || mathHelp.visible ? 6 : 0
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

        // Accent outline tracing the launcher's silhouette: down the left wedge
        // curve, the left side, the rounded bottom, the right side and up the
        // right wedge curve. It's transparent at the bar's edge and fades in
        // along the wedges, so the bar → launcher join has no hard line.
        // Keystrokes make it flash.
        Canvas {
            id: edgeGlow

            readonly property real lineWidth: 2
            readonly property real restOpacity: 0.3
            // Same radius the Fillet wedges use.
            readonly property int joinR: Math.max(0, Math.min(win.theme.joinRadius, panel.height + panel.y))

            x: panel.x - edgeGlow.joinR
            y: 0
            width: panel.width + 2 * edgeGlow.joinR
            height: Math.max(0, panel.y + panel.height)
            visible: panel.width > 0 && edgeGlow.height > 0
            opacity: edgeGlow.restOpacity

            function flash() {
                flashAnim.restart();
            }

            SequentialAnimation {
                id: flashAnim
                NumberAnimation {
                    target: edgeGlow
                    property: "opacity"
                    to: 1
                    duration: 50
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: edgeGlow
                    property: "opacity"
                    to: edgeGlow.restOpacity
                    duration: 520
                    easing.type: Easing.OutCubic
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onJoinRChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const lw = edgeGlow.lineWidth, J = edgeGlow.joinR;
                const w = width, h = height;
                if (w - 2 * J < 2 * lw || h < 2 * lw)
                    return;

                const c = win.theme.highlight;
                const rgba = a => "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
                                 + Math.round(c.b * 255) + "," + a + ")";
                // Transparent at the bar edge, fully lit just below the wedges.
                const g = ctx.createLinearGradient(0, 0, 0, h);
                g.addColorStop(0, rgba(0));
                g.addColorStop(Math.min(0.9, (J + 16) / h), rgba(1));
                g.addColorStop(1, rgba(1));

                // Panel sides sit lw/2 inside the panel; the wedge arcs are
                // concentric with the wedges, so they meet the sides smoothly.
                const xl = J + lw / 2, xr = w - J - lw / 2, yb = h - lw / 2;
                const R = J + lw / 2;
                const br = Math.max(0, Math.min(win.theme.radius - lw / 2, (xr - xl) / 2, yb - J));

                ctx.beginPath();
                if (J > 0) {
                    ctx.moveTo(0, J - R);
                    ctx.arc(0, J, R, -Math.PI / 2, 0, false);
                } else {
                    ctx.moveTo(xl, 0);
                }
                ctx.lineTo(xl, yb - br);
                ctx.arcTo(xl, yb, xl + br, yb, br);
                ctx.lineTo(xr - br, yb);
                ctx.arcTo(xr, yb, xr, yb - br, br);
                if (J > 0) {
                    ctx.lineTo(xr, J);
                    ctx.arc(w, J, R, Math.PI, Math.PI * 1.5, false);
                } else {
                    ctx.lineTo(xr, 0);
                }
                ctx.strokeStyle = g;
                ctx.lineWidth = lw;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }
}
