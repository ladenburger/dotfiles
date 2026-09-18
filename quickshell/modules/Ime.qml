import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property Theme theme
    required property var screen

    readonly property bool japanese: InputState.isJapanese(InputState.im)

    readonly property bool onFocusedScreen: {
        const fm = Hyprland.focusedMonitor;
        return !!(fm && root.screen && fm.name === root.screen.name);
    }

    readonly property string pillLabel: {
        const name = InputState.im;
        if (root.japanese) return "JP";
        if (InputState.isLatin(name)) return InputState.layoutTag();
        return InputState.imName(name);
    }

    function publish() {
        LangState.anchorScreen = root.screen ? root.screen.name : "";
        LangState.anchorX = root.mapToItem(null, root.width / 2, 0).x;
    }

    function show(selfClosing) {
        InputState.refreshGroup();
        root.publish();
        LangState.show(selfClosing);
    }

    visible: InputState.imUp
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Connections {
        target: InputState

        function onSwitched() {
            if (InputState.selfSwitch) return;
            if (!LangState.armed || !root.onFocusedScreen) return;
            root.show(true);
        }
    }

    Pill {
        id: pill
        theme: root.theme
        icon: InputState.glyph(InputState.im)
        label: root.pillLabel
        iconColor: root.japanese ? root.theme.highlight : root.theme.lang
        labelColor: root.japanese ? root.theme.text : root.theme.subtext
        active: LangState.open && root.onFocusedScreen
        onClicked: InputState.cycleQuietly(1)
        onRightClicked: {
            if (LangState.open && !LangState.autoClose) {
                LangState.hide();
            } else {
                root.show(false);
            }
        }
        onWheel: delta => InputState.cycleQuietly(delta > 0 ? -1 : 1)
    }
}
