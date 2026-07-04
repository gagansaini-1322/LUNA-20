import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Theme
import LunaHub.Pages
import LunaHub.Shell

pragma ComponentBehavior: Bound

Item {
    id: shell

    property string currentRoute: "dashboard"
    signal routeRequested(string route)

    readonly property var navigationItems: [
        { "route": "dashboard", "label": "Dashboard", "icon": "◎" },
        { "route": "performance", "label": "Performance", "icon": "✦", "badge": "" },
        { "route": "optimizer", "label": "Optimizer", "icon": "✺", "badge": "" },
        { "route": "games", "label": "Games", "icon": "▶" },
        { "route": "network", "label": "Network", "icon": "◍" },
        { "route": "systemtools", "label": "System Tools", "icon": "▣" },
        { "route": "rgb", "label": "RGB", "icon": "❖" },
        { "route": "settings", "label": "Settings", "icon": "⚙" }
    ]

    property string pageTitle: ""
    property var pageActions: []

    readonly property Sidebar sidebar: sidebarInstance
    readonly property TopBar topbar: topbarInstance

    readonly property string telemetryServiceStatus: "Connected"
    readonly property string lunaVersion: "20.0"

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    Sidebar {
        id: sidebarInstance
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Metrics.sidebarWidth
        navigationItems: shell.navigationItems
        currentRoute: shell.currentRoute
        versionString: "v" + shell.lunaVersion
        serviceStatus: shell.telemetryServiceStatus
        onRouteRequested: (route) => shell.routeRequested(route)
    }

    TopBar {
        id: topbarInstance
        anchors.left: sidebarInstance.right
        anchors.right: parent.right
        anchors.top: parent.top
        height: Metrics.titleBarHeight + Metrics.topBarHeight
        pageTitle: shell.pageTitle
        actions: shell.pageActions
    }

    Rectangle {
        id: stackRoot
        anchors.left: sidebarInstance.right
        anchors.right: parent.right
        anchors.top: topbarInstance.bottom
        anchors.bottom: parent.bottom
        color: Theme.bgPrimary
        clip: true

        StackLayout {
            id: pageStack
            anchors.fill: parent
            currentIndex: routeIndex(shell.currentRoute)

            DashboardPage {
                routeName: "dashboard"
            }
            PerformancePage {
                routeName: "performance"
            }
            OptimizerPage {
                routeName: "optimizer"
            }
            GamesPage {
                routeName: "games"
            }
            NetworkPage {
                routeName: "network"
            }
            SystemToolsPage {
                routeName: "systemtools"
            }
            RGBControlPage {
                routeName: "rgb"
            }
            SettingsPage {
                routeName: "settings"
            }
        }
    }

    NotificationLayer {
        id: notifications
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Metrics.xs24
        anchors.bottomMargin: Metrics.xs24
        width: 360
        height: parent.height - 200
    }

    DialogLayer {
        id: dialogs
        anchors.fill: parent
    }

    function routeIndex(route) {
        for (var i = 0; i < navigationItems.length; i++)
            if (navigationItems[i].route === route) return i
        return 0
    }

    function pageTitleFor(route) {
        for (var i = 0; i < navigationItems.length; i++)
            if (navigationItems[i].route === route) return navigationItems[i].label
        return ""
    }

    function notify(title, message, tone) {
        notifications.push({ "title": title, "message": message, "tone": tone ? tone : 0 })
    }

    function openDialog(name, props) {
        dialogs.open(name, props)
    }

    function closeDialog() {
        dialogs.closeAll()
    }
}
