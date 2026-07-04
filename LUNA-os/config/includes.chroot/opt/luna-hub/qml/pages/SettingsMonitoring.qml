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
            heading: "Monitoring"
            subheading: "Frequency and sensors polled."

            SettingsField {
                width: parent.width
                label: "Telemetry sample rate"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "10 Hz", value: 10 }, { label: "5 Hz", value: 5 }, { label: "2 Hz", value: 2 } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsField {
                width: parent.width
                label: "Sensor coverage"
                field: LunaDropdown { Layout.fillWidth: true; modelArray: [ { label: "All", value: "all" }, { label: "CPU + GPU", value: "cg" }, { label: "Minimum", value: "min" } ]; currentIndex: 0; displayRole: "label"; valueRole: "value" }
            }
            SettingsToggle {
                width: parent.width
                label: "Persist historical telemetry"
                description: "Used for the History graph in Optimizer."
                checked: true
            }
            SettingsToggle {
                width: parent.width
                label: "Include disk SMART health in diagnostics"
                checked: true
            }
        }
    }
}
