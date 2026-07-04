//! CPU utilisation and frequency collector. Reads `/proc/stat` deltas to
//! compute per-core and aggregate utilisation.

use std::collections::HashMap;
use std::fs;
use std::time::Instant;

use crate::state::CpuSnapshot;

#[derive(Debug, Clone, Copy)]
struct CpuTimes {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,
    irq: u64,
    softirq: u64,
    steal: u64,
}

impl CpuTimes {
    fn parse(line: &str) -> Option<(String, Self)> {
        let mut it = line.split_whitespace();
        let label = it.next()?.to_string();
        if !label.starts_with("cpu") {
            return None;
        }
        let nums: Vec<u64> = it
            .filter_map(|t| t.parse::<u64>().ok())
            .collect();
        if nums.len() < 4 {
            return None;
        }
        let t = CpuTimes {
            user: nums.first().copied().unwrap_or(0),
            nice: nums.get(1).copied().unwrap_or(0),
            system: nums.get(2).copied().unwrap_or(0),
            idle: nums.get(3).copied().unwrap_or(0),
            iowait: nums.get(4).copied().unwrap_or(0),
            irq: nums.get(5).copied().unwrap_or(0),
            softirq: nums.get(6).copied().unwrap_or(0),
            steal: nums.get(7).copied().unwrap_or(0),
        };
        Some((label, t))
    }

    fn total(&self) -> u64 {
        self.user
            + self.nice
            + self.system
            + self.idle
            + self.iowait
            + self.irq
            + self.softirq
            + self.steal
    }

    fn busy(&self) -> u64 {
        self.user + self.nice + self.system + self.irq + self.softirq + self.steal
    }
}

#[derive(Debug, Default)]
pub struct CpuStat {
    prev: HashMap<String, CpuTimes>,
    last: Option<Instant>,
    pub model: Option<String>,
}

impl CpuStat {
    pub fn new() -> Self {
        let mut s = Self::default();
        s.model = read_cpu_model();
        // Prime previous readings so first delta is meaningful.
        if let Ok(snapshot) = read_stat_raw() {
            for (k, v) in snapshot {
                s.prev.insert(k, v);
            }
        }
        s.last = Some(Instant::now());
        s
    }

    pub fn tick(&mut self) -> CpuSnapshot {
        let now = Instant::now();
        let cur = read_stat_raw().unwrap_or_default();
        let mut cores = Vec::new();
        let mut aggregate: Option<(u64, u64)> = None;

        for (label, t) in &cur {
            if let Some(prev) = self.prev.get(label).copied() {
                let d_total = t.total().saturating_sub(prev.total());
                let d_busy = t.busy().saturating_sub(prev.busy());
                let util = if d_total > 0 {
                    (d_busy as f32 / d_total as f32) * 100.0
                } else {
                    0.0
                };
                if label == "cpu" {
                    aggregate = Some((d_busy, d_total));
                } else if let Some(idx) = label.strip_prefix("cpu") {
                    if let Ok(n) = idx.parse::<u32>() {
                        cores.push(crate::state::CpuCore {
                            idx: n,
                            freq_mhz: read_core_freq_mhz(n),
                            util_pct: util.clamp(0.0, 100.0),
                        });
                    }
                }
            }
            self.prev.insert(label.clone(), *t);
        }

        cores.sort_by_key(|c| c.idx);

        let util_pct = match aggregate {
            Some((busy, total)) if total > 0 => (busy as f32 / total as f32) * 100.0,
            _ => 0.0,
        }
        .clamp(0.0, 100.0);

        let freq_mhz = cores
            .iter()
            .filter_map(|c| c.freq_mhz)
            .max();

        self.last = Some(now);

        CpuSnapshot {
            model: self.model.clone(),
            util_pct,
            freq_mhz,
            temp_c: crate::sensor::temperature::cpu_package_celsius_estimate(),
            cores,
        }
    }

    pub fn uptime(&self) -> Option<Duration> {
        self.last.map(|t| t.elapsed())
    }
}

use std::time::Duration;

fn read_stat_raw() -> anyhow::Result<HashMap<String, CpuTimes>> {
    let body = fs::read_to_string("/proc/stat")?;
    let mut map = HashMap::new();
    for line in body.lines() {
        if let Some((k, v)) = CpuTimes::parse(line) {
            map.insert(k, v);
        }
    }
    Ok(map)
}

fn read_cpu_model() -> Option<String> {
    let body = fs::read_to_string("/proc/cpuinfo").ok()?;
    let mut model = None;
    let mut physical: u32 = 0;
    let mut logical: u32 = 0;
    for line in body.lines() {
        if let Some(rest) = line.strip_prefix("model name") {
            if model.is_none() {
                if let Some(v) = rest.split(':').nth(1) {
                    model = Some(v.trim().to_string());
                }
            }
        }
        if line.starts_with("physical id") {
            physical += 1;
        }
        if line.starts_with("processor") {
            logical += 1;
        }
    }
    if model.is_some() {
        return model;
    }
    if physical > 0 || logical > 0 {
        return Some(format!("{} phys / {} logical", physical.max(1), logical.max(1)));
    }
    None
}

pub fn cpu_cores_physical() -> u32 {
    let body = match fs::read_to_string("/proc/cpuinfo") {
        Ok(b) => b,
        Err(_) => return 0,
    };
    let mut ids = std::collections::HashSet::<String>::new();
    for line in body.lines() {
        if let Some(rest) = line.strip_prefix("physical id") {
            if let Some(v) = rest.split(':').nth(1) {
                ids.insert(v.trim().to_string());
            }
        }
    }
    if ids.is_empty() {
        body.lines()
            .filter(|l| l.starts_with("processor"))
            .count() as u32
    } else {
        ids.len() as u32
    }
}

pub fn cpu_cores_logical() -> u32 {
    let body = match fs::read_to_string("/proc/cpuinfo") {
        Ok(b) => b,
        Err(_) => return 0,
    };
    body.lines()
        .filter(|l| l.starts_with("processor"))
        .count() as u32
}

fn read_core_freq_mhz(idx: u32) -> Option<u32> {
    let p = format!(
        "/sys/devices/system/cpu/cpu{idx}/cpufreq/scaling_cur_freq"
    );
    let raw = fs::read_to_string(&p).ok()?;
    let khz: i64 = raw.trim().parse().ok()?;
    Some((khz / 1000).max(0) as u32)
}
