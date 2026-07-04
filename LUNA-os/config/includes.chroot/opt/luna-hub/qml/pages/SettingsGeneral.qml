import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: pg
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: Metrics.xs16

        SettingsSection {
            width: parent.width
            heading: "General"
            subheading: "Account and basic preferences."

            SettingsField {
                width: parent.width
                label: "Display Name"
                field: LunaTextField { Layout.fillWidth: true; text: "Player One"; placeholder: "e.g. Player One" }
            }
            SettingsField {
                width: parent.width
                label: "Language"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "English (US)", value: "en_US" }, { label: "Italiano", value: "it_IT" }, { label: "Deutsch", value: "de_DE" }, { label: "Español", value: "es_ES" } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsToggle {
                width: parent.width
                label: "Open Luna Hub at login"
                description: "Start in the background and wait for the first window."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Minimize to System Tray"
                description: "Useful while you're gaming."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Send anonymous usage stats"
                description: "Help Luna Hub improve defaults and recommendations."
                checked: false
            }
        }
    }
}
