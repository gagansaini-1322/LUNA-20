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

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Label {
            text: "Diagnostics"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }
        Label {
            text: "Generate a sanitized report we can share with support."
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Rectangle {
            color: Theme.bgPrimary
            radius: Metrics.radiusMd
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
            width: parent.width
            height: parent.height - 200

            Label {
                anchors.fill: parent
                anchors.margins: Metrics.xs16
                text: "// Luna Diagnostic Preview\nluna-hub@host  ✔ OK\ntelemetry     ✔ OK\nboost         ✔ idle\ngpu.notes     \"Driver 555.42 stable\"\nram.notes     \"18GB / 32GB in use\"\nstorage.notes \"NVMe 56% full\"\nintegration   ✔ Steam, GOG, Battle.net\n// Sensitive identifiers removed."
                color: Theme.textPrimary
                font.family: Typography.monoFamily
                font.pixelSize: Typography.caption.size
                wrapMode: Text.NoWrap
            }
        }

        Row {
            spacing: Metrics.xs12
            LunaButton { text: "Preview Report"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Subtle }
            LunaButton { text: "Generate & Save"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Primary }
            LunaButton { text: "Send to Support"; sizeMode: LunaButton.Size.Small }
        }
    }
}
