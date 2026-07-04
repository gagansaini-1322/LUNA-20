import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: row

    property string itemTitle: ""
    property string itemGame: ""
    property string itemStatus: "Ready"
    property string itemPriority: "Normal"
    property string iconName: "▶"
    property var menuActions: []
    signal menuRequested()

    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
    radius: Metrics.radiusMd
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: Metrics.radiusMd + 1
        color: "transparent"
        border.color: Theme.accentPrimary
        border.width: Metrics.strokeThin
        opacity: row.ListView.isCurrentItem ? Theme.glowSoft : 0
        visible: opacity > 0
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs12
        anchors.rightMargin: Metrics.xs8
        spacing: Metrics.xs12

        Item {
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: Metrics.radiusSm
                color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.18)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.45)
            }
            Label {
                anchors.centerIn: parent
                text: row.iconName
                color: Theme.accentSecondary
                font.pixelSize: Metrics.iconMd
                font.family: Typography.family
            }
        }

        Column {
            width: row.width - 36 - 130 - 36 - parent.spacing * 4
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: row.itemGame
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption.size
                font.weight: Font.Medium
                font.letterSpacing: 0.4
                elide: Text.ElideRight
                width: parent.width
            }
            Label {
                text: row.itemTitle
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }
        }

        LunaStatusBadge {
            Layout.preferredWidth: 80
            anchors.verticalCenter: parent.verticalCenter
            text: row.itemStatus
            tone: row.itemStatus === "Running" ? LunaStatusBadge.Tone.Success
                  : row.itemStatus === "Paused" ? LunaStatusBadge.Tone.Warning
                  : LunaStatusBadge.Tone.Neutral
            dot: true
        }

        LunaStatusBadge {
            anchors.verticalCenter: parent.verticalCenter
            text: row.itemPriority
            tone: row.itemPriority === "High" ? LunaStatusBadge.Tone.Critical
                  : row.itemPriority === "Low" ? LunaStatusBadge.Tone.Neutral
                  : LunaStatusBadge.Tone.Info
        }

        LunaIconButton {
            anchors.verticalCenter: parent.verticalCenter
            iconName: "⋯"
            iconPx: Metrics.iconMd
            tooltipText: "Actions"
            onClicked: row.menuRequested()
        }
    }
}
