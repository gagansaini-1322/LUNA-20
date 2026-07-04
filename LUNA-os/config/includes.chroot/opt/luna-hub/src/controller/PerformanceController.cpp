// Luna OS Project
//
// PerformanceController implementation. Uses `powerprofilesctl set-profile`
// for the underlying daemon and falls back to a stored intended profile
// if the daemon is offline.

#include "PerformanceController.h"

#include "bridge/IpcClient.h"

#include <QFile>
#include <QIODevice>
#include <QPointer>
#include <QProcess>
#include <QSettings>
#include <QStringBuilder>

#include <exception>

namespace Luna::Hub {

namespace {

const QStringList kProfiles{
    QStringLiteral("eco"),
    QStringLiteral("balanced"),
    QStringLiteral("performance"),
    QStringLiteral("luna_boost"),
};

constexpr const char *kPpctlCmd = "powerprofilesctl";

} // namespace

PerformanceController::PerformanceController(QObject *parent)
    : QObject(parent) {
    QSettings store(QSettings::IniFormat,
                    QSettings::UserScope,
                    QStringLiteral("LunaOS"),
                    QStringLiteral("luna-hub"));
    m_current = normalize(store.value(QStringLiteral("lastProfile"), QStringLiteral("balanced")).toString());
    m_ppctlAvailable = fileExists(detectPowerprofiles());
    m_lastDetail = QStringLiteral("Power-profiles daemon status: ")
                   + (m_ppctlAvailable ? QStringLiteral("available") : QStringLiteral("not detected"));
}

PerformanceController::~PerformanceController() = default;

void PerformanceController::attachIpc(IpcClient *ipc) {
    m_ipc = ipc;
}

QStringList PerformanceController::availableProfiles() const {
    return kProfiles;
}

QString PerformanceController::normalize(const QString &raw) const {
    const QString s = raw.trimmed().toLower();
    if (s == QStringLiteral("eco") || s == QStringLiteral("power-saver")) {
        return QStringLiteral("eco");
    }
    if (s == QStringLiteral("balanced") || s == QStringLiteral("default")) {
        return QStringLiteral("balanced");
    }
    if (s == QStringLiteral("performance") || s == QStringLiteral("speed")) {
        return QStringLiteral("performance");
    }
    if (s == QStringLiteral("luna_boost") || s == QStringLiteral("luna-boost") || s == QStringLiteral("lunaboost")) {
        return QStringLiteral("luna_boost");
    }
    return QStringLiteral("balanced");
}

bool PerformanceController::fileExists(const QString &p) const {
    return QFile::exists(p);
}

QString PerformanceController::detectPowerprofiles() const {
    const QStringList candidates{
        QStringLiteral("/usr/bin/powerprofilesctl"),
        QStringLiteral("/usr/local/bin/powerprofilesctl"),
        QStringLiteral("/usr/sbin/powerprofilesctl"),
        QStringLiteral("/usr/local/sbin/powerprofilesctl"),
    };
    for (const QString &c : candidates) {
        if (fileExists(c)) {
            return c;
        }
    }
    // Probe via `which` so custom paths still work.
    QProcess proc;
    proc.start(QStringLiteral("which"), {QString::fromLatin1(kPpctlCmd)});
    if (proc.waitForFinished(500) && proc.exitCode() == 0) {
        const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!out.isEmpty()) {
            return out;
        }
    }
    return QString::fromLatin1(kPpctlCmd);
}

QString PerformanceController::powerprofilesctlPath() const {
    return detectPowerprofiles();
}

QString PerformanceController::run(const QString &mode) {
    const QString bin = powerprofilesctlPath();
    QProcess proc;
    proc.start(bin, {QStringLiteral("set-profile"), mode});
    if (!proc.waitForStarted(1500)) {
        return QStringLiteral("powerprofilesctl not executable");
    }
    if (!proc.waitForFinished(3000)) {
        proc.kill();
        return QStringLiteral("powerprofilesctl timeout");
    }
    const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
    if (proc.exitCode() != 0) {
        return err.isEmpty() ? QStringLiteral("powerprofilesctl exit ") + QString::number(proc.exitCode()) : err;
    }
    return out;
}

QString PerformanceController::profileDetailsText() const {
    return m_lastDetail;
}

QString PerformanceController::currentProfile() const {
    return m_current;
}

void PerformanceController::refresh() {
    try {
        if (m_ppctlAvailable) {
            QProcess proc;
            proc.start(powerprofilesctlPath(), {QStringLiteral("get-profile")});
            if (proc.waitForFinished(2000) && proc.exitCode() == 0) {
                const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
                const QString normalized = normalize(out);
                if (normalized != m_current) {
                    m_current = normalized;
                    emit currentProfileChanged();
                }
            }
            QProcess list;
            list.start(powerprofilesctlPath(), {QStringLiteral("list")});
            if (list.waitForFinished(2000) && list.exitCode() == 0) {
                m_lastDetail = QString::fromUtf8(list.readAllStandardOutput()).trimmed();
                emit profileStateChanged();
            }
        } else {
            m_lastDetail = QStringLiteral("power-profiles daemon not available — using Luna Hub defaults");
            emit profileStateChanged();
        }
        if (m_ipc) {
            m_ipc->submitCommand(QStringLiteral("profile.get"), {});
        }
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("refresh: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("refresh: unknown failure"));
    }
}

QString PerformanceController::setProfile(const QString &name) {
    try {
        const QString target = normalize(name);
        if (!kProfiles.contains(target)) {
            return QStringLiteral("unknown profile: ") + name;
        }
        emit profileApplicationRequested(target);

        QSettings store(QSettings::IniFormat,
                        QSettings::UserScope,
                        QStringLiteral("LunaOS"),
                        QStringLiteral("luna-hub"));
        store.setValue(QStringLiteral("lastProfile"), target);

        if (target != QStringLiteral("luna_boost") && m_ppctlAvailable) {
            const QString result = run(target);
            if (result.startsWith(QStringLiteral("powerprofilesctl "))) {
                // fallback: still update internal state but report it to the user.
                m_lastDetail = result;
                emit profileStateChanged();
                if (target == m_current) {
                    return QString();
                }
            }
        }

        if (target != m_current) {
            m_current = target;
            emit currentProfileChanged();
        }
        emit profileStateChanged();
        if (m_ipc) {
            QVariantMap params;
            params.insert(QStringLiteral("profile"), target);
            m_ipc->submitCommand(QStringLiteral("profile.set"), params);
        }
        return QString();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("setProfile: ") + QString::fromUtf8(ex.what()));
        return QStringLiteral("setProfile failed");
    } catch (...) {
        emit errorOccurred(QStringLiteral("setProfile: unknown failure"));
        return QStringLiteral("setProfile failed");
    }
}

}  // namespace Luna::Hub
