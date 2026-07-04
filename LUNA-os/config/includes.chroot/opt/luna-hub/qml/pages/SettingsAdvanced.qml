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
            heading: "Advanced"
            subheading: "Developer, debug, and experimental toggles."

            SettingsToggle {
                width: parent.width
                label: "Verbose telemetry logs"
                description: "Writes per-second telemetry into journald."
                checked: false
            }
            SettingsToggle {
                width: parent.width
                label: "Unsafe experimental Boost modes"
                description: "Includes voltage, ELC, and curve optimizer."
                checked: false
            }
            LunaButton {
                text: "Open Config Folder"
                variant: LunaButton.Variant.Subtle
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
