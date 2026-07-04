// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#include "QueueController.h"

#include <QSettings>

namespace Luna::Hub {

QueueController::QueueController(QObject* parent) : QAbstractListModel(parent) {}

int QueueController::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_entries.size();
}

QVariant QueueController::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};
    const auto& e = m_entries.at(index.row());
    switch (role) {
        case GameIdRole:    return e.gameId;
        case GameTitleRole: return e.title;
        case PriorityRole:  return e.priority;
        case StatusRole:    return e.status;
        case ProgressRole:  return e.progress;
    }
    return {};
}

QHash<int, QByteArray> QueueController::roleNames() const {
    return {
        { GameIdRole,    "gameId"   },
        { GameTitleRole, "title"    },
        { PriorityRole,  "priority" },
        { StatusRole,    "status"   },
        { ProgressRole,  "progress" },
    };
}

void QueueController::load() {
    beginResetModel();
    m_entries.clear();
    QSettings s;
    const int n = s.beginReadArray("luna/queue");
    for (int i = 0; i < n; ++i) {
        s.setArrayIndex(i);
        QueueEntry e;
        e.gameId   = s.value("id").toString();
        e.title    = s.value("title").toString();
        e.priority = s.value("priority", 1).toInt();
        e.status   = s.value("status", QStringLiteral("Waiting")).toString();
        e.progress = s.value("progress", 0).toInt();
        m_entries.append(e);
    }
    s.endArray();
    endResetModel();
    emit queueChanged();
}

void QueueController::seedDefaults() {
    if (!m_entries.isEmpty()) return;
    addGame(QStringLiteral("manual:cs2"),   QStringLiteral("Counter-Strike 2"), 0);
    addGame(QStringLiteral("manual:valor"), QStringLiteral("VALORANT"), 0);
}

bool QueueController::addGame(const QString& id, const QString& title, int priority) {
    if (id.isEmpty() || title.isEmpty()) return false;
    if (indexOf(id) >= 0) return false;
    QueueEntry e;
    e.gameId   = id;
    e.title    = title;
    e.priority = qBound(0, priority, 2);
    e.status   = QStringLiteral("Waiting");
    e.progress = 0;
    beginInsertRows({}, m_entries.size(), m_entries.size());
    m_entries.append(e);
    endInsertRows();
    emit queueChanged();
    return true;
}

bool QueueController::removeGame(const QString& id) {
    int r = indexOf(id);
    if (r < 0) return false;
    beginRemoveRows({}, r, r);
    m_entries.removeAt(r);
    endRemoveRows();
    emit queueChanged();
    return true;
}

bool QueueController::changePriority(const QString& id, int priority) {
    int r = indexOf(id);
    if (r < 0) return false;
    m_entries[r].priority = qBound(0, priority, 2);
    emitFor(r);
    emit queueChanged();
    return true;
}

bool QueueController::moveUp(const QString& id) {
    int r = indexOf(id);
    if (r <= 0) return false;
    m_entries.swapItemsAt(r, r - 1);
    emit dataChanged(index(r - 1), index(r));
    emit queueChanged();
    return true;
}

bool QueueController::moveDown(const QString& id) {
    int r = indexOf(id);
    if (r < 0 || r + 1 >= m_entries.size()) return false;
    m_entries.swapItemsAt(r, r + 1);
    emit dataChanged(index(r), index(r + 1));
    emit queueChanged();
    return true;
}

bool QueueController::pauseGame(const QString& id) {
    int r = indexOf(id);
    if (r < 0) return false;
    m_entries[r].status = QStringLiteral("Paused");
    emitFor(r);
    emit queueChanged();
    return true;
}

bool QueueController::resumeGame(const QString& id) {
    int r = indexOf(id);
    if (r < 0) return false;
    m_entries[r].status = QStringLiteral("Active");
    emitFor(r);
    emit queueChanged();
    return true;
}

void QueueController::emitFor(int row) {
    QModelIndex i = index(row);
    emit dataChanged(i, i);
}

int QueueController::indexOf(const QString& id) const {
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).gameId == id) return i;
    }
    return -1;
}

}  // namespace Luna::Hub
