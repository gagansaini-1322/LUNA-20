import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Button {
    id: control

    property string iconName: ""
    property string tooltipText: ""
    property bool active: false
    property color iconColor: Theme.textSecondary
    property int sizeMode: 0
    property int iconPx: Metrics.iconLg

    flat: true
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    implicitWidth: {
        if (sizeMode === 1) return 28
        if (sizeMode === 2) return 36
        return 32
    }
    implicitHeight: implicitWidth

    background: Rectangle {
        radius: width * 0.5
        color: {
            if (!control.enabled) return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.25)
            if (control.active) return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.25)
            if (control.pressed) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.6)
            if (control.hovered) return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.4)
            return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
        }
        border.width: control.active ? Metrics.strokeThin : Metrics.strokeHairline
        border.color: {
            if (control.active) return Theme.borderActive
            if (control.hovered) return Theme.borderHover
            return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)
        }
        Behavior on color { ColorAnimation { duration: Metrics.durFast } }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: width * 0.5
            color: "transparent"
            border.color: Theme.borderActive
            border.width: Metrics.strokeThin
            opacity: control.active ? Theme.glowMedium : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
        }
    }

    contentItem: Item {
        Label {
            anchors.centerIn: parent
            text: control.iconName
            color: control.enabled
                ? (control.active ? Theme.textPrimary : control.iconColor)
                : Theme.disabledColor
            font.pixelSize: control.iconPx
            font.family: Typography.family
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: control.tooltipText.length > 0 ? control.tooltipText : control.iconName
    Accessible.focusable: true

    LunaTooltip {
        id: tip
        text: control.tooltipText
        visible: control.tooltipText.length > 0 && control.hovered && !control.pressed
    }
}
