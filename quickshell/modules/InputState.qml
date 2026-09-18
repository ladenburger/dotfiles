pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var layouts: []
    property string layout: ""

    property bool imUp: false

    property var methods: []
    property string im: ""

    signal switched()

    function isLatin(name) {
        return name.length === 0 || name.startsWith("keyboard-");
    }

    readonly property var jaMethods: ["mozc", "anthy", "kkc", "skk"]

    function isJapanese(name) {
        return root.jaMethods.indexOf(name) >= 0;
    }

    readonly property string latinGlyph: "\u{f030c}"

    function glyph(name) {
        if (root.isJapanese(name)) return "あ";
        if (root.isLatin(name)) return root.latinGlyph;
        const e = root.entry(name);
        return (e ? e.display : name).slice(0, 2);
    }

    function entry(name) {
        return root.methods.find(e => e.name === name) ?? null;
    }

    readonly property var endonyms: ({
        "German": "Deutsch",
        "German (no dead keys)": "Deutsch (ohne Akzenttasten)"
    })

    function imName(name) {
        if (root.isJapanese(name)) return "日本語";
        const e = root.entry(name);
        const label = (e ? e.display : name).replace(/^Keyboard - /, "");
        return root.endonyms[label] ?? label;
    }

    function layoutTag() {
        const code = root.layoutOfIm(root.im);
        return (code.length > 0 ? code : root.layout).toUpperCase();
    }

    function shortenLayout(name) {
        const map = {
            "English (US)": "us",
            "English (UK)": "gb",
            "German": "de",
            "German (no dead keys)": "de",
            "French": "fr",
            "Spanish": "es",
            "Russian": "ru"
        };
        if (map[name]) return map[name];
        const m = name.match(/\(([A-Za-z]{2})/);
        if (m) return m[1].toLowerCase();
        return name.slice(0, 2).toLowerCase();
    }

    function setLayout(code) {
        if (code.length === 0 || code === root.layout) return;
        root.layout = code;
        root.syncImToLayout();
    }

    function setIm(name) {
        if (name.length === 0 || name === root.im) return;
        root.im = name;
        root.switched();
    }

    property string pending: ""

    Timer {
        id: pendingTimer
        interval: 1500
        onTriggered: root.pending = ""
    }

    function selectIm(name) {
        if (name.length === 0 || name === root.im) return;
        root.setIm(name);
        root.syncLayoutToIm();
        root.tell(name);
    }

    function reassert() {
        if (root.im.length === 0) return;
        root.tell(root.im);
    }

    function tell(name) {
        root.pending = name;
        pendingTimer.restart();
        setter.running = false;
        setter.command = ["fcitx5-remote", "-s", name];
        setter.running = true;
    }

    function refreshGroup() {
        if (!group.running) group.running = true;
    }

    function layoutOfIm(name) {
        if (!name.startsWith("keyboard-")) return "";
        return name.slice("keyboard-".length).split("-")[0];
    }

    function imForLayout(code) {
        const hit = root.methods.find(e => root.layoutOfIm(e.name) === code);
        return hit ? hit.name : "";
    }

    readonly property string imeLayout: "us"

    function layoutForIm(name) {
        const code = root.layoutOfIm(name);
        return code.length > 0 ? code : root.imeLayout;
    }

    function syncImToLayout() {
        if (!root.imUp || root.layout.length === 0) return;
        if (root.layoutOfIm(root.im).length === 0) return;
        root.selectIm(root.imForLayout(root.layout));
    }

    function syncLayoutToIm() {
        const code = root.layoutForIm(root.im);
        if (code.length === 0 || code === root.layout) return;
        const i = root.layouts.indexOf(code);
        if (i < 0) return;
        layoutSetter.running = false;
        layoutSetter.command = ["hyprctl", "switchxkblayout", "all", String(i)];
        layoutSetter.running = true;
    }

    Process { id: layoutSetter }

    function cycleIm(step) {
        const list = root.methods;
        if (list.length < 2) return;
        const i = list.findIndex(e => e.name === root.im);
        root.selectIm(list[((i < 0 ? 0 : i) + step + list.length) % list.length].name);
    }

    property bool selfSwitch: false

    function cycleQuietly(step) {
        root.selfSwitch = true;
        root.cycleIm(step);
        root.selfSwitch = false;
    }

    GlobalShortcut {
        name: "imcycle"
        description: "Cycle fcitx5 input method (US / DE / Japanese)"
        onPressed: root.cycleIm(1)
    }

    IpcHandler {
        target: "im"
        function next(): void { root.cycleIm(1) }
        function prev(): void { root.cycleIm(-1) }
        function select(name: string): void { root.selectIm(name) }
        function status(): string { return root.im + " " + root.layout }
    }

    function isVirtualKeyboard(device) {
        return device.startsWith("hl-virtual-keyboard");
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            if (parts.length < 2 || root.isVirtualKeyboard(parts[0])) return;
            root.setLayout(root.shortenLayout(parts[parts.length - 1]));
        }
    }

    Process {
        id: layoutList
        running: true
        command: ["hyprctl", "getoption", "input:kb_layout", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const str = JSON.parse(this.text).str ?? "";
                    root.layouts = str.split(",").map(s => s.trim()).filter(s => s.length > 0);
                } catch (e) {}
            }
        }
    }

    Process {
        id: layoutSeed
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = (JSON.parse(this.text).keyboards ?? [])
                        .filter(k => !root.isVirtualKeyboard(k.name));
                    const main = kb.find(k => k.main) ?? kb[0];
                    if (main && main.active_keymap)
                        root.layout = root.shortenLayout(main.active_keymap);
                } catch (e) {}
            }
        }
    }

    Process { id: setter }

    Process {
        id: watcher
        running: true
        command: ["sh", "-c",
            "prev=; while :; do " +
            "if fcitx5-remote >/dev/null 2>&1; then " +
            "line=\"up $(fcitx5-remote -n 2>/dev/null)\"; else line=down; fi; " +
            "if [ \"$line\" != \"$prev\" ]; then printf '%s\\n' \"$line\"; prev=$line; fi; " +
            "sleep 0.3; done"]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim();
                root.imUp = s.startsWith("up");
                if (!root.imUp) return;
                const name = s.slice(2).trim();
                if (name.length === 0) return;
                if (root.pending.length > 0) {
                    if (name !== root.pending) return;
                    root.pending = "";
                    pendingTimer.stop();
                }
                if (!root.methods.some(e => e.name === name)) root.refreshGroup();
                if (name === root.im) return;

                const known = root.methods.some(e => e.name === root.im);
                if (root.im.length === 0 || !known) {
                    root.setIm(name);
                    root.syncLayoutToIm();
                    return;
                }
                root.reassert();
            }
        }
    }

    Process {
        id: group
        running: true
        command: ["gdbus", "call", "--session", "--dest", "org.fcitx.Fcitx5",
            "--object-path", "/controller",
            "--method", "org.fcitx.Fcitx.Controller1.FullInputMethodGroupInfo", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const start = this.text.indexOf("[(");
                if (start < 0) return;
                const re = /\('([^'\\]*)', '((?:[^'\\]|\\.)*)'/g;
                const out = [];
                let m;
                while ((m = re.exec(this.text.slice(start))) !== null)
                    out.push({ name: m[1], display: m[2].replace(/\\'/g, "'") });
                if (out.length > 0) root.methods = out;
            }
        }
    }
}
