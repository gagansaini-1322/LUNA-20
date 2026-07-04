import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle { color: "transparent"

    Column {
        anchors.fill: parent
        spacing: Metrics.xs16

        SettingsSection {
            width: parent.width
            heading: "Notifications"
            subheading: "Toasts, OS, and in-app alerts."

            SettingsToggle {
                width: parent.width
                label: "Boost State Changes"
                description: "On / partial / off transitions."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Thermal Warnings"
                description: "Threshold ramps per sensor."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Driver & System Updates"
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Luna Boost Auto-stop Events"
                description: "When invoked protections disengage Boost."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Play in-game overlay indicator"
                checked: false
            }
        }
    }
}
