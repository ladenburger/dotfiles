import QtQuick
import "math.js" as Calc

Canvas {
    id: view

    required property var tree
    required property Theme theme
    property real fontSize: 22

    property real maxWidth: 10000

    readonly property string family: {
        const have = Qt.fontFamilies();
        for (const f of ["Latin Modern Roman", "CMU Serif", "STIX Two Text", "Libertinus Serif", "Noto Serif"])
            if (have.indexOf(f) >= 0)
                return f;
        return "serif";
    }

    property var _box: null
    readonly property int _pad: 3

    implicitWidth: _box ? Math.ceil(_box.w) + 2 * _pad : 0
    implicitHeight: _box ? Math.ceil(_box.a + _box.d) + 2 * _pad : 0

    function relayout() {
        if (!view.available || !view.tree) {
            view._box = null;
            view.requestPaint();
            return;
        }
        const ctx = view.getContext("2d");
        const measure = (font, text) => {
            ctx.font = font;
            return ctx.measureText(text).width;
        };
        let box = Calc.layout(view.tree, measure, view.fontSize, view.family);
        const room = view.maxWidth - 2 * view._pad;
        if (box.w > room)
            box = Calc.layout(view.tree, measure, Math.max(11, view.fontSize * room / box.w), view.family);
        view._box = box;
        view.requestPaint();
    }

    onTreeChanged: relayout()
    onAvailableChanged: relayout()
    onMaxWidthChanged: relayout()
    onFamilyChanged: relayout()
    onPaint: _paint()

    function _color(role) {
        switch (role) {
        case "result": return view.theme.highlight;
        case "rel": return view.theme.subtext;
        case "dim": return view.theme.muted;
        }
        return view.theme.text;
    }

    function _paint() {
        const ctx = view.getContext("2d");
        ctx.reset();
        const box = view._box;
        if (!box)
            return;
        ctx.save();
        ctx.translate(view._pad, view._pad + box.a);
        ctx.textBaseline = "alphabetic";
        for (const o of box.ops) {
            const col = view._color(o.role);
            switch (o.op) {
            case "text":
                ctx.font = o.font;
                ctx.fillStyle = col;
                ctx.fillText(o.s, o.x, o.y);
                break;
            case "fill":
                ctx.fillStyle = col;
                ctx.fillRect(o.x, o.y, o.w, o.h);
                break;
            case "rect":
                ctx.strokeStyle = col;
                ctx.lineWidth = o.lw;
                ctx.strokeRect(o.x, o.y, o.w, o.h);
                break;
            case "line":
                ctx.strokeStyle = col;
                ctx.lineWidth = o.lw;
                ctx.lineJoin = o.square ? "miter" : "round";
                ctx.lineCap = o.square ? "square" : "round";
                ctx.beginPath();
                ctx.moveTo(o.pts[0][0], o.pts[0][1]);
                for (let i = 1; i < o.pts.length; i++)
                    ctx.lineTo(o.pts[i][0], o.pts[i][1]);
                ctx.stroke();
                break;
            case "paren": {

                const p = o.pts;
                ctx.fillStyle = col;
                ctx.beginPath();
                ctx.moveTo(p[0][0], p[0][1]);
                ctx.quadraticCurveTo(p[1][0], p[1][1], p[2][0], p[2][1]);
                ctx.quadraticCurveTo(p[3][0], p[3][1], p[0][0], p[0][1]);
                ctx.fill();
                break;
            }
            }
        }
        ctx.restore();
    }

    Connections {
        target: view.theme
        function onNameChanged() { view.requestPaint(); }
    }
}
