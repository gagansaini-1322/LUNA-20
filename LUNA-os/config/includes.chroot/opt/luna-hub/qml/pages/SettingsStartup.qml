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
            heading: "Startup"
            subheading: "Launchable items on session log-in."

            SettingsToggle {
                width: parent.width
                label: "Luna Boost on log-in"
                description: "Quietly pre-warm telemetry before your first game."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "RGB controller"
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Steam library indexer"
                checked: false
            }
            SettingsToggle {
                width: parent.width
                label: "Game integration sync"
                description: "Pulls save states and achievements."
                checked: true
            }
        }
    }
}
