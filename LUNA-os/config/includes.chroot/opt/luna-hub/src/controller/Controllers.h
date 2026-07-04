// Luna OS Project
//
// Singleton registry. Constructs all long-lived controllers, wires them
// together, and exposes them to QML either as context properties or as
// QML singletons via qmlRegisterSingletonInstance.
//
// QML side obtains:
//   AppController  (singleton, the root)
//   Telemetry
//   Performance
//   Fans
//   LunaBoost
//   Settings
//   Notifications
//   Navigation
//   SystemInfo
//   Queue         (QAbstractListModel)
//   Games         (QAbstractListModel)
//
// All other controllers fan-out from these.

#ifndef LUNA_CONTROLLERS_H
#define LUNA_CONTROLLERS_H

#include <QObject>
#include <QQmlApplicationEngine>

namespace Luna::Hub {

class IpcClient;
class AppController;
class TelemetryController;
class PerformanceController;
class FanController;
class LunaBoostController;
class SettingsController;
class NotificationController;
class NavigationController;
class SystemInfoController;
class QueueController;
class GameController;

namespace Engine {

void registerTypes();
void registerReferences(QQmlApplicationEngine *engine);

// Static accessors for C++ callers (so other controllers can resolve
// the shared instances if they need to cross-reference at startup).
AppController        *appController();
TelemetryController  *telemetry();
PerformanceController *performance();
FanController        *fans();
LunaBoostController  *lunaBoost();
SettingsController   *settings();
NotificationController *notifications();
NavigationController *navigation();
SystemInfoController *systemInfo();
QueueController      *queue();
GameController       *games();
IpcClient            *ipc();

} // namespace Engine
}  // namespace Luna::Hub

#endif // LUNA_CONTROLLERS_H
