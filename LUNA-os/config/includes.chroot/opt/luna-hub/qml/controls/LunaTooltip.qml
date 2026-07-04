import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Popup {
    id: control

    property string text: ""
    property int sideMargin: Metrics.xs8
    property int maxWidth_: 240
    enum Side { Auto, Top, Bottom, Left, Right }

    parent: Overlay.overlay
    padding: Metrics.xs8
    visible: false
    closePolicy: Popup.NoAutoClose
    opacity: 1.0

    background: Rectangle {
        radius: Metrics.radiusMd
        color: Theme.tooltipBg
        border.width: Metrics.strokeHairline
        border.color: Theme.borderHover
    }

    contentItem: Label {
        text: control.text
        color: Theme.textSecondary
        wrapMode: Text.WordWrap
        font.family: Typography.family
        font.pixelSize: Typography.caption.size
        font.weight: Typography.caption.weight
    }

    function position(target) {
        if (!target) return
        var p = target.mapToItem(Overlay.overlay, 0, 0)
        var w = Math.min(implicitWidth, maxWidth_)
        var h = implicitHeight
        var x = p.x + (target.width - w) * 0.5
        var y = p.y + target.height + Metrics.xs4
        if (x + w > Overlay.overlay.width - sideMargin)
            x = Overlay.overlay.width - w - sideMargin
        if (x < sideMargin) x = sideMargin
        if (y + h > Overlay.overlay.height - sideMargin)
            y = p.y - h - Metrics.xs4
        control.x = x
        control.y = y
        control.width = w
        control.height = h
    }
}
