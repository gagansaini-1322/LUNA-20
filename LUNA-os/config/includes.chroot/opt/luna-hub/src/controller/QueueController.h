// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QString>
#include <QVector>

namespace Luna::Hub {

struct QueueEntry {
    QString gameId;
    QString title;
    int     priority = 1;     // 0=High 1=Med 2=Low
    QString status   = QStringLiteral("Waiting");
    int     progress = 0;     // 0..100
};

class QueueController : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY queueChanged)
public:
    enum Roles {
        GameIdRole = Qt::UserRole + 1,
        GameTitleRole,
        PriorityRole,
        StatusRole,
        ProgressRole,
    };
    explicit QueueController(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void load();
    Q_INVOKABLE bool addGame(const QString& id, const QString& title, int priority);
    Q_INVOKABLE bool removeGame(const QString& id);
    Q_INVOKABLE bool changePriority(const QString& id, int priority);
    Q_INVOKABLE bool moveUp(const QString& id);
    Q_INVOKABLE bool moveDown(const QString& id);
    Q_INVOKABLE bool pauseGame(const QString& id);
    Q_INVOKABLE bool resumeGame(const QString& id);
    Q_INVOKABLE void seedDefaults();

signals:
    void queueChanged();

private:
    void emitFor(int row);
    int  indexOf(const QString& id) const;

    QVector<QueueEntry> m_entries;
};

}  // namespace Luna::Hub
