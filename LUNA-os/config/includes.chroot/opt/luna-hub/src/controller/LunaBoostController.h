// Luna OS Project
//
// Tracks the individual optimization actions triggered by LunaBoost
// (priority tuning, gamemode, GPU performance mode, I/O elevator,
// renice, etc.) and rolls them up into an aggregate state machine
// implemented in state.rs (Off, Enabling, On, Partial, Error).
// QML only ever sees strings; the C++ enums stay opaque.

#ifndef LUNA_LUNA_BOOST_CONTROLLER_H
#define LUNA_LUNA_BOOST_CONTROLLER_H

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

class LunaBoostController : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString aggregateState READ aggregateState NOTIFY aggregateStateChanged)
    Q_PROPERTY(QStringList availableActions READ availableActions CONSTANT)
    Q_PROPERTY(bool active READ active NOTIFY aggregateStateChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(int okCount READ okCount NOTIFY countsChanged)
    Q_PROPERTY(int pendingCount READ pendingCount NOTIFY countsChanged)
    Q_PROPERTY(int failedCount READ failedCount NOTIFY countsChanged)
    Q_PROPERTY(int runningCount READ runningCount NOTIFY countsChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        DescriptionRole,
        RiskRole,
        StatusRole,
        LastMessageRole,
    };
    Q_ENUM(Roles)

    enum class ActionStatus {
        Pending = 0,
        Running,
        Ok,
        Failed,
        Unsupported,
        PermissionRequired,
        AlreadyActive,
    };

    enum class AggregateState {
        Off,
        Enabling,
        On,
        Partial,
        Error,
    };

    explicit LunaBoostController(QObject *parent = nullptr);
    ~LunaBoostController() override;

    QString aggregateState() const { return m_aggregateString; }
    QStringList availableActions() const;
    bool active() const;
    QString lastError() const { return m_lastError; }
    int okCount() const { return m_ok; }
    int pendingCount() const { return m_pending; }
    int failedCount() const { return m_failed; }
    int runningCount() const { return m_running; }

    void attachIpc(IpcClient *ipc);

    Q_INVOKABLE void enable();
    Q_INVOKABLE void disable();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString statusOf(const QString &id) const;
    Q_INVOKABLE QString toggleAndReturnState();

    Q_INVOKABLE QVariantList actionsVariant() const;
    Q_INVOKABLE QString aggregateStateName() const;

    // QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

Q_SIGNALS:
    void aggregateStateChanged();
    void countsChanged();
    void lastErrorChanged();
    void enableRequested();
    void disableRequested();
    void actionStarted(const QString &id);
    void actionCompleted(const QString &id, const QString &status, const QString &message);
    void errorOccurred(const QString &message);

private:
    struct Action {
        QString id;
        QString title;
        QString description;
        QString risk;       // low / medium / high
        ActionStatus status = ActionStatus::Pending;
        QString lastMessage;
    };

    int idxFor(const QString &id) const;
    void setActionStatus(int row, ActionStatus status, const QString &message);
    void recomputeAggregate();
    QString statusToString(ActionStatus s) const;
    QString aggregateToString(AggregateState s) const;
    static ActionStatus statusFromString(const QString &s);

    QPointer<IpcClient> m_ipc;
    QList<Action> m_actions;
    AggregateState m_aggregate = AggregateState::Off;
    QString m_aggregateString = QStringLiteral("off");
    QString m_lastError;
    int m_ok = 0;
    int m_pending = 0;
    int m_failed = 0;
    int m_running = 0;
};

}  // namespace Luna::Hub

#endif // LUNA_LUNA_BOOST_CONTROLLER_H
