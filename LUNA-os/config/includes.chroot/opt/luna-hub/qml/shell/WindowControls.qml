import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: controls

    implicitWidth: 138
    implicitHeight: Metrics.titleBarHeight

    signal minimizeClicked()
    signal maximizeClicked()
    signal closeClicked()

    property bool isMaximized: false

    Row {
        anchors.fill: parent
        anchors.rightMargin: Metrics.xs8
        spacing: 0

        WindowButton {
            width: 46
            height: parent.height
            iconChar: "—"
            iconSize: 12
            hoverColor: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.45)
            accessibleName: "Minimize"
            onClicked: controls.minimizeClicked()
        }
        WindowButton {
            width: 46
            height: parent.height
            iconChar: controls.isMaximized ? "❐" : "□"
            iconSize: 14
            hoverColor: Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.55)
            accessibleName: controls.isMaximized ? "Restore" : "Maximize"
            onClicked: controls.maximizeClicked()
        }
        WindowButton {
            width: 46
            height: parent.height
            iconChar: "✕"
            iconSize: 12
            hoverColor: Theme.criticalColor
            hoverTextColor: Theme.textPrimary
            accessibleName: "Close"
            onClicked: controls.closeClicked()
        }
    }

    component WindowButton: Rectangle {
        id: wb
        property string iconChar: ""
        property int iconSize: Metrics.iconSm
        property color hoverColor: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.35)
        property color hoverTextColor: Theme.textPrimary
        property string accessibleName: ""
        signal clicked()

        color: hover.containsMouse && !pressed ? hoverColor : "transparent"

        Behavior on color { ColorAnimation { duration: Metrics.durFast } }

        HoverHandler { id: hover }

        Label {
            anchors.centerIn: parent
            text: wb.iconChar
            color: wb.hover.containsMouse && !wb.parent.parent.pressed ? wb.hoverTextColor : Theme.textSecondary
            font.pixelSize: wb.iconSize
            font.family: Typography.family
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wb.clicked()
        }
    }
}
