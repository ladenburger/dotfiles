pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var values: []

    property bool quiet: true
    property int quietMs: 1200

    readonly property real attack: 0.55
    readonly property real release: 0.10

    property int listeners: 0

    readonly property int firstWait: 2000
    readonly property int maxWait: 60000
    property int wait: root.firstWait

    function _clear(): void {
        root.values = [];
        root.quiet = true;
    }

    Process {
        id: proc

        running: false
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]

        onExited: {
            root._clear();
            if (root.listeners > 0) {
                retry.interval = root.wait;
                retry.restart();
                root.wait = Math.min(root.maxWait, root.wait * 2);
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: frame => {
                const bars = [];
                let peak = 0;
                for (const field of frame.split(";")) {
                    if (field === "") continue;
                    const v = Number(field);
                    if (isNaN(v)) continue;
                    bars.push(v);
                    if (v > peak) peak = v;
                }
                if (bars.length === 0) return;

                const was = root.values;
                const carry = was.length === bars.length;
                const eased = [];
                for (let i = 0; i < bars.length; i++) {
                    const from = carry ? was[i] : 0;
                    const k = bars[i] > from ? root.attack : root.release;
                    eased.push(from + (bars[i] - from) * k);
                }

                root.values = eased;
                root.wait = root.firstWait;
                if (peak > 0) {
                    root.quiet = false;
                    hush.restart();
                }
            }
        }
    }

    Timer {
        id: hush
        interval: root.quietMs
        onTriggered: root.quiet = true
    }

    Timer {
        id: retry
        onTriggered: if (root.listeners > 0) proc.running = true
    }

    onListenersChanged: {
        if (root.listeners > 0) {
            proc.running = true;
        } else {
            retry.stop();
            proc.running = false;
            root.wait = root.firstWait;
            root._clear();
        }
    }
}
