import QtQuick
import LunaHub
import LunaHub.Theme
import LunaHub.Dialogs

pragma ComponentBehavior: Bound

Item {
    id: layer

    property var activeDialog: null

    function open(name, props) {
        closeAll()
        var comp = null
        if (name === "gameSelection") comp = gameSelectionDialogComponent
        else if (name === "confirmation") comp = confirmationDialogComponent
        else if (name === "boostDetails") comp = boostDetailsDialogComponent
        else if (name === "diagnostics") comp = diagnosticsDialogComponent

        if (!comp) return
        var dlg = comp.createObject(layer, props || {})
        dlg.closed.connect(function() { dlg.destroy(); activeDialog = null })
        activeDialog = dlg
        dlg.open()
    }

    function closeAll() {
        if (activeDialog) activeDialog.close()
    }

    Component {
        id: gameSelectionDialogComponent
        GameSelectionDialog {}
    }
    Component {
        id: confirmationDialogComponent
        ConfirmationDialog {}
    }
    Component {
        id: boostDetailsDialogComponent
        BoostDetailsDialog {}
    }
    Component {
        id: diagnosticsDialogComponent
        DiagnosticsDialog {}
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.overlayBg.r, Theme.overlayBg.g, Theme.overlayBg.b, 0.55)
        visible: layer.activeDialog !== null
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Metrics.durFade } }
    }
}
