import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Theme
import LunaHub.Shell

pragma ComponentBehavior: Bound

ApplicationWindow {
    id: rootWindow

    title: "Luna Hub"
    width: 1400
    height: 880
    minimumWidth: Metrics.windowMinWidth
    minimumHeight: Metrics.windowMinHeight
    visible: true
    color: Theme.bgPrimary
    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint
             | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint

    font.family: Typography.family
    color: Theme.bgPrimary

    Component.onCompleted: {
        shell.pageTitle = "Dashboard"
    }

    AppShell {
        id: shell
        anchors.fill: parent

        onRouteRequested: (route) => {
            shell.pageTitle = shell.pageTitleFor(route)
            shell.currentRoute = route
        }
    }

    onClosing: function(close) {
        if (close.accepted) return
        close.accepted = true
        Qt.quit()
    }
}
