import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "optimizer"

    property var sections: [
        { "label": "Current Game" },
        { "label": "Background" },
        { "label": "Startup" },
        { "label": "Gaming Services" },
        { "label": "Recommendations" },
        { "label": "History" }
    ]
    property int sectionIndex: 0

    property string currentGame: "Helldivers 2"
    property string currentGameSource: "Steam"
    property string currentGameProfile: "FPS Priority"

    property var backgroundItems: [
        { "name": "discord",       "title": "Discord",              "load": "1.3%", "memory": "420 MB", "status": "Optimized", "active": true },
        { "name": "chrome",        "title": "Google Chrome",        "load": "4.1%", "memory": "1.2 GB", "status": "Idle",      "active": true },
        { "name": "steamservice",  "title": "Steam Service",        "load": "0.6%", "memory": "98 MB",  "status": "Optimized", "active": true },
        { "name": "ea_app",        "title": "EA App",               "load": "1.0%", "memory": "260 MB", "status": "Throttled", "active": false }
    ]

    property var startupItems: [
        { "name": "OneDrive",       "title": "Microsoft OneDrive",  "impact": "Low",    "enabled": true },
        { "name": "Steam",          "title": "Steam Client",          "impact": "Low",    "enabled": true },
        { "name": "Corsair iCUE",   "title": "iCUE",                  "impact": "Medium", "enabled": true },
        { "name": "Nahimic",        "title": "Nahimic Service",       "impact": "High",   "enabled": false },
        { "name": "Razer Synapse",  "title": "Razer Synapse",         "impact": "Medium", "enabled": false }
    ]

    property var services: [
        { "name": "BattlEye",           "title": "BattlEye",            "state": "Active",       "active": true },
        { "name": "EasyAntiCheat",      "title": "Easy Anti-Cheat",     "state": "Active",       "active": true },
        { "name": "Xbox Game Services", "title": "Xbox Game Services",  "state": "Suspended",    "active": true },
        { "name": "GameInputRedist",    "title": "GameInput",           "state": "Deployment",   "active": false }
    ]

    property var recommendations: [
        { "title": "Switch to Turbo fan profile",   "reason": "GPU 78°C sustained", "impact": "+12% FPS",   "apply": true },
        { "title": "Pause OneDrive while gaming",   "reason": "Disk I/O contention", "impact": "Lower 1% lows", "apply": false },
        { "title": "Cap Frame Rate to 144",          "reason": "Reduce tearing", "impact": "+5% frame time", "apply": true },
        { "title": "Move Helldivers 2 to NVMe",      "reason": "On SATA SSD", "impact": "Faster loads", "apply": false }
    ]

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
                id: sectionLoader
                anchors.fill: parent
                sourceComponent: page.sectionIndex === 0 ? currentGameComp
                                  : page.sectionIndex === 1 ? backgroundComp
                                  : page.sectionIndex === 2 ? startupComp
                                  : page.sectionIndex === 3 ? servicesComp
                                  : page.sectionIndex === 4 ? recommendationsComp
                                  : historyComp
    loader
}
        }
    }

    Component {
        id: currentGameComp
        OptimizerCurrentGamePanel { game: page.currentGame; source: page.currentGameSource; profile: page.currentGameProfile; items: page.recommendations }
    }
    Component {
        id: backgroundComp
        OptimizerListPanel {
            heading: "Background processes"
            subheading: "Suspend or throttle low-priority applications while gaming."
            items: page.backgroundItems
            itemKind: "process"
        }
    }
    Component {
        id: startupComp
        OptimizerListPanel {
            heading: "Startup items"
            subheading: "Disable high-impact boot entries to reduce login time."
            items: page.startupItems
            itemKind: "startup"
        }
    }
    Component {
        id: servicesComp
        OptimizerListPanel {
            heading: "Gaming Services"
            subheading: "Telemetry-native anti-cheat, overlay, and game input services."
            items: page.services.map(function(s) { return { name: s.name, title: s.title, status: s.state, active: s.active } })
            itemKind: "service"
        }
    }
    Component {
        id: recommendationsComp
        OptimizerRecommendationsPanel { items: page.recommendations }
    }
    Component {
        id: historyComp
        OptimizerHistoryPanel {}
    }
}
