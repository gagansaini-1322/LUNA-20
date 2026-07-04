import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card

    property var sensors: []
    signal refresh()

    implicitHeight: 240

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
                text: "Temperatures"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: parent.width - 200 }
            LunaButton {
                text: "Refresh"
                sizeMode: LunaButton.Size.Small
                variant: LunaButton.Variant.Ghost
                iconName: "↻"
                hasIcon: true
                onClicked: card.refresh()
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ListView {
            width: parent.width
            height: parent.height - 80
            clip: true
            spacing: Metrics.xs4
            model: card.sensors
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: TemperatureRow {
                width: parent ? parent.width : 0
                sensorName: modelData.name
                sensorValue: modelData.value
                sensorLabel: modelData.label || ""
                sensorStatus: modelData.status || "ok"
            }
        }

        LunaEmptyState {
            visible: card.sensors.length === 0
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: parent.width
            height: parent.height - 80
            heading: "No sensors reported"
            body: "Telemetry service is gathering data."
            iconName: "○"
        }
    }
}
