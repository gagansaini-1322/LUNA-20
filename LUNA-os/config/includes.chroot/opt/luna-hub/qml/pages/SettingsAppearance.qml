import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: Metrics.xs16

        SettingsSection {
            width: parent.width
            heading: "Appearance"
            subheading: "Theme, accents, and density."

            SettingsField {
                width: parent.width
                label: "Accent"
                field: LunaSegmented { Layout.fillWidth: true; currentIndex: 0; options: [ { label: "Luna" }, { label: "Aurora" }, { label: "Nebula" }, { label: "Forge" } ] }
            }
            SettingsField {
                width: parent.width
                label: "Surface density"
                field: LunaSegmented { Layout.fillWidth: true; currentIndex: 1; options: [ { label: "Compact" }, { label: "Cozy" }, { label: "Spacious" } ] }
            }
            SettingsField {
                width: parent.width
                label: "Font Family"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "Inter", value: "Inter" }, { label: "Cantarell", value: "Cantarell" }, { label: "System", value: "" } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsToggle {
                width: parent.width
                label: "Use tabular numerals"
                description: "Aligned digits across telemetry values."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Reduced motion"
                description: "Disables short UI animations where possible."
                checked: false
            }
        }
    }
}
