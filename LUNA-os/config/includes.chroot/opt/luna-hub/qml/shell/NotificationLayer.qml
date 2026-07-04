import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: layer

    property int maxToasts: 6

    function push(notif) {
        if (model.count >= maxToasts) model.remove(0)
        var t = component.createObject(null, { "title": notif.title, "message": notif.message || "", "tone": notif.tone !== undefined ? notif.tone : 1, "durationMs": notif.durationMs || 3200 })
        t.dismissed.connect(function() { t.destroy() })
        t.parent = layer
        t.width = layer.width
        t.height = 76
        var idx = layout.children.length
        layout.addItem(t)
        t.present()
    }

    ListModel { id: model }

    Component {
        id: component
        LunaToast {}
    }

    Column {
        id: layout
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        spacing: Metrics.xs8
    }
}
