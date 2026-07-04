// Luna OS Project
//
// FanController implementation. Probes /sys/class/hwmon for fan RPM,
// PWM, and PWM enable to classify what the platform allows.

#include "FanController.h"

#include "bridge/IpcClient.h"
#include "sysinfo/SysInfo.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPointer>
#include <QStringBuilder>

#include <exception>

namespace Luna::Hub {

namespace {

const QStringList kProfiles{
    QStringLiteral("silent"),
    QStringLiteral("balanced"),
    QStringLiteral("turbo"),
    QStringLiteral("full_speed"),
};

// Decide a stable profile name from arbitrary user input.
QString normalize(const QString &raw) {
    const QString s = raw.trimmed().toLower();
    if (s == QStringLiteral("silent") || s == QStringLiteral("quiet")) return QStringLiteral("silent");
    if (s == QStringLiteral("balanced")) return QStringLiteral("balanced");
    if (s == QStringLiteral("turbo") || s == QStringLiteral("performance")) return QStringLiteral("turbo");
    if (s == QStringLiteral("full_speed") || s == QStringLiteral("max")) return QStringLiteral("full_speed");
    return {};
}

bool isWritableByMe(const QString &path) {
    QFileInfo fi(path);
    if (!fi.exists()) {
        return false;
    }
    return fi.isWritable();
}

bool fileExists(const QString &path) {
    return QFile::exists(path);
}

} // namespace

FanController::FanController(QObject *parent)
    : QObject(parent) {
    try {
        detectCapability();
    } catch (...) {
        emit errorOccurred(QStringLiteral("FanController init failed"));
    }
}

FanController::~FanController() = default;

void FanController::attachIpc(IpcClient *ipc) {
    m_ipc = ipc;
}

QStringList FanController::availableProfiles() const {
    return kProfiles;
}

QVariantList FanController::enumerateHwmon() const {
    QVariantList out;
    const QList<HwmonEntry> entries = SysInfo::enumerateHwmon();
    out.reserve(entries.size());
    for (const HwmonEntry &h : entries) {
        QVariantMap m;
        m.insert(QStringLiteral("name"), h.name);
        m.insert(QStringLiteral("path"), h.path);
        m.insert(QStringLiteral("fans"), h.fanInputs);
        m.insert(QStringLiteral("temps"), h.tempInputs);
        m.insert(QStringLiteral("pwmControls"), h.pwmControls);
        m.insert(QStringLiteral("pwmEnable"), h.pwmEnable);
        out.append(m);
    }
    return out;
}

bool FanController::canProbePwm() const {
    QDir d(QStringLiteral("/sys/class/hwmon"));
    if (!d.exists()) {
        return false;
    }
    const QStringList dirs = d.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &dir : dirs) {
        const QString abs = d.absoluteFilePath(dir);
        const QDir inner(abs);
        const QStringList files = inner.entryList(QStringList{QStringLiteral("pwm*")}, QDir::Files);
        if (!files.isEmpty()) {
            return true;
        }
    }
    return false;
}

QString FanController::capabilityFromProbes(bool anyFan,
                                            bool anyPwm,
                                            bool anyPwmWritable,
                                            bool anyTemp,
                                            bool hasFancontrolBin) {
    if (!anyFan && !anyPwm && !anyTemp) {
        return QStringLiteral("unsupported");
    }
    if (hasFancontrolBin && anyPwm) {
        if (anyPwmWritable) {
            return QStringLiteral("control_available");
        }
        return QStringLiteral("permission_required");
    }
    if (anyPwm) {
        if (anyPwmWritable) {
            return QStringLiteral("control_available");
        }
        return QStringLiteral("permission_required");
    }
    return QStringLiteral("monitor_only");
}

