// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QCoreApplication>
#include <QQmlContext>
#include <QDir>
#include <QStandardPaths>

#include "controller/AppController.h"

namespace Luna::Hub {

static void registerTypes() {
    qmlRegisterUncreatableType<AppController>(
        "LunaHub", 1, 0, "AppController",
        QStringLiteral("Created in C++")
    );
}

}  // namespace Luna::Hub

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("Luna OS Project"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("luna-os.local"));
    QCoreApplication::setApplicationName(QStringLiteral("Luna Hub"));
    QCoreApplication::setApplicationDisplayName(QStringLiteral("Luna Hub"));
    QCoreApplication::setApplicationVersion(QStringLiteral(LUNA_HUB_VERSION));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    Luna::Hub::registerTypes();

    QQmlApplicationEngine engine;

    Luna::Hub::AppController appController;
    appController.initialize();

    auto* rootContext = engine.rootContext();
    rootContext->setContextProperty(QStringLiteral("appController"), &appController);
    rootContext->setContextProperty(
        QStringLiteral("lunaHub"), &appController);

#ifdef LUNA_HUB_QML_DIR
    engine.addImportPath(QString::fromUtf8(LUNA_HUB_QML_DIR));
#endif

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("LunaHub"), QStringLiteral("App"));

    if (engine.rootObjects().isEmpty())
        return EXIT_FAILURE;

    const int rc = app.exec();
    appController.shutdown();
    return rc;
}
