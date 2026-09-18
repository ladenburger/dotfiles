import QtQuick

Item {
    id: root

    required property Theme theme
    required property var cut
    required property real fit
    required property real originX
    required property real originY

    readonly property var kyotoWall: ({

        levels: [

            { percent: 0,   y: 1514, slope: -0.0466 },
            { percent: 25,  y: 1396 },
            { percent: 50,  y: 1267 },
            { percent: 75,  y: 1140 },
            { percent: 100, y: 1014 }
        ],

        slope: -0.024,

        slats: [
            { y: 131.75, slope:  0.000 },
            { y: 261.25, slope: -0.004 },
            { y: 387.00, slope: -0.005 },
            { y: 512.75, slope: -0.015 }
        ],
        mediaBand: 1,
        controlsBand: 2,

        lean: 0.024,
        left: 2060,
        right: 2545,
        gap: 0.3,
        labelRight: 2040,
        labelSize: 24
    })

    readonly property var walls: ({
        "6qic3ilgnw0a1.png": root.kyotoWall,
        "31-hard-gruvbox.png": root.kyotoWall
    })

    readonly property string wallpaper:
        (root.cut && root.cut.source) ? root.cut.source.split("/").pop() : ""
    readonly property var geo: root.walls[root.wallpaper] ?? null

    function sx(x: real): real { return root.originX + x * root.fit; }
    function sy(y: real): real { return root.originY + y * root.fit; }

    function slatY(slat: var, x: real): real {
        return slat.y + slat.slope * (x - root.geo.left);
    }

    function tiltDeg(slope: real): real {
        return Math.atan(slope) * 180 / Math.PI;
    }

    readonly property real leanDeg: root.geo
        ? -Math.atan(root.geo.lean) * 180 / Math.PI : 0

    function leanX(percent: real, x: real): real {
        return root.geo.lean * (root.levelY(percent, x) - root.levelY(0, x));
    }

    function levelY(percent: real, x: real): real {
        const ls = root.geo.levels;
        let i = 0;
        while (i < ls.length - 2 && percent > ls[i + 1].percent) i++;
        const a = ls[i], b = ls[i + 1];
        const t = (percent - a.percent) / (b.percent - a.percent);
        const sa = a.slope ?? root.geo.slope;
        const sb = b.slope ?? root.geo.slope;
        return a.y + (b.y - a.y) * t
             + (sa + (sb - sa) * t) * (x - root.geo.left);
    }

    function bandX(i: int): real { return root.sx(root.geo.left); }
    function bandY(i: int): real { return root.sy(root.geo.slats[i].y); }
    function bandW(i: int): real {
        return (root.geo.right - root.geo.left) * root.fit;
    }
    function bandH(i: int): real {
        return (root.geo.slats[i + 1].y - root.geo.slats[i].y) * root.fit;
    }
    function bandTilt(i: int): real {
        return root.tiltDeg(root.geo.slats[i].slope);
    }

    readonly property rect hits: media.hits

    DesktopVisualizer {
        anchors.fill: parent
        theme: root.theme
        wall: root
    }

    DesktopMedia {
        id: media
        anchors.fill: parent
        theme: root.theme
        wall: root
    }
}
