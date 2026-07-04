import QtQuick
import LunaHub

pragma ComponentBehavior: Bound
Item {
    id: root

    enum Mode { Compact, Mid, Wide, Ultrawide }
    property int mode: Layouts.Mode.Compact
    property real containerPadding: Metrics.xs16
    property real cardSpacing: Metrics.xs16
    property int columns: 3

    function recompute(width) {
        if (width >= Metrics.bpUltrawide) {
            mode = Layouts.Mode.Ultrawide
            columns = 6
            cardSpacing = Metrics.xs24
            containerPadding = Metrics.xs32
        } else if (width >= Metrics.bpWide) {
            mode = Layouts.Mode.Wide
            columns = 4
            cardSpacing = Metrics.xs20
            containerPadding = Metrics.xs24
        } else if (width >= Metrics.bpMid) {
            mode = Layouts.Mode.Mid
            columns = 3
            cardSpacing = Metrics.xs16
            containerPadding = Metrics.xs20
        } else {
            mode = Layouts.Mode.Compact
            columns = 2
            cardSpacing = Metrics.xs12
            containerPadding = Metrics.xs16
        }
    }

    function isCompact() { return mode === Layouts.Mode.Compact }
    function isWide() { return mode === Layouts.Mode.Wide || mode === Layouts.Mode.Ultrawide }
}
