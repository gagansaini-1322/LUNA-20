import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "settings"

    property var subtabs: [
        { "label": "General" },
        { "label": "Appearance" },
        { "label": "Monitoring" },
        { "label": "Performance" },
        { "label": "Notifications" },
        { "label": "Privacy" },
        { "label": "Startup" },
        { "label": "Advanced" }
    ]
    property int subIndex: 0

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        LunaTabBar {
            width: parent.width
            tabs: page.subtabs
            currentIndex: page.subIndex
            onCurrentChanged: (idx) => page.subIndex = idx
        }

        Item {
            width: parent.width
            height: parent.height - y - Metrics.xs16

            Loader {
                anchors.fill: parent
                sourceComponent: page.subIndex === 0 ? general
                                  : page.subIndex === 1 ? appearance
                                  : page.subIndex === 2 ? monitoring
                                  : page.subIndex === 3 ? performance
                                  : page.subIndex === 4 ? notifications
                                  : page.subIndex === 5 ? privacy
                                  : page.subIndex === 6 ? startup
                                  : advanced
            }
        }
    }

    Component { id: general; SettingsGeneral {} }
    Component { id: appearance; SettingsAppearance {} }
    Component { id: monitoring; SettingsMonitoring {} }
    Component { id: performance; SettingsPerformance {} }
    Component { id: notifications; SettingsNotifications {} }
    Component { id: privacy; SettingsPrivacy {} }
    Component { id: startup; SettingsStartup {} }
    Component { id: advanced; SettingsAdvanced {} }
}
