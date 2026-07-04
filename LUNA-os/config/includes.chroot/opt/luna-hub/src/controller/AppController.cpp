// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#include "AppController.h"

#include "TelemetryController.h"
#include "PerformanceController.h"
#include "GameController.h"
#include "QueueController.h"
#include "SettingsController.h"
#include "NavigationController.h"
#include "NotificationController.h"
#include "FanController.h"
#include "SystemInfoController.h"
#include "LunaBoostController.h"

#include <QQmlEngine>

namespace Luna::Hub {

AppController::AppController(QObject* parent)
    : QObject(parent)
    , m_telemetry(new TelemetryController(this))
    , m_performance(new PerformanceController(this))
    , m_games(new GameController(this))
    , m_queue(new QueueController(this))
    , m_settings(new SettingsController(this))
    , m_navigation(new NavigationController(this))
    , m_notifications(new NotificationController(this))
    , m_fan(new FanController(this))
    , m_systemInfo(new SystemInfoController(this))
    , m_lunaBoost(new LunaBoostController(this))
{}

AppController::~AppController() {
    shutdown();
}

bool AppController::initialize() {
    if (m_initialized) return true;

    m_telemetry->startMonitoring();
    m_games->refresh();
    m_queue->load();
    m_systemInfo->refresh();

    m_initialized = true;
    emit ready();
    return true;
}

void AppController::shutdown() {
    if (!m_initialized) return;
    emit shuttingDown();
    if (m_telemetry) m_telemetry->stopMonitoring();
    m_initialized = false;
}

}  // namespace Luna::Hub
