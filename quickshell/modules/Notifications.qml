pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false

    onCenterOpenChanged: if (centerOpen) popups.clear()

    property bool sound: true
    readonly property string soundDir: "/usr/share/sounds/freedesktop/stereo/"
    property real _lastSound: 0
    function toggleSound() { root.sound = !root.sound }

    readonly property Theme theme: Theme {}

    readonly property ListModel popups: ListModel {}
    property var _byId: ({})
    property var _times: ({})
    property int _seq: 0

    signal arrived

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        persistenceSupported: true

        onNotification: notification => root._onNotification(notification)
    }

    readonly property int historyCount: server.trackedNotifications ? server.trackedNotifications.values.length : 0

    function _onNotification(n) {
        n.tracked = true;
        root._times[n.id] = Date.now();
        root.arrived();

        const critical = n.urgency === NotificationUrgency.Critical;
        if (root.dnd && !critical)
            return;

        root._playSound(n, critical);

        const sid = ++root._seq;
        root._byId[sid] = n;
        root.popups.append({ sid: sid });

        try {
            n.closed.connect(function() {
                root._removeByNotif(n);
                delete root._times[n.id];
            });
        } catch (e) {

        }
    }

    function _playSound(n, critical) {
        if (!root.sound)
            return;
        const h = n.hints || ({});
        if (h["suppress-sound"])
            return;

        const now = Date.now();
        if (now - root._lastSound < 400)
            return;
        root._lastSound = now;

        let file;
        if (h["sound-file"])
            file = String(h["sound-file"]).replace(/^file:\/\//, "");
        else if (h["sound-name"])
            file = root.soundDir + String(h["sound-name"]) + ".oga";
        else
            file = root.soundDir + (critical ? "dialog-warning.oga" : "message.oga");

        Quickshell.execDetached(["paplay", file]);
    }

    function notif(sid) {
        return root._byId[sid] ?? null;
    }

    function timeOf(n) {
        return root._times[n.id] ?? Date.now();
    }

    function dropPopup(sid) {
        for (let i = 0; i < root.popups.count; i++) {
            if (root.popups.get(i).sid === sid) {
                delete root._byId[sid];
                root.popups.remove(i);
                return;
            }
        }
    }

    function _removeByNotif(n) {
        for (let i = 0; i < root.popups.count; i++) {
            const sid = root.popups.get(i).sid;
            if (root._byId[sid] === n) {
                delete root._byId[sid];
                root.popups.remove(i);
                return;
            }
        }
    }

    function dismiss(n) {
        if (n) n.dismiss();
    }

    function clearAll() {
        const all = server.trackedNotifications ? [...server.trackedNotifications.values] : [];
        for (const n of all) n.dismiss();
    }

    function invokeAction(n, action) {
        action.invoke();
        if (n && !n.resident)
            n.dismiss();
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }
}
