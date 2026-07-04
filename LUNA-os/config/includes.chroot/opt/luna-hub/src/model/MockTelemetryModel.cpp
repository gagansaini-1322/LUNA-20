// Luna OS Project
//
// Deterministic mock telemetry implementation.

#include "MockTelemetryModel.h"

#include "sysinfo/SysInfo.h"
#include "sysinfo/GpuDetector.h"

#include <QDateTime>
#include <QFile>
#include <QRandom>

#include <cmath>
#include <cstdlib>

namespace Luna::Hub {

namespace {

// Cheap xorshift-style deterministic prng. Returning a double in [0, 1)
double randUnit(quint64 &state) {
    quint64 x = state;
    if (x == 0) {
        x = 0x9E3779B97F4A7C15ull;
    }
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    state = x;
    const double out = static_cast<double>(x & ((1ull << 53) - 1)) / static_cast<double>(1ull << 53);
    return out;
}

double bounded(quint64 &state, double lo, double hi) {
    return lo + (hi - lo) * randUnit(state);
}

double sinusoidal(quint64 &state, double base, double amp, quint64 ticks, double period) {
    constexpr double pi = 3.141592653589793;
    const double phase = static_cast<double>(ticks) / period;
    const double jitter = (randUnit(state) - 0.5) * 0.5 * amp;
    return base + amp * sin(phase * 2.0 * pi) + jitter;
}

} // namespace

MockTelemetryModel::MockTelemetryModel(QObject *parent)
    : QObject(parent) {
}

MockTelemetryModel::~MockTelemetryModel() = default;

void MockTelemetryModel::setSeed(quint64 seed) {
    m_seed = seed == 0 ? 1u : seed;
}

QString MockTelemetryModel::sourceName() const {
    return QStringLiteral("mock");
}

QVariantMap MockTelemetryModel::snapshot() const {
    QVariantMap snap;
    snap.insert(QStringLiteral("timestamp_ms"),
                QDateTime::currentMSecsSinceEpoch());

    quint64 state = m_seed ^ (m_ticks * 0x9E3779B97F4A7C15ull);
    m_ticks = state;

    // CPU
    QVariantMap cpu;
    cpu.insert(QStringLiteral("model"), SysInfo::readCpuModel());
    cpu.insert(QStringLiteral("util_pct"),
               bounded(state, 8.0, 65.0));
    cpu.insert(QStringLiteral("freq_mhz"),
               SysInfo::readCpuFrequencyMhz(0));
    cpu.insert(QStringLiteral("temp_c"),
               sinusoidal(state, 56.0, 8.0, m_ticks, 30.0));
    QVariantList cores;
    const int coresCount = SysInfo::readLogicalCoreCount();
    for (int i = 0; i < qMax(1, coresCount); ++i) {
        QVariantMap core;
        core.insert(QStringLiteral("idx"), i);
        core.insert(QStringLiteral("freq_mhz"), SysInfo::readCpuFrequencyMhz(i));
        core.insert(QStringLiteral("util_pct"),
                     sinusoidal(state, 30.0, 30.0, m_ticks + static_cast<quint64>(i), 12.0));
        cores.append(core);
    }
    cpu.insert(QStringLiteral("cores"), cores);
    snap.insert(QStringLiteral("cpu"), cpu);

    // Memory
    const MemInfo mi = SysInfo::readMemInfo();
    QVariantMap mem;
    mem.insert(QStringLiteral("total_bytes"), mi.totalKb * 1024ULL);
    mem.insert(QStringLiteral("avail_bytes"), mi.availableKb * 1024ULL);
    mem.insert(QStringLiteral("used_bytes"),
               (mi.totalKb > mi.availableKb ? (mi.totalKb - mi.availableKb) : 0) * 1024ULL);
    mem.insert(QStringLiteral("cached_bytes"), mi.cachedKb * 1024ULL);
    mem.insert(QStringLiteral("swap_total_bytes"), mi.swapTotalKb * 1024ULL);
    mem.insert(QStringLiteral("swap_used_bytes"),
               (mi.swapTotalKb > mi.swapFreeKb ? (mi.swapTotalKb - mi.swapFreeKb) : 0) * 1024ULL);
    snap.insert(QStringLiteral("memory"), mem);

    // GPU(s)
    const QList<GpuDescriptor> gpus = GpuDetector::detectAll();
    QVariantList gpuList;
    int idx = 0;
    for (const GpuDescriptor &g : gpus) {
        QVariantMap gs;
        gs.insert(QStringLiteral("idx"), idx++);
        gs.insert(QStringLiteral("vendor"), g.vendor);
        gs.insert(QStringLiteral("name"),
                  g.name.isEmpty() ? QStringLiteral("GPU") : g.name);
        gs.insert(QStringLiteral("util_pct"),
                  bounded(state, 3.0, 80.0));
        gs.insert(QStringLiteral("temp_c"),
                  sinusoidal(state, 50.0, 12.0, m_ticks + static_cast<quint64>(idx), 18.0));
        gs.insert(QStringLiteral("vram_used_bytes"),
                  static_cast<quint64>(bounded(state, 0.6e9, 5.5e9)));
        gs.insert(QStringLiteral("vram_total_bytes"),
                  static_cast<quint64>(8.0e9));
        gs.insert(QStringLiteral("power_w"),
                  bounded(state, 12.0, 220.0));
        gs.insert(QStringLiteral("clock_mhz"),
                  static_cast<int>(bounded(state, 800.0, 2200.0)));
        gpuList.append(gs);
    }
    snap.insert(QStringLiteral("gpus"), gpuList);

    // Fans
    QVariantList fans;
    {
        const QList<HwmonEntry> hwmon = SysInfo::enumerateHwmon();
        for (int i = 0; i < hwmon.size(); ++i) {
            QVariantMap f;
            f.insert(QStringLiteral("label"), hwmon.at(i).name);
            f.insert(QStringLiteral("hwmon_path"), hwmon.at(i).path);
            f.insert(QStringLiteral("rpm"),
                     static_cast<int>(sinusoidal(state, 1500.0, 900.0,
                                                m_ticks + static_cast<quint64>(i), 24.0)));
            fans.append(f);
        }
    }
    snap.insert(QStringLiteral("fans"), fans);

    // Temperatures
    QVariantList temps;
    {
        const QList<HwmonEntry> hwmon = SysInfo::enumerateHwmon();
        for (int i = 0; i < hwmon.size(); ++i) {
            QVariantMap t;
            t.insert(QStringLiteral("label"), hwmon.at(i).name);
            t.insert(QStringLiteral("hwmon_path"), hwmon.at(i).path);
            t.insert(QStringLiteral("temp_c"),
                     sinusoidal(state, 50.0, 12.0,
                                m_ticks + static_cast<quint64>(i), 22.0));
            t.insert(QStringLiteral("temp_max_c"), 85.0);
            t.insert(QStringLiteral("temp_crit_c"), 100.0);
            temps.append(t);
        }
    }
    snap.insert(QStringLiteral("temps"), temps);

    // Network
    QVariantMap net;
    net.insert(QStringLiteral("interface"), QStringLiteral("eth0"));
    net.insert(QStringLiteral("rx_bps"), bounded(state, 1e4, 5e6));
    net.insert(QStringLiteral("tx_bps"), bounded(state, 1e3, 1.5e6));
    net.insert(QStringLiteral("latency_ms"), bounded(state, 5.0, 75.0));
    net.insert(QStringLiteral("packet_loss_pct"), bounded(state, 0.0, 0.4));
    snap.insert(QStringLiteral("network"), net);

    // Active game (mostly null)
    snap.insert(QStringLiteral("active_game"), QVariant());

    // Profile / FPS
    QVariantMap profile;
    profile.insert(QStringLiteral("power"), QStringLiteral("balanced"));
    profile.insert(QStringLiteral("fan"), QStringLiteral("balanced"));
    snap.insert(QStringLiteral("profile"), profile);

    QVariantMap fps;
    fps.insert(QStringLiteral("current"), 0.0);
    fps.insert(QStringLiteral("avg_pct"), QVariant());
    fps.insert(QStringLiteral("one_low_pct"), QVariant());
    snap.insert(QStringLiteral("fps"), fps);

    snap.insert(QStringLiteral("capability"), QStringLiteral("monitor_only"));
    return snap;
}

QVariantMap MockTelemetryModel::systemInfo() const {
    QVariantMap info;
    info.insert(QStringLiteral("hostname"), SysInfo::readHostname());
    info.insert(QStringLiteral("kernel"), SysInfo::readKernelRelease());
    info.insert(QStringLiteral("kernel_version"), SysInfo::readKernelVersion());
    info.insert(QStringLiteral("os_release"), SysInfo::readOsReleasePrettyName());
    info.insert(QStringLiteral("os_id"), SysInfo::readOsReleaseId());
    info.insert(QStringLiteral("cpu_model"), SysInfo::readCpuModel());
    info.insert(QStringLiteral("cpu_cores_physical"), SysInfo::readLogicalCoreCount());
    info.insert(QStringLiteral("cpu_cores_logical"), SysInfo::readLogicalCoreCount());
    const MemInfo mi = SysInfo::readMemInfo();
    info.insert(QStringLiteral("memory_total_bytes"), mi.totalKb * 1024ULL);
    info.insert(QStringLiteral("has_nvidia_smi"), GpuDetector::hasNvidiaSmi());
    info.insert(QStringLiteral("has_thermald"), QFile::exists(QStringLiteral("/usr/sbin/thermald")));
    info.insert(QStringLiteral("has_gamemode"),
                QFile::exists(QStringLiteral("/usr/bin/gamemoderun")));
    info.insert(QStringLiteral("has_powerprofilesctl"),
                QFile::exists(QStringLiteral("/usr/bin/powerprofilesctl")));
    info.insert(QStringLiteral("has_fancontrol"),
                QFile::exists(QStringLiteral("/usr/sbin/fancontrol")));
    info.insert(QStringLiteral("capability"), QStringLiteral("monitor_only"));
    return info;
}

}  // namespace Luna::Hub
