import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property color bg: "#ff1d2021"
    readonly property color solidBg: "#f2282828"
    readonly property color frame: "#ff0f1112"
    readonly property color pill: "#d93c3836"
    readonly property color pillHover: "#e64a4440"
    readonly property color text: "#ebdbb2"
    readonly property color subtext: "#a89984"
    readonly property color muted: "#7c6f64"
    readonly property color network: "#8ec07c"
    readonly property color bluetooth: "#83a598"
    readonly property color good: "#b8bb26"
    readonly property color warn: "#fabd2f"
    readonly property color critical: "#fb4934"
    readonly property color criticalBg: "#cc241d"
    readonly property color highlight: "#e8c597"
    readonly property color distro: "#d79921"
    readonly property color cpu: "#fb4934"
    readonly property color mem: "#fabd2f"
    readonly property color temp: "#fe8019"
    readonly property color lang: "#d3869b"
    readonly property color audio: "#83a598"
    readonly property color shadow: "#aa1d2021"

    readonly property color border: highlight
    readonly property color borderDim: muted

    readonly property string fontFamily: "ZedMono Nerd Font"

    readonly property string cjkFontFamily: "Noto Sans CJK JP"

    readonly property int durFast: 120
    readonly property int durMed: 210
    readonly property int durSlow: 340
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack
    readonly property real overshoot: 1.7

    readonly property int barHeight: 36
    readonly property int barMargin: 12

    readonly property int barBottom: barHeight

    readonly property real barWidthRatio: 0.72
    readonly property int barMinWidth: 640
    readonly property int barGroupGap: 16
    readonly property int barRadius: 12
    readonly property int radius: 10
    readonly property int radiusSmall: 6
    readonly property int pillHeight: 26

    readonly property int screenRadius: 14

    readonly property int frameRadius: 26
    readonly property int frameEdge: 6

    readonly property int joinRadius: 24

    function islandWidth(screenWidth) {
        return Math.round(Math.min(screenWidth - 2 * barMargin,
                                   Math.max(barMinWidth,
                                            screenWidth * barWidthRatio)));
    }
}
