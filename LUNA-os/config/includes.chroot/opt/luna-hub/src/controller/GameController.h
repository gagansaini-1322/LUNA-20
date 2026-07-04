// Luna OS Project
//
// Detects games installed by various Luna-supported launchers
// (Steam, Heroic, Lutris) and any user-added manual entry. The
// resulting list is exposed through QAbstractListModel with roles
// (id, title, source, icon, runtime) plus Q_PROPERTY signals.

#ifndef LUNA_GAME_CONTROLLER_H
#define LUNA_GAME_CONTROLLER_H

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QStringList>
#include <QVariantList>

namespace Luna::Hub {

class IpcClient;

class GameController : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QStringList knownSources READ knownSources CONSTANT)
    Q_PROPERTY(int gameCount READ rowCountQml NOTIFY gamesChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        SourceRole,
        IconRole,
        RuntimeRole,
        PathRole,
        DetectedRole,
    };
    Q_ENUM(Roles)

    struct DetectedGame {
        QString id;
        QString title;
        QString source;       // steam | heroic | lutris | manual
        QString icon;         // path or launcher-style id
        QString runtime;      // native | wine | proton | heroic | browser
        QString installPath;
        qint64 detectedEpochMs = 0;
    };

    explicit GameController(QObject *parent = nullptr);
    ~GameController() override;

    QStringList knownSources() const;
    int rowCountQml() const { return m_games.size(); }

    Q_INVOKABLE void rescan();
    Q_INVOKABLE QVariantList gamesVariant() const;
    Q_INVOKABLE QVariantMap findById(const QString &id) const;
    Q_INVOKABLE QString launchCommand(const QString &gameId) const;

    Q_INVOKABLE QString addManualGame(const QString &id,
                                      const QString &title,
                                      const QString &runtime,
                                      const QString &installPath);
    Q_INVOKABLE bool removeGame(const QString &id);
    Q_INVOKABLE QVariantList gamesBySource(const QString &source) const;
    Q_INVOKABLE int countBySource(const QString &source) const;

    void attachIpc(IpcClient *ipc);

    // QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

Q_SIGNALS:
    void gamesChanged();
    void scanStarted();
    void scanFinished(int count);
    void errorOccurred(const QString &message);

private:
    int idxForId(const QString &id) const;
    void emitRowChanged(int row);
    void replaceAll(const QList<DetectedGame> &next);
    void loadManual();
    void persistManual();
    void detectSteam(QList<DetectedGame> *out) const;
    void detectHeroic(QList<DetectedGame> *out) const;
    void detectLutris(QList<DetectedGame> *out) const;

    QPointer<IpcClient> m_ipc;
    QList<DetectedGame> m_games;
};

}  // namespace Luna::Hub

#endif // LUNA_GAME_CONTROLLER_H
