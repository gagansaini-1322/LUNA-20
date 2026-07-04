//! Fan speed and PWM control reader/writer. Walks `/sys/class/hwmon` for
//! `fan*_input` (RPM) and optionally writes `pwm*` to set a duty cycle.

use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use crate::state::FanSnapshot;

#[derive(Debug, Clone)]
pub struct FanData {
    pub index: u32,
    pub hwmon_path: PathBuf,
    pub label: Option<String>,
    pub name: String,
    pub rpm: Option<u32>,
    pub pwm: Option<u8>,
    pub pwm_max: Option<u8>,
    pub has_pwm_control: bool,
}

pub fn list_fans() -> Vec<FanSnapshot> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/class/hwmon") else {
        return out;
    };
    for entry in entries.flatten() {
        let hwmon = entry.path();
        let name = fs::read_to_string(hwmon.join("name"))
            .ok()
            .map(|s| s.trim().to_string())
            .unwrap_or_default();

        for idx in discover_indices(&hwmon, "fan") {
            let rpm_str = read_path(&hwmon.join(format!("fan{idx}_input")));
            let rpm = rpm_str.trim().parse::<i32>().ok().map(|v| v.max(0) as u32);
            let label = read_path(&hwmon.join(format!("fan{idx}_label")))
                .trim()
                .to_string();
            let label = if label.is_empty() {
                if name.is_empty() {
                    format!("fan{idx}")
                } else {
                    format!("{name} fan{idx}")
                }
            } else if name.is_empty() {
                label
            } else {
                format!("{name}: {label}")
            };
            out.push(FanSnapshot {
                label: Some(label),
                hwmon_path: hwmon.display().to_string(),
                rpm,
            });
        }
    }
    out
}

fn discover_indices(dir: &Path, prefix: &str) -> Vec<u32> {
    let Ok(entries) = fs::read_dir(dir) else {
        return Vec::new();
    };
    let mut indices: Vec<u32> = entries
        .flatten()
        .filter_map(|e| {
            let n = e.file_name().to_string_lossy().to_string();
            if !n.starts_with(prefix) {
                return None;
            }
            let tail = n.strip_prefix(prefix)?.strip_suffix("_input")?;
            tail.parse::<u32>().ok()
        })
        .collect();
    indices.sort_unstable();
    indices.dedup();
    indices
}

fn read_path(p: &Path) -> String {
    fs::read_to_string(p).unwrap_or_default()
}

/// Lists every fan with full metadata including PWM availability.
pub fn list_fans_full() -> Vec<FanData> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/class/hwmon") else {
        return out;
    };
    for entry in entries.flatten() {
        let hwmon = entry.path();
        let name = read_path(&hwmon.join("name"))
            .trim()
            .to_string();
        for idx in discover_indices(&hwmon, "fan") {
            let rpm_str = read_path(&hwmon.join(format!("fan{idx}_input")));
            let rpm = rpm_str.trim().parse::<i32>().ok().map(|v| v.max(0) as u32);
            let label = read_path(&hwmon.join(format!("fan{idx}_label")))
                .trim()
                .to_string();
            let label = if label.is_empty() { None } else { Some(label) };
            let pwm = read_u8(&hwmon.join(format!("pwm{idx}")));
            let pwm_max = read_u8(&hwmon.join(format!("pwm{idx}_max"))).unwrap_or(255);
            let has_pwm_control = can_write(&hwmon.join(format!("pwm{idx}")));
            out.push(FanData {
                index: idx,
                hwmon_path: hwmon.clone(),
                label,
                name: name.clone(),
                rpm,
                pwm,
                pwm_max: Some(pwm_max),
                has_pwm_control,
            });
        }
        // Also include PWM-only entries with no fan.
        for idx in discover_indices(&hwmon, "pwm") {
            if out.iter().any(|f| f.hwmon_path == hwmon && f.index == idx) {
                continue;
            }
            let pwm = read_u8(&hwmon.join(format!("pwm{idx}")));
            let pwm_max = read_u8(&hwmon.join(format!("pwm{idx}_max"))).unwrap_or(255);
            let has_pwm_control = can_write(&hwmon.join(format!("pwm{idx}")));
            out.push(FanData {
                index: idx,
                hwmon_path: hwmon.clone(),
                label: None,
                name: name.clone(),
                rpm: None,
                pwm,
                pwm_max: Some(pwm_max),
                has_pwm_control,
            });
        }
    }
    out
}

fn read_u8(p: &Path) -> Option<u8> {
    let raw = read_path(p);
    raw.trim().parse().ok()
}

fn can_write(p: &Path) -> bool {
    match fs::metadata(p) {
        Ok(md) => {
            // 0o200 owner write bit masked into mode + check write perms for current uid.
            md.permissions().mode() & 0o222 != 0
        }
        Err(_) => false,
    }
}
