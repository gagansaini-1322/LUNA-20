pragma Singleton
import QtQuick

QtObject {
    id: metrics

    // Spacing scale (4-base)
    readonly property int xs4: 4
    readonly property int xs8: 8
    readonly property int xs12: 12
    readonly property int xs16: 16
    readonly property int xs20: 20
    readonly property int xs24: 24
    readonly property int xs32: 32
    readonly property int xs40: 40
    readonly property int xs48: 48
    readonly property int xs64: 64

    // Iconography
    readonly property int iconXs: 12
    readonly property int iconSm: 14
    readonly property int iconMd: 16
    readonly property int iconLg: 20
    readonly property int iconXl: 24
    readonly property int iconXxl: 32

    // Corner radii
    readonly property int radiusSm: 4
    readonly property int radiusMd: 6
    readonly property int radiusLg: 10
    readonly property int radiusXl: 14
    readonly property int radiusPill: 999

    // Minimum card dimensions
    readonly property int cardMinHeight: 96
    readonly property int cardMinHeightTall: 160
    readonly property int cardMinHeightHero: 220
    readonly property int cardMinWidth: 180

    // Window chrome
    readonly property int titleBarHeight: 32
    readonly property int sidebarWidth: 220
    readonly property int sidebarCompactWidth: 64
    readonly property int topBarHeight: 48
    readonly property int statusBarHeight: 24
    readonly property int windowMinWidth: 1280
    readonly property int windowMinHeight: 720

    // Strokes
    readonly property int strokeHairline: 1
    readonly property int strokeThin: 2
    readonly property int strokeMedium: 3

    // Graph sampling
    readonly property int graphSamplesMax: 600
    readonly property real graphStrokeWidth: 1.5
    readonly property real graphFillAlpha: 0.18

    // Timing
    readonly property int durFast: 120
    readonly property int durToggle: 180
    readonly property int durFade: 180
    readonly property int durIndicator: 150
    readonly property int durToastSlide: 220
    readonly property int durModal: 200
    readonly property int durSpinner: 900

    // Fans/telemetry refresh rates
    readonly property int telemetryHz: 10
    readonly property int fanVisHz: 4

    // Layout breakpoints (adaptive)
    readonly property int bpCompact: 1024
    readonly property int bpMid: 1366
    readonly property int bpWide: 1680
    readonly property int bpUltrawide: 1920

    function spacing(n) {
        if (n <= 4) return xs4
        if (n <= 8) return xs8
        if (n <= 12) return xs12
        if (n <= 16) return xs16
        if (n <= 20) return xs20
        if (n <= 24) return xs24
        if (n <= 32) return xs32
        if (n <= 40) return xs40
        return xs48
    }

    function duration(name) {
        switch (name) {
            case "fast": return durFast
            case "toggle": return durToggle
            case "fade": return durFade
            case "indicator": return durIndicator
            case "toast": return durToastSlide
            case "modal": return durModal
            case "spinner": return durSpinner
        }
        return durFade
    }
}
