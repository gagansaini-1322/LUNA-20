import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    loopSlides: true
    mouseNavigation: true
    arrowNavigation: true
    keyShortcutsEnabled: true
    titleColor: "#00b4ff"
    textColor: "#ffffff"
    fontFamily: "Noto Sans"

    Timer {
        id: advanceTimer
        interval: 5000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        title: "Welcome to LUNA OS"
        centeredText: "The installer will guide you through\nsetting up your new gaming system."
    }

    Slide {
        title: "Features"
        content: [
            "Lightweight Arch-based gaming OS",
            "KDE Plasma desktop environment",
            "Steam, Lutris, Wine pre-installed",
            "Optimized for gaming performance"
        ]
    }

    Slide {
        title: "Gaming Ready"
        content: [
            "Steam with Proton support",
            "Lutris game manager",
            "Wine for Windows games",
            "MangoHud performance overlay",
            "GameMode optimizations"
        ]
    }

    Slide {
        title: "Join Our Community"
        centeredText: "Visit https://lunaos.org\nfor support and documentation."
    }

    function onActivate() {
        console.log("Slideshow activated");
        presentation.currentSlide = 0;
    }

    function onLeave() {
        console.log("Slideshow deactivated");
    }
}
