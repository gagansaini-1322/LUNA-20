import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Button {
    id: control

    enum Size { Small, Medium, Large }
    enum Variant { Default, Primary, Subtle, Danger, Ghost }

    property int sizeMode: LunaButton.Size.Medium
    property int variant: LunaButton.Variant.Default
    property bool hasIcon: false
    property string iconName: ""
    property string shortcutText: ""
    property bool active: false

    flat: true
    autoExclusive: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0

    font.family: Typography.family
    font.pixelSize: Typography.buttonLabel.size
    font.weight: Typography.buttonLabel.weight
    font.letterSpacing: Typography.buttonLabel.letterSpacing

    implicitHeight: {
        if (sizeMode === LunaButton.Size.Small) return 28
        if (sizeMode === LunaButton.Size.Large) return 44
        return 36
    }
    implicitWidth: Math.max(implicitContentWidth + hPadding * 2, 64)

    readonly property int hPadding: {
        if (sizeMode === LunaButton.Size.Small) return Metrics.xs12
        if (sizeMode === LunaButton.Size.Large) return Metrics.xs24
        return Metrics.xs16
    }

    function bgFor() {
        if (!enabled) return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
        if (active) return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.22)
        if (variant === LunaButton.Variant.Primary) {
            if (pressed) return Qt.darker(Theme.accentPrimary, 1.4)
            if (hovered) return Theme.accentPrimary
            return Theme.accentPrimary
        }
        if (variant === LunaButton.Variant.Danger) {
            if (pressed) return Qt.darker(Theme.criticalColor, 1.4)
            if (hovered) return Theme.criticalColor
            return Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.85)
        }
        if (variant === LunaButton.Variant.Subtle) {
            if (pressed) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.6)
            if (hovered) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.35)
            return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.45)
        }
        if (variant === LunaButton.Variant.Ghost) {
            if (pressed) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.6)
            if (hovered) return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.35)
            return "transparent"
        }
        if (pressed) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.5)
        if (hovered) return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.28)
        return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    }

    function fgFor() {
        if (!enabled) return Theme.disabledColor
        if (variant === LunaButton.Variant.Primary) return Theme.textPrimary
        if (variant === LunaButton.Variant.Danger) return Theme.textPrimary
        if (active) return Theme.textPrimary
        return Theme.textSecondary
    }

    function borderFor() {
        if (active) return Theme.borderActive
        if (hovered && !pressed) return Theme.borderHover
        if (variant === LunaButton.Variant.Subtle) return Theme.borderDefault
        return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.6)
    }

    background: Rectangle {
        id: bgRect
        color: control.bgFor()
        radius: Metrics.radiusMd
        border.width: Metrics.strokeHairline
        border.color: control.borderFor()
        opacity: 1.0
        Behavior on color {
            ColorAnimation { duration: Metrics.durFast }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: Metrics.radiusMd + 1
            color: "transparent"
            border.color: Theme.borderActive
            border.width: Metrics.strokeThin
            opacity: control.active ? Theme.glowSoft : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
        }
    }

    contentItem: Row {
        spacing: Metrics.xs8
        anchors.centerIn: parent
        Label {
            visible: control.hasIcon
            text: control.iconName
            color: control.fgFor()
            font.pixelSize: Typography.buttonLabel.size + 2
            font.family: Typography.family
        }
        Label {
            text: control.text
            color: control.fgFor()
            font: control.font
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            visible: control.shortcutText.length > 0
            text: control.shortcutText
            color: Theme.textMuted
            font.pixelSize: Typography.caption.size
            font.family: Typography.family
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.focusable: true
}
