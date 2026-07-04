import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle { color: "transparent"

    Column {
        anchors.fill: parent
        spacing: Metrics.xs16

        SettingsSection {
            width: parent.width
            heading: "Privacy"
            subheading: "Telemetry, sharing, and local data."

            SettingsToggle {
                width: parent.width
                label: "Send anonymous crash reports"
                description: "Helps Luna Hub catch issues early."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Generate anonymized diagnostics"
                description: "Used when creating a Support bundle."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Store profile data on disk"
                description: "Allow profiles to follow you across sessions."
                checked: true
            }
            LunaButton {
                text: "Clear Local Cache"
                variant: LunaButton.Variant.Danger
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
