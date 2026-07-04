import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "systemtools"

    property var sections: [
        { "label": "System Info" },
        { "label": "Drivers" },
        { "label": "Storage" },
        { "label": "Services" },
        { "label": "Logs" },
        { "label": "Diagnostics" },
        { "label": "Update" },
        { "label": "Recovery" }
    ]
    property int sectionIndex: 0

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        LunaTabBar {
            width: parent.width
            tabs: page.sections
            currentIndex: page.sectionIndex
            onCurrentChanged: (idx) => page.sectionIndex = idx
        }

        Item {
            width: parent.width
            height: parent.height - y - Metrics.xs16

            Loader {
                anchors.fill: parent
                sourceComponent: page.sectionIndex === 0 ? sysInfoComp
                                  : page.sectionIndex === 1 ? driversComp
                                  : page.sectionIndex === 2 ? storageComp
                                  : page.sectionIndex === 3 ? servicesComp
                                  : page.sectionIndex === 4 ? logsComp
                                  : page.sectionIndex === 5 ? diagComp
                                  : page.sectionIndex === 6 ? updateComp
                                  : recoveryComp
            }
        }
    }

    Component {
        id: sysInfoComp
        SystemToolsSysInfo {}
    }
    Component {
        id: driversComp
        SystemToolsDrivers {}
    }
    Component {
        id: storageComp
        SystemToolsStorage {}
    }
    Component {
        id: servicesComp
        SystemToolsServices {}
    }
    Component {
        id: logsComp
        SystemToolsLogs {}
    }
    Component {
        id: diagComp
        SystemToolsDiagnostics {}
    }
    Component {
        id: updateComp
        SystemToolsUpdate {}
    }
    Component {
        id: recoveryComp
        SystemToolsRecovery {}
    }
}
