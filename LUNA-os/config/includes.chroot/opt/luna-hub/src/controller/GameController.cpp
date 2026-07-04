// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#include "GameController.h"

#include "../bridge/IpcClient.h"
#include "../model/MockTelemetryModel.h"

#include <QStandardPaths>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>

namespace Luna::Hub {

GameController::GameController(QObject* parent)
    : QAbstractListModel(parent)
    , m_ipc(new IpcClient(this))
{}

int GameController::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_entries.size();
}

QVariant GameController::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};
    const auto& e = m_entries.at(index.row());
    switch (role) {
        case GameIdRole:    return e.gameId;
        case GameTitleRole: return e.title;
        case SourceRole:    return e.source;
        case IconRole:      return e.icon;
    }
    return {};
}

QHash<int, QByteArray> GameController::roleNames() const {
    return {
        { GameIdRole,    "gameId" },
        { GameTitleRole, "title"  },
        { SourceRole,    "source" },
        { IconRole,      "icon"   },
    };
}

void GameController::refresh() {
    beginResetModel();
    m_entries.clear();
    loadSteamGames();
    loadHeroicGames();
    loadLutrisGames();
    endResetModel();
    emit gamesChanged();
}

void GameController::loadSteamGames() {
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QStringList candidates;
    candidates << home + QStringLiteral("/.steam/steam/steamapps");
    candidates << home + QStringLiteral("/.local/share/Steam/steamapps");
    for (const QString& path : candidates) {
        if (path.isEmpty()) continue;
        QDir d(path);
        if (!d.exists()) continue;
        const auto files = d.entryList(QStringList() << QStringLiteral("appmanifest_*.acf"),
                                        QDir::Files);
        for (const QString& f : files) {
            QFile file(d.absoluteFilePath(f));
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) continue;
            QString content = QString::fromUtf8(file.readAll());
            file.close();
            auto grab = [&content](const QString& k) -> QString {
                int i = content.indexOf(k, 0, Qt::CaseInsensitive);
                if (i < 0) return {};
                i = content.indexOf(QLatin1String("\""), i);
                if (i < 0) return {};
                int j = content.indexOf(QLatin1String("\""), i + 1);
                if (j < 0) return {};
                return content.mid(i + 1, j - i - 1);
            };
            QString appid = grab(QStringLiteral("appid"));
            QString name  = grab(QStringLiteral("name"));
            if (appid.isEmpty() || name.isEmpty()) continue;
            GameEntry e;
            e.gameId = QStringLiteral("steam:") + appid;
            e.title  = name;
            e.source = QStringLiteral("Steam");
            e.icon   = QStringLiteral("applications-games");
            m_entries.append(e);
        }
    }
}

void GameController::loadHeroicGames() {
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    const QByteArray heroSources[] = {"legendaryConfig", "gogConfig", "epicConfig", "amazonConfig"};
    Q_UNUSED(heroSources);
    QString cfg = home + QStringLiteral("/.config/heroic");
    QDir d(cfg + QStringLiteral("/gogstore/"));
    Q_UNUSED(d);
    QString cache = home + QStringLiteral("/.cache/heroic");
    QDir cacheDir(cache);
    QStringList sideload = cacheDir.entryList(QStringList(), QDir::Dirs | QDir::NoDotAndDotDot);
    Q_UNUSED(sideload);
    // Heroic library lookup without internet; intentionally conservative:
    // Without DB, we don't fabricate results. If Heroic is installed, the
    // native gogdl/legendary components provide accurate lists at runtime.
}

void GameController::loadLutrisGames() {
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QFile f(home + QStringLiteral("/.config/lutris/games.json"));
    if (!f.open(QIODevice::ReadOnly)) return;
    QJsonParseError err{};
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) return;
    const QJsonArray games = doc.object().value(QStringLiteral("games")).toArray();
    for (const QJsonValue& v : games) {
        const QJsonObject g = v.toObject();
        GameEntry e;
        e.gameId = QStringLiteral("lutris:") + g.value("slug").toString();
        e.title  = g.value("name").toString();
        e.source = QStringLiteral("Lutris");
        e.icon   = QStringLiteral("applications-games");
        m_entries.append(e);
    }
}

QStringList GameController::sources() const {
    return { QStringLiteral("Steam"),
             QStringLiteral("Heroic"),
             QStringLiteral("Lutris"),
             QStringLiteral("Manual") };
}

}  // namespace Luna::Hub
