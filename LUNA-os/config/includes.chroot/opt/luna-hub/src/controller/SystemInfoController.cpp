// Luna OS Project
//
// SystemInfoController implementation. Aggregates data from SysInfo
// and GpuDetector; caches on initialization and on explicit refresh().

#include "SystemInfoController.h"

#include "sysinfo/SysInfo.h"

#include <QFile>
#include <QProcess>
#include <QStringBuilder>

#include <exception>

namespace Luna::Hub {

SystemInfoController::SystemInfoController(QObject *parent)
    : QObject(parent) {
    try {
        collectFromSys();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("systemInfo init: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("systemInfo init: unknown failure"));
    }
}

SystemInfoController::~SystemInfoController() = default;

void SystemInfoController::refresh() {
    try {
        collectFromSys();
        emit infoChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("systemInfo refresh failed"));
    }
}

void SystemInfoController::collectFromSys() {
    m_osName = SysInfo::readOsReleasePrettyName();
    m_osId = SysInfo::readOsReleaseId();
    m_kernel = SysInfo::readKernelRelease();
    m_hostname = SysInfo::readHostname();
    m_cpuModel = SysInfo::readCpuModel();
    m_logicalCores = SysInfo::readLogicalCoreCount();
    // Very rough physical core count; if hyperthreading is enabled this
    // returns logical, otherwise it equals physical. Defer real detection
    // to a follow-up when needed — the UI works either way.
    m_physicalCores = m_logicalCores;

    const MemInfo mi = SysInfo::readMemInfo();
    m_memoryTotalBytes = mi.totalKb * 1024ULL;

    m_gpus = GpuDetector::detectAll();
    m_hasNvidiaSmi = GpuDetector::hasNvidiaSmi();

    m_hasPowerprofiles = QFile::exists(QStringLiteral("/usr/bin/powerprofilesctl"));
    m_hasGamemode = QFile::exists(QStringLiteral("/usr/bin/gamemoderun"))
                   || QFile::exists(QStringLiteral("/usr/local/bin/gamemoderun"));
    m_hasFancontrol = QFile::exists(QStringLiteral("/usr/sbin/fancontrol"))
                      || QFile::exists(QStringLiteral("/usr/bin/fancontrol"));
    m_hasThermald = QFile::exists(QStringLiteral("/usr/sbin/thermald"))
                    || QFile::exists(QStringLiteral("/usr/bin/thermald"));
}

QString SystemInfoController::cpuFrequencyInfo() const {
    try {
        QProcess proc;
        proc.start(QStringLiteral("lscpu"), {QStringLiteral("-p=cpu,mhz")});
        if (!proc.waitForStarted(500)) {
            return {};
        }
        if (!proc.waitForFinished(800)) {
            return {};
        }
        if (proc.exitCode() != 0) {
            return {};
        }
        return QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    } catch (...) {
        return QString();
    }
}

QVariantList SystemInfoController::gpuListVariant() const {
    QVariantList list;
    list.reserve(m_gpus.size());
    for (const GpuDescriptor &g : m_gpus) {
        QVariantMap m;
        m.insert(QStringLiteral("idx"), g.idx);
        m.insert(QStringLiteral("vendor"), g.vendor);
        m.insert(QStringLiteral("name"), g.name);
        m.insert(QStringLiteral("driver"), g.driver);
        m.insert(QStringLiteral("pciSlot"), g.pciSlot);
        m.insert(QStringLiteral("drmPath"), g.drmPath);
        m.insert(QStringLiteral("canReadSysFs"), g.canReadSysFs);
        list.append(m);
    }
    return list;
}

QVariantMap SystemInfoController::asVariantMap() const {
    QVariantMap m;
    m.insert(QStringLiteral("osName"), m_osName);
    m.insert(QStringLiteral("osId"), m_osId);
    m.insert(QStringLiteral("kernel"), m_kernel);
    m.insert(QStringLiteral("hostname"), m_hostname);
    m.insert(QStringLiteral("cpuModel"), m_cpuModel);
    m.insert(QStringLiteral("logicalCores"), m_logicalCores);
    m.insert(QStringLiteral("physicalCores"), m_physicalCores);
    m.insert(QStringLiteral("memoryTotalBytes"),
             static_cast<qulonglong>(m_memoryTotalBytes));
    m.insert(QStringLiteral("gpus"), gpuListVariant());
    m.insert(QStringLiteral("hasNvidiaSmi"), m_hasNvidiaSmi);
    m.insert(QStringLiteral("hasPowerprofilesctl"), m_hasPowerprofiles);
    m.insert(QStringLiteral("hasGamemode"), m_hasGamemode);
    m.insert(QStringLiteral("hasFancontrol"), m_hasFancontrol);
    m.insert(QStringLiteral("hasThermald"), m_hasThermald);
    return m;
}

}  // namespace Luna::Hub
