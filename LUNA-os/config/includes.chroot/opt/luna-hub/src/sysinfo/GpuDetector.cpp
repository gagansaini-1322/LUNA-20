// Luna OS Project
//
// GPU discovery. The DRM card list (/sys/class/drm/card*) is the canonical
// source for GPUs present in the system. Vendor is inferred from the
// driver symlink (i915 → Intel, amdgpu → AMD, nvidia → NVIDIA). NVIDIA
// names are enriched using `nvidia-smi --query-gpu=index,name` when
// installed.

#include "GpuDetector.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStringList>
#include <QTextStream>

#include <algorithm>

namespace Luna::Hub {

namespace {

QString readSymlinkTarget(const QString &path) {
    QFileInfo fi(path);
    return fi.isSymLink() ? fi.symLinkTarget() : QString();
}

QString basenameOf(const QString &path) {
    const int idx = path.lastIndexOf(QLatin1Char('/'));
    return idx >= 0 ? path.mid(idx + 1) : path;
}

QString resolveDriverFromDevice(const QString &devicePath) {
    const QString driverLink = devicePath + QStringLiteral("/driver");
    if (!QFileInfo::exists(driverLink)) {
        return {};
    }
    const QString target = readSymlinkTarget(driverLink);
    return basenameOf(target);
}

} // namespace

bool GpuDetector::hasNvidiaSmi() {
    QProcess proc;
    proc.start(QStringLiteral("which"), {QStringLiteral("nvidia-smi")});
    if (!proc.waitForFinished(800)) {
        return false;
    }
    return proc.exitCode() == 0;
}

QList<GpuDescriptor> GpuDetector::detectNvidia() {
    QList<GpuDescriptor> result;
    if (!hasNvidiaSmi()) {
        return result;
    }

    QList<QString> names;
    {
        QProcess proc;
        proc.start(QStringLiteral("nvidia-smi"),
                  {QStringLiteral("--query-gpu=index,name"),
                   QStringLiteral("--format=csv,noheader,nounits")});
        if (proc.waitForFinished(1500) && proc.exitCode() == 0) {
            const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
            const QStringList lines = out.split(QLatin1Char('\n'));
            for (const QString &line : lines) {
                if (line.trimmed().isEmpty()) {
                    continue;
                }
                const QStringList parts = line.split(QStringLiteral(", "));
                if (parts.size() >= 2) {
                    names.append(parts.at(1).trimmed());
                } else {
                    names.append(line.trimmed());
                }
            }
        }
    }

    QDir drm(QStringLiteral("/sys/class/drm"));
    if (!drm.exists()) {
        return result;
    }
    const QStringList cards = drm.entryList({QStringLiteral("card[0-9]*")},
                                            QDir::Dirs | QDir::NoDotAndDotDot);
    int nameIdx = 0;
    int nextDescriptorIdx = result.size();
    for (const QString &card : cards) {
        const QString cardPath = drm.absoluteFilePath(card);
        const QString devicePath = cardPath + QStringLiteral("/device");
        const QString driver = resolveDriverFromDevice(devicePath);
        if (driver != QStringLiteral("nvidia")) {
            continue;
        }
        GpuDescriptor desc;
        desc.driver = driver;
        desc.drmPath = cardPath;
        desc.vendor = QStringLiteral("nvidia");
        desc.pciSlot = basenameOf(devicePath);
        if (nameIdx < names.size()) {
            desc.name = names.at(nameIdx);
        } else {
            desc.name = QStringLiteral("NVIDIA GPU");
        }
        desc.idx = nextDescriptorIdx++;
        result.append(desc);
        ++nameIdx;
    }
    return result;
}

QList<GpuDescriptor> GpuDetector::detectAmd() {
    QList<GpuDescriptor> result;
    QDir drm(QStringLiteral("/sys/class/drm"));
    if (!drm.exists()) {
        return result;
    }
    const QStringList cards = drm.entryList({QStringLiteral("card[0-9]*")},
                                            QDir::Dirs | QDir::NoDotAndDotDot);
    int nextIdx = 0;
    for (const QString &card : cards) {
        const QString cardPath = drm.absoluteFilePath(card);
        const QString devicePath = cardPath + QStringLiteral("/device");
        const QString driver = resolveDriverFromDevice(devicePath);
        if (driver != QStringLiteral("amdgpu")) {
            continue;
        }
        QString name;
        QFile nameFile(devicePath + QStringLiteral("/product_name"));
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            name = QString::fromUtf8(nameFile.readAll()).trimmed();
        }
        if (name.isEmpty()) {
            name = QStringLiteral("AMD Radeon GPU");
        }
        GpuDescriptor desc;
        desc.idx = nextIdx++;
        desc.vendor = QStringLiteral("amd");
        desc.driver = driver;
        desc.drmPath = cardPath;
        desc.pciSlot = basenameOf(devicePath);
        desc.name = name;
        result.append(desc);
    }
    return result;
}

QList<GpuDescriptor> GpuDetector::detectIntel() {
    QList<GpuDescriptor> result;
    QDir drm(QStringLiteral("/sys/class/drm"));
    if (!drm.exists()) {
        return result;
    }
    const QStringList cards = drm.entryList({QStringLiteral("card[0-9]*")},
                                            QDir::Dirs | QDir::NoDotAndDotDot);
    int nextIdx = 0;
    for (const QString &card : cards) {
        const QString cardPath = drm.absoluteFilePath(card);
        const QString devicePath = cardPath + QStringLiteral("/device");
        const QString driver = resolveDriverFromDevice(devicePath);
        if (driver != QStringLiteral("i915")) {
            continue;
        }
        QString name;
        QFile nameFile(devicePath + QStringLiteral("/product_name"));
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            name = QString::fromUtf8(nameFile.readAll()).trimmed();
        }
        if (name.isEmpty()) {
            name = QStringLiteral("Intel GPU");
        }
        GpuDescriptor desc;
        desc.idx = nextIdx++;
        desc.vendor = QStringLiteral("intel");
        desc.driver = driver;
        desc.drmPath = cardPath;
        desc.pciSlot = basenameOf(devicePath);
        desc.name = name;
        result.append(desc);
    }
    return result;
}

QList<GpuDescriptor> GpuDetector::detectAll() {
    QList<GpuDescriptor> all;
    QList<GpuDescriptor> intel = detectIntel();
    QList<GpuDescriptor> amd = detectAmd();
    QList<GpuDescriptor> nvidia = detectNvidia();
    int idx = 0;
    for (GpuDescriptor &d : intel) {
        d.idx = idx++;
        all.append(d);
    }
    for (GpuDescriptor &d : amd) {
        d.idx = idx++;
        all.append(d);
    }
    for (GpuDescriptor &d : nvidia) {
        d.idx = idx++;
        all.append(d);
    }
    // If nothing was found at all, return a single placeholder so the UI
    // never displays an empty GPU strip.
    if (all.isEmpty()) {
        GpuDescriptor fallback;
        fallback.idx = 0;
        fallback.vendor = QStringLiteral("unknown");
        fallback.name = QStringLiteral("GPU not detected");
        fallback.driver = QString();
        fallback.pciSlot = QString();
        fallback.drmPath = QString();
        fallback.canReadSysFs = false;
        all.append(fallback);
    }
    std::stable_sort(all.begin(), all.end(),
                     [](const GpuDescriptor &a, const GpuDescriptor &b) {
                         return a.idx < b.idx;
                     });
    return all;
}

}  // namespace Luna::Hub
