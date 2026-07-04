// Luna OS Project
//
// Implementation of the singleton registry. Constructed in dependency
// order so e.g. PerformanceController can be created before AppController
// but still receive AppController as its parent object.

#include "Controllers.h"

#include "AppController.h"
#include "TelemetryController.h"
#include "PerformanceController.h"
#include "FanController.h"
#include "LunaBoostController.h"
#include "SettingsController.h"
#include "NotificationController.h"
#include "NavigationController.h"
#include "SystemInfoController.h"
#include "QueueController.h"
#include "GameController.h"

#include "bridge/IpcClient.h"

#include <QQmlContext>
#include <QQmlEngine>
#include <QtQml>

namespace Luna::Hub {

namespace Engine {

namespace {

// Long-lived shared instances. Parent ownership flows through these.
IpcClient              *g_ipc      = nullptr;
AppController          *g_app      = nullptr;
TelemetryController    *g_telem    = nullptr;
PerformanceController  *g_perf     = nullptr;
FanController          *g_fan      = nullptr;
LunaBoostController    *g_boost    = nullptr;
SettingsController     *g_settings = nullptr;
NotificationController *g_notify   = nullptr;
NavigationController   *g_nav      = nullptr;
SystemInfoController   *g_sys      = nullptr;
QueueController        *g_queue    = nullptr;
GameController         *g_games    = nullptr;

bool g_initialized = false;

void exposeSingleton(QQmlApplicationEngine *engine,
                     const char *name,
                     QObject *instance) {
    if (!engine || !instance) {
        return;
    }
    QQmlContext *root = engine->rootContext();
    if (!root) {
        return;
    }
    // qmlRegisterSingletonInstance gives us a real singleton the QML
    // can `import LunaHub` against. We use it both for typed objects
    // (so QML can hold Q_PROPERTY bindings) and as the context-level
    // fallback for convenient JS access.
    const int typeId = qmlRegisterSingletonInstance(instance->metaObject()->className(),
                                                    "LunaHub",
                                                    1, 0,
                                                    QString::fromLatin1(name).toLower(),
                                                    instance);
    if (typeId != -1) {
        (void)typeId;
    }
    root->setContextProperty(QString::fromLatin1(name), instance);
}

} // namespace

void registerTypes() {
    if (g_initialized) {
        return;
    }
    g_initialized = true;

    g_ipc = new IpcClient();
    g_ipc->connectToServer();

    g_settings = new SettingsController();
    g_nav      = new NavigationController();
    g_sys      = new SystemInfoController();
    g_notify   = new NotificationController();
    g_perf     = new PerformanceController();
    g_perf->attachIpc(g_ipc);
    g_fan      = new FanController();
    g_fan->attachIpc(g_ipc);
    g_boost    = new LunaBoostController();
    g_boost->attachIpc(g_ipc);
    g_queue    = new QueueController();
    g_games    = new GameController();
    g_games->attachIpc(g_ipc);
    g_telem    = new TelemetryController();
    g_telem->attachIpc(g_ipc);
    g_app      = new AppController();

    g_app->_installControllers(g_ipc,
                               g_telem,
                               g_perf,
                               g_fan,
                               g_boost,
                               g_settings,
                               g_notify,
                               g_nav,
                               g_sys,
                               g_queue,
                               g_games);
}

void registerReferences(QQmlApplicationEngine *engine) {
    if (!engine) {
        return;
    }
    registerTypes();

    exposeSingleton(engine, "AppController",   g_app);
    exposeSingleton(engine, "Telemetry",       g_telem);
    exposeSingleton(engine, "Performance",     g_perf);
    exposeSingleton(engine, "Fans",            g_fan);
    exposeSingleton(engine, "LunaBoost",       g_boost);
    exposeSingleton(engine, "Settings",        g_settings);
    exposeSingleton(engine, "Notifications",   g_notify);
    exposeSingleton(engine, "Navigation",      g_nav);
    exposeSingleton(engine, "SystemInfo",      g_sys);
    exposeSingleton(engine, "IpcClient",       g_ipc);

    QQmlContext *root = engine->rootContext();
    if (root) {
        root->setContextProperty(QStringLiteral("QueueModel"), g_queue);
        root->setContextProperty(QStringLiteral("GamesModel"), g_games);
    }
}

AppController          *appController()  { return g_app;      }
TelemetryController    *telemetry()      { return g_telem;    }
PerformanceController  *performance()    { return g_perf;     }
FanController          *fans()           { return g_fan;      }
LunaBoostController    *lunaBoost()      { return g_boost;    }
SettingsController     *settings()       { return g_settings; }
NotificationController *notifications()  { return g_notify;   }
NavigationController   *navigation()     { return g_nav;      }
SystemInfoController   *systemInfo()     { return g_sys;      }
QueueController        *queue()          { return g_queue;    }
GameController         *games()          { return g_games;    }
IpcClient              *ipc()            { return g_ipc;      }

} // namespace Engine
}  // namespace Luna::Hub
