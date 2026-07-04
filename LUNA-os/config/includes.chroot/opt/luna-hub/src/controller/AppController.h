// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#pragma once

#include <QObject>
#include <QPointer>

namespace Luna::Hub {

class TelemetryController;
class PerformanceController;
class GameController;
class QueueController;
class SettingsController;
class NotificationController;
class FanController;
class SystemInfoController;
class NavigationController;
class LunaBoostController;

class AppController : public QObject {
    Q_OBJECT
    Q_PROPERTY(Luna::Hub::TelemetryController*    telemetry    READ telemetry    CONSTANT)
    Q_PROPERTY(Luna::Hub::PerformanceController*  performance  READ performance  CONSTANT)
    Q_PROPERTY(Luna::Hub::GameController*         games        READ games        CONSTANT)
    Q_PROPERTY(Luna::Hub::QueueController*        queue        READ queue        CONSTANT)
    Q_PROPERTY(Luna::Hub::SettingsController*     settings     READ settings     CONSTANT)
    Q_PROPERTY(Luna::Hub::NavigationController*   navigation   READ navigation   CONSTANT)
    Q_PROPERTY(Luna::Hub::NotificationController* notifications READ notifications CONSTANT)
    Q_PROPERTY(Luna::Hub::FanController*          fan          READ fan          CONSTANT)
    Q_PROPERTY(Luna::Hub::SystemInfoController*   systemInfo   READ systemInfo   CONSTANT)
    Q_PROPERTY(Luna::Hub::LunaBoostController*    lunaBoost    READ lunaBoost    CONSTANT)
    Q_PROPERTY(QString buildVersion READ buildVersion CONSTANT)

public:
    explicit AppController(QObject* parent = nullptr);
    ~AppController() override;

    Q_INVOKABLE bool initialize();
    Q_INVOKABLE void shutdown();

    TelemetryController*   telemetry()    const { return m_telemetry;    }
    PerformanceController* performance()  const { return m_performance;  }
    GameController*        games()        const { return m_games;        }
    QueueController*       queue()        const { return m_queue;        }
    SettingsController*    settings()     const { return m_settings;     }
    NavigationController*  navigation()   const { return m_navigation;   }
    NotificationController* notifications()const { return m_notifications;}
    FanController*         fan()          const { return m_fan;          }
    SystemInfoController*  systemInfo()   const { return m_systemInfo;   }
    LunaBoostController*   lunaBoost()    const { return m_lunaBoost;    }

    QString buildVersion() const { return QStringLiteral("1.0.0"); }

signals:
    void ready();
    void shuttingDown();

private:
    QPointer<TelemetryController>    m_telemetry;
    QPointer<PerformanceController>  m_performance;
    QPointer<GameController>         m_games;
    QPointer<QueueController>        m_queue;
    QPointer<SettingsController>     m_settings;
    QPointer<NavigationController>   m_navigation;
    QPointer<NotificationController> m_notifications;
    QPointer<FanController>          m_fan;
    QPointer<SystemInfoController>   m_systemInfo;
    QPointer<LunaBoostController>    m_lunaBoost;

    bool m_initialized = false;
};

}  // namespace Luna::Hub
