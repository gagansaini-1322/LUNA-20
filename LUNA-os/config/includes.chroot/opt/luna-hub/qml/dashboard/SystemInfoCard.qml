import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card

    property var fields: [
        { "k": "OS", "v": "LunaOS 20.0 Falcon" },
        { "k": "Kernel", "v": "6.6.21-luna" },
        { "k": "CPU", "v": "AMD Ryzen 7 7800X3D" },
        { "k": "GPU", "v": "NVIDIA RTX 4070 SUPER" },
        { "k": "RAM", "v": "32 GB DDR5-6000" },
        { "k": "Mobo", "v": "ASUS ROG STRIX B650" },
        { "k": "Driver", "v": "NVIDIA 555.42" },
        { "k": "Storage", "v": "2 TB NVMe Gen4" }
    ]

    signal refresh()
    signal copyDiagnostics()

    implicitHeight: 240

    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        RowLayout {
            spacing: Metrics.xs12
            Layout.fillWidth: true
            Label {
                text: "System Info"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Item { Layout.fillWidth: true }
            LunaButton {
                text: "Refresh"
                sizeMode: LunaButton.Size.Small
                variant: LunaButton.Variant.Ghost
                iconName: "↻"
                hasIcon: true
                onClicked: card.refresh()
            }
            LunaButton {
                text: "Copy Diagnostics"
                sizeMode: LunaButton.Size.Small
                onClicked: card.copyDiagnostics()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: Metrics.xs24
            rowSpacing: Metrics.xs8

            Repeater {
                model: card.fields
                delegate: Row {
                    Layout.fillWidth: true
                    Label {
                        text: modelData.k
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.bodyLabel.size
                        font.weight: Font.Medium
                        width: 80
                    }
                    Label {
                        text: modelData.v
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.bodyLabel.size
                        elide: Text.ElideRight
                        width: card.width - 200 - Metrics.xs24
                    }
                }
            }
        }
    }
}
