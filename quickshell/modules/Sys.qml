pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPerc: 0
    property var loadAvg: [0, 0, 0]

    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real memPerc: 0

    property real tempC: -1
    readonly property bool tempCritical: root.tempC >= 80

    property var _prevCpu: null

    function _parse(out) {
        const lines = out.split("\n");
        for (const line of lines) {
            if (line.startsWith("cpu ")) {
                const f = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0);
                const total = f.reduce((a, b) => a + b, 0);
                if (root._prevCpu) {
                    const dTotal = total - root._prevCpu.total;
                    const dIdle = idle - root._prevCpu.idle;
                    if (dTotal > 0)
                        root.cpuPerc = Math.max(0, Math.min(100, (1 - dIdle / dTotal) * 100));
                }
                root._prevCpu = { total: total, idle: idle };
            } else if (line.startsWith("MemTotal:")) {
                root.memTotalGiB = parseFloat(line.split(/\s+/)[1]) / 1048576;
            } else if (line.startsWith("MemAvailable:")) {
                const availGiB = parseFloat(line.split(/\s+/)[1]) / 1048576;
                root.memUsedGiB = Math.max(0, root.memTotalGiB - availGiB);
                root.memPerc = root.memTotalGiB > 0 ? root.memUsedGiB / root.memTotalGiB * 100 : 0;
            } else if (line.startsWith("TEMP=")) {
                const milli = parseFloat(line.slice(5));
                root.tempC = isNaN(milli) ? -1 : Math.round(milli / 1000);
            } else if (line.startsWith("LOAD=")) {
                root.loadAvg = line.slice(5).trim().split(/\s+/).slice(0, 3).map(Number);
            }
        }
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "grep '^cpu ' /proc/stat; grep -E 'MemTotal|MemAvailable' /proc/meminfo; " +
            "echo LOAD=$(cut -d' ' -f1-3 /proc/loadavg); " +
            "for h in /sys/class/hwmon/hwmon*; do n=$(cat \"$h/name\" 2>/dev/null); " +
            "case \"$n\" in coretemp|k10temp|zenpower|cpu_thermal) echo TEMP=$(cat \"$h/temp1_input\" 2>/dev/null); break;; esac; done; " +
            "[ -z \"$n\" ] && echo TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) || true"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
