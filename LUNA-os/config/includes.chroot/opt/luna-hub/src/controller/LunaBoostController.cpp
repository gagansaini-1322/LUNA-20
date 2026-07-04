// Luna OS Project
//
// LunaBoostController implementation. Models each optimization
// action as a row in the abstract list model, then rolls the
// per-action statuses up into one aggregate state.

#include "LunaBoostController.h"

#include "bridge/IpcClient.h"

#include <QPointer>
#include <QStringBuilder>

#include <exception>

namespace Luna::Hub {

namespace {

QList<LunaBoostController::Action> defaultActions() {
    QList<LunaBoostController::Action> list;
    auto add = [&](const QString &id, const QString &title, const QString &desc, const QString &risk) {
        LunaBoostController::Action a;
        a.id = id;
        a.title = title;
        a.description = desc;
        a.risk = risk;
        list.append(a);
    };
    add(QStringLiteral("cpu_governor_performance"),
        QStringLiteral("CPU governor → performance"),
        QStringLiteral("Sets scaling_governor=performance while LunaBoost is active."),
        QStringLiteral("low"));
    add(QStringLiteral("gpu_performance_mode"),
        QStringLiteral("GPU → performance mode"),
        QStringLiteral("Asks the driver to hold the GPU clocks high when supported."),
        QStringLiteral("low"));
    add(QStringLiteral("nice_game"),
        QStringLiteral("Renice active game process"),
        QStringLiteral("Best-effort renice of the active game PID to -5."),
        QStringLiteral("medium"));
    add(QStringLiteral("gamemode"),
        QStringLiteral("Feral gamemode"),
        QStringLiteral("Calls gamemoderun if installed; no-op otherwise."),
        QStringLiteral("low"));
    add(QStringLiteral("io_scheduler"),
        QStringLiteral("I/O scheduler → mq-deadline"),
        QStringLiteral("Adjusts the block queue scheduler where supported."),
        QStringLiteral("medium"));
    add(QStringLiteral("network_nice"),
        QStringLiteral("TCP nice raises throughput"),
        QStringLiteral("Bumps net.core.default_qdisc to fq_cobalt on supported kernels."),
        QStringLiteral("medium"));
    add(QStringLiteral("background_throttle"),
        QStringLiteral("Background process throttle"),
        QStringLiteral("Lowers nice/IO priority of background workloads."),
        QStringLiteral("low"));
    add(QStringLiteral("compositor_hints"),
        QStringLiteral("Compositor latency hints"),
        QStringLiteral("Sends a hint that the compositor should prefer short frames."),
        QStringLiteral("low"));
    return list;
}

} // namespace

LunaBoostController::LunaBoostController(QObject *parent)
    : QAbstractListModel(parent),
      m_actions(defaultActions()) {
}

LunaBoostController::~LunaBoostController() = default;

QStringList LunaBoostController::availableActions() const {
    QStringList list;
    list.reserve(m_actions.size());
    for (const Action &a : m_actions) {
        list.append(a.id);
    }
    return list;
}

bool LunaBoostController::active() const {
    return m_aggregate == AggregateState::Enabling
            || m_aggregate == AggregateState::On
            || m_aggregate == AggregateState::Partial;
}

void LunaBoostController::attachIpc(IpcClient *ipc) {
    m_ipc = ipc;
}

int LunaBoostController::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) {
        return 0;
    }
    return m_actions.size();
}

QVariant LunaBoostController::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_actions.size()) {
        return {};
    }
    const Action &a = m_actions.at(index.row());
    switch (role) {
        case IdRole: return a.id;
        case TitleRole: return a.title;
        case DescriptionRole: return a.description;
        case RiskRole: return a.risk;
        case StatusRole: return statusToString(a.status);
        case LastMessageRole: return a.lastMessage;
        case Qt::DisplayRole: return a.title;
        default:
            return {};
    }
}

QHash<int, QByteArray> LunaBoostController::roleNames() const {
    return {
        {IdRole, QByteArrayLiteral("actionId")},
        {TitleRole, QByteArrayLiteral("title")},
        {DescriptionRole, QByteArrayLiteral("description")},
        {RiskRole, QByteArrayLiteral("risk")},
        {StatusRole, QByteArrayLiteral("status")},
        {LastMessageRole, QByteArrayLiteral("lastMessage")},
    };
}

int LunaBoostController::idxFor(const QString &id) const {
    for (int i = 0; i < m_actions.size(); ++i) {
        if (m_actions.at(i).id == id) {
            return i;
        }
    }
    return -1;
}

LunaBoostController::ActionStatus LunaBoostController::statusFromString(const QString &s) {
    const QString v = s.trimmed().toLower();
    if (v == QStringLiteral("ok") || v == QStringLiteral("success")) return ActionStatus::Ok;
    if (v == QStringLiteral("running")) return ActionStatus::Running;
    if (v == QStringLiteral("failed") || v == QStringLiteral("error")) return ActionStatus::Failed;
    if (v == QStringLiteral("unsupported")) return ActionStatus::Unsupported;
    if (v == QStringLiteral("permission_required")) return ActionStatus::PermissionRequired;
    if (v == QStringLiteral("already_active")) return ActionStatus::AlreadyActive;
    return ActionStatus::Pending;
}

QString LunaBoostController::statusToString(ActionStatus s) const {
    switch (s) {
        case ActionStatus::Pending: return QStringLiteral("pending");
        case ActionStatus::Running: return QStringLiteral("running");
        case ActionStatus::Ok: return QStringLiteral("ok");
        case ActionStatus::Failed: return QStringLiteral("failed");
        case ActionStatus::Unsupported: return QStringLiteral("unsupported");
        case ActionStatus::PermissionRequired: return QStringLiteral("permission_required");
        case ActionStatus::AlreadyActive: return QStringLiteral("already_active");
    }
    return QStringLiteral("pending");
}

