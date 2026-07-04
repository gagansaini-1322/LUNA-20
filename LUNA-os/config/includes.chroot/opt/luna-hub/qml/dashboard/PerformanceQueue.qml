import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card

    property var items: []
    signal addRequested()

    implicitHeight: 280

    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Row {
            width: parent.width
            spacing: Metrics.xs12
            Label {
                text: "Performance Queue"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
                anchors.verticalCenter: parent.verticalCenter
            }
            LunaStatusBadge {
                text: card.items.length + " games"
                tone: LunaStatusBadge.Tone.Neutral
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: parent.width - 200 }
            LunaButton {
                text: "Add to Queue"
                sizeMode: LunaButton.Size.Small
                iconName: "+"
                hasIcon: true
                variant: LunaButton.Variant.Subtle
                onClicked: card.addRequested()
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 60
            clip: true
            spacing: Metrics.xs4
            model: card.items
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Item {
                width: list.width
                height: 56
                QueueItem {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs4
                    itemTitle: modelData.title
                    itemGame: modelData.game
                    itemStatus: modelData.status
                    itemPriority: modelData.priority !== undefined ? modelData.priority : "Normal"
                }
            }
        }

        LunaEmptyState {
            visible: card.items.length === 0
            anchors.centerIn: parent
            width: parent.width
            height: parent.height - 80
            heading: "Queue is empty"
            body: "Add a game to prioritize resources while you play."
            actionLabel: "Add a Game"
            iconName: "+"
            onAction: card.addRequested()
        }
    }
}
