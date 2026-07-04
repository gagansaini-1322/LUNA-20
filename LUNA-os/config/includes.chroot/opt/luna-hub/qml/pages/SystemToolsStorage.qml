import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    property var volumes: [
        { "label": "NVMe System",  "path": "/",          "total": "2.0 TB",  "used": "1.12 TB",  "percent": 56,  "tonal": Theme.cpuAccent },
        { "label": "Games NVMe",   "path": "/mnt/games", "total": "4.0 TB",  "used": "2.71 TB",  "percent": 67,  "tonal": Theme.ramAccent },
        { "label": "Scratch SSD",  "path": "/scratch",   "total": "512 GB",  "used": "302 GB",   "percent": 59,  "tonal": Theme.gpuAccent },
        { "label": "External",     "path": "/media/bk",  "total": "8 TB",    "used": "5.4 TB",   "percent": 67,  "tonal": Theme.accentSecondary }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Label {
            text: "Storage"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }

        ListView {
            width: parent.width
            height: parent.height - 50
            clip: true
            spacing: Metrics.xs8
            model: card.volumes
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 76
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
                Column {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs12
                    spacing: Metrics.xs4
                    Row {
                        width: parent.width
                        Label {
                            text: modelData.label
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                        }
                        Item { width: parent.width - 320 }
                        Label {
                            text: modelData.used + "  /  " + modelData.total
                            color: Theme.textSecondary
                            font.family: Typography.family
                            font.pixelSize: Typography.smallTelemetry.size
                            font.features: { "tnum": true }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Label {
                        text: modelData.path
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                    }
                    LunaProgressBar {
                        width: parent.width
                        height: 6
                        value: modelData.percent
                        max: 100
                        fillColor: modelData.tonal
                    }
                }
            }
        }
    }
}
