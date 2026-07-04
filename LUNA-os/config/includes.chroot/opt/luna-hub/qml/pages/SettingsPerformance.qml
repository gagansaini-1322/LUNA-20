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
            heading: "Performance"
            subheading: "Defaults for Luna Boost profiles."

            SettingsField {
                width: parent.width
                label: "Default profile on game launch"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "Balanced", value: "Balanced" }, { label: "Turbo", value: "Turbo" }, { label: "Silent", value: "Silent" } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsField {
                width: parent.width
                label: "Frame cap strategy"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "Match display refresh", value: "dr" }, { label: "Fixed 60", value: "60" }, { label: "Off", value: "off" } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsToggle {
                width: parent.width
                label: "Auto-switch to Turbo when thermal headroom is low"
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Pause non-essential background services while gaming"
                checked: true
            }
        }
    }
}