QVariantMap FanController::detectCapability() {
    try {
        const QList<HwmonEntry> entries = SysInfo::enumerateHwmon();
        bool anyFan = false;
        bool anyPwm = false;
        bool anyPwmWritable = false;
        bool anyTemp = false;

        m_devices.clear();
        for (const HwmonEntry &h : entries) {
            QVariantMap m;
            m.insert(QStringLiteral("name"), h.name);
            m.insert(QStringLiteral("path"), h.path);
            m.insert(QStringLiteral("fans"), h.fanInputs);
            m.insert(QStringLiteral("temps"), h.tempInputs);
            m.insert(QStringLiteral("pwmControls"), h.pwmControls);
            m.insert(QStringLiteral("pwmEnable"), h.pwmEnable);
            bool hasWritablePwm = false;
            for (const QString &pwm : h.pwmControls) {
                const QString pwmPath = h.path + QLatin1Char('/') + pwm;
                if (fileExists(pwmPath)) {
                    anyPwm = true;
                    if (isWritableByMe(pwmPath)) {
                        anyPwmWritable = true;
                        hasWritablePwm = true;
                    }
                }
            }
            m.insert(QStringLiteral("hasWritablePwm"), hasWritablePwm);
            if (!h.fanInputs.isEmpty()) {
                anyFan = true;
            }
            if (!h.tempInputs.isEmpty()) {
                anyTemp = true;
            }
            m_devices.append(m);
        }

        const bool hasFancontrol = fileExists(QStringLiteral("/usr/sbin/fancontrol"))
                                  || fileExists(QStringLiteral("/usr/bin/fancontrol"));
        const QString capability = capabilityFromProbes(anyFan, anyPwm, anyPwmWritable, anyTemp, hasFancontrol);
        m_capability = capability;
        m_capabilityDetails.clear();
        m_capabilityDetails.insert(QStringLiteral("capability"), capability);
        m_capabilityDetails.insert(QStringLiteral("hasFanInput"), anyFan);
        m_capabilityDetails.insert(QStringLiteral("hasPwm"), anyPwm);
        m_capabilityDetails.insert(QStringLiteral("hasPwmWritable"), anyPwmWritable);
        m_capabilityDetails.insert(QStringLiteral("hasTempInput"), anyTemp);
        m_capabilityDetails.insert(QStringLiteral("hasFancontrolBinary"), hasFancontrol);
        m_capabilityDetails.insert(QStringLiteral("deviceCount"), m_devices.size());

        m_summary = tr("Probed %1 hwmon device(s); capability: %2")
                       .arg(m_devices.size())
                       .arg(capability);
    } catch (const std::exception &ex) {
        m_capability = QStringLiteral("error");
        m_capabilityDetails.insert(QStringLiteral("error"), QString::fromUtf8(ex.what()));
        emit errorOccurred(QStringLiteral("detectCapability: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        m_capability = QStringLiteral("error");
        m_capabilityDetails.insert(QStringLiteral("error"), QStringLiteral("unknown"));
        emit errorOccurred(QStringLiteral("detectCapability: unknown failure"));
    }
    emit capabilityChanged();
    emit summaryChanged();
    return m_capabilityDetails;
}

void FanController::refresh() {
    detectCapability();
    if (m_ipc) {
        m_ipc->submitCommand(QStringLiteral("fan.get"), {});
    }
}

QString FanController::setProfile(const QString &name) {
    try {
        const QString target = normalize(name);
        if (target.isEmpty()) {
            return QStringLiteral("unknown profile: ") + name;
        }
        if (m_ipc) {
            QVariantMap params;
            params.insert(QStringLiteral("profile"), target);
            m_ipc->submitCommand(QStringLiteral("fan.set"), params);
        }
        if (target != m_currentProfile) {
            m_currentProfile = target;
            emit currentProfileChanged();
        }
        emit summaryChanged();
        return QString();
    } catch (...) {
        emit errorOccurred(QStringLiteral("setProfile failed"));
        return QStringLiteral("setProfile failed");
    }
}

QVariantList FanController::devicesVariant() const {
    QVariantList list;
    list.reserve(m_devices.size());
    for (const QVariantMap &m : m_devices) {
        list.append(m);
    }
    return list;
}

QString FanController::runProbe() {
    return m_capability;
}

}  // namespace Luna::Hub