QString LunaBoostController::aggregateToString(AggregateState s) const {
    switch (s) {
        case AggregateState::Off: return QStringLiteral("off");
        case AggregateState::Enabling: return QStringLiteral("enabling");
        case AggregateState::On: return QStringLiteral("on");
        case AggregateState::Partial: return QStringLiteral("partial");
        case AggregateState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("off");
}

void LunaBoostController::setActionStatus(int row,
                                          ActionStatus status,
                                          const QString &message) {
    if (row < 0 || row >= m_actions.size()) {
        return;
    }
    Action &a = m_actions[row];
    a.status = status;
    a.lastMessage = message;
    const QModelIndex idx = index(row, 0);
    emit dataChanged(idx, idx, {StatusRole, LastMessageRole});
    emit actionCompleted(a.id, statusToString(status), message);
}

void LunaBoostController::enable() {
    try {
        if (m_aggregate == AggregateState::Enabling
                || m_aggregate == AggregateState::On
                || m_aggregate == AggregateState::Partial) {
            // idempotent: act as if a refresh.
            refresh();
            return;
        }
        for (int i = 0; i < m_actions.size(); ++i) {
            setActionStatus(i, ActionStatus::Running, QStringLiteral("dispatched"));
        }
        m_aggregate = AggregateState::Enabling;
        m_aggregateString = aggregateToString(m_aggregate);
        emit aggregateStateChanged();
        emit enableRequested();
        recomputeAggregate();
        if (m_ipc) {
            QVariantMap params;
            params.insert(QStringLiteral("state"), QStringLiteral("on"));
            m_ipc->submitCommand(QStringLiteral("lunaboost.set"), params);
        }
    } catch (const std::exception &ex) {
        m_lastError = QString::fromUtf8(ex.what());
        emit lastErrorChanged();
        emit errorOccurred(QStringLiteral("enable: ") + m_lastError);
    } catch (...) {
        m_lastError = QStringLiteral("enable: unknown failure");
        emit lastErrorChanged();
        emit errorOccurred(m_lastError);
    }
}

void LunaBoostController::disable() {
    try {
        for (int i = 0; i < m_actions.size(); ++i) {
            setActionStatus(i, ActionStatus::Pending, QStringLiteral("reset"));
        }
        m_aggregate = AggregateState::Off;
        m_aggregateString = aggregateToString(m_aggregate);
        emit aggregateStateChanged();
        emit disableRequested();
        recomputeAggregate();
        if (m_ipc) {
            QVariantMap params;
            params.insert(QStringLiteral("state"), QStringLiteral("off"));
            m_ipc->submitCommand(QStringLiteral("lunaboost.set"), params);
        }
    } catch (...) {
        emit errorOccurred(QStringLiteral("disable failed"));
    }
}

void LunaBoostController::refresh() {
    if (m_ipc) {
        m_ipc->submitCommand(QStringLiteral("lunaboost.get"), {});
    }
    // Without a daemon reply, the local heuristic remains.
    recomputeAggregate();
}

QString LunaBoostController::statusOf(const QString &id) const {
    const int row = idxFor(id);
    if (row < 0) {
        return {};
    }
    return statusToString(m_actions.at(row).status);
}

QString LunaBoostController::toggleAndReturnState() {
    if (active()) {
        disable();
    } else {
        enable();
    }
    return m_aggregateString;
}

QVariantList LunaBoostController::actionsVariant() const {
    QVariantList list;
    list.reserve(m_actions.size());
    for (int i = 0; i < m_actions.size(); ++i) {
        const Action &a = m_actions.at(i);
        QVariantMap m;
        m.insert(QStringLiteral("id"), a.id);
        m.insert(QStringLiteral("title"), a.title);
        m.insert(QStringLiteral("description"), a.description);
        m.insert(QStringLiteral("risk"), a.risk);
        m.insert(QStringLiteral("status"), statusToString(a.status));
        m.insert(QStringLiteral("lastMessage"), a.lastMessage);
        m.insert(QStringLiteral("row"), i);
        list.append(m);
    }
    return list;
}

QString LunaBoostController::aggregateStateName() const {
    return m_aggregateString;
}

void LunaBoostController::recomputeAggregate() {
    int ok = 0, pending = 0, failed = 0, running = 0, unsupported = 0;
    for (const Action &a : m_actions) {
        switch (a.status) {
            case ActionStatus::Ok: ++ok; break;
            case ActionStatus::Pending: ++pending; break;
            case ActionStatus::Failed: ++failed; break;
            case ActionStatus::Running: ++running; break;
            case ActionStatus::Unsupported: ++unsupported; break;
            case ActionStatus::PermissionRequired: ++failed; break;
            case ActionStatus::AlreadyActive: ++ok; break;
        }
    }
    m_ok = ok;
    m_pending = pending;
    m_failed = failed;
    m_running = running;
    emit countsChanged();

    if (m_aggregate == AggregateState::Enabling) {
        if (failed > 0 && ok > 0) {
            m_aggregate = AggregateState::Partial;
        } else if (pending == 0 && running == 0 && failed == 0 && unsupported == 0) {
            m_aggregate = AggregateState::On;
        } else if (pending == 0 && running == 0 && (failed > 0 || unsupported > 0)) {
            m_aggregate = AggregateState::Partial;
        } else {
            return; // stay in Enabling
        }
        m_aggregateString = aggregateToString(m_aggregate);
        emit aggregateStateChanged();
    }
}

}  // namespace Luna::Hub
