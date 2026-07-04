import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: item

    property string label: ""
    property string icon: ""
    property bool active: false
    property string badgeCount: ""
    signal clicked()

    property bool hover: hoverHandler.hovered

    color: {
        if (active) return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.18)
        if (pressed) return Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.45)
        if (hover) return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.18)
        return "transparent"
    }

    radius: Metrics.radiusMd
    border.width: active ? Metrics.strokeHairline : 0
    border.color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.55)

    Behavior on color { ColorAnimation { duration: Metrics.durFast } }

    Rectangle {
        id: glowRect
        anchors.fill: parent
        anchors.margins: -1
        radius: Metrics.radiusMd + 1
        color: "transparent"
        border.color: Theme.accentPrimary
        border.width: Metrics.strokeThin
        opacity: item.active ? Theme.glowSoft : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4
        width: 3
        height: parent.height - 12
        radius: 2
        color: Theme.accentPrimary
        opacity: item.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs16
        anchors.rightMargin: Metrics.xs12
        spacing: Metrics.xs12
        Label {
            text: item.icon
            color: item.active ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: Metrics.iconLg
            font.family: Typography.family
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            text: item.label
            color: item.active ? Theme.textPrimary : Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            font.weight: item.active ? Font.Medium : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width - 36 - (item.badgeCount.length > 0 ? 32 : 0)
        }
        LunaStatusBadge {
            visible: item.badgeCount.length > 0
            text: item.badgeCount
            tone: LunaStatusBadge.Tone.Neutral
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler { id: hoverHandler }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: { item.z = 1 }
        onReleased: { item.z = 0 }
        onClicked: item.clicked()
    }
}
