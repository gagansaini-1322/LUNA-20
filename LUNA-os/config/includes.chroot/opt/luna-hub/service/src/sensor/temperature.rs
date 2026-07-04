//! Temperature sensor reader. Walks `/sys/class/hwmon` and exposes every
//! `temp*_input` (millidegrees Celsius) plus its `temp*_label` and limits.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::state::TempSensor;

pub fn list_sensors() -> Vec<TempSensor> {
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
        let indices = discover_indices(&hwmon, "temp");
        for idx in indices {
            if let Some(s) = build_sensor(&hwmon, &name, idx) {
                out.push(s);
            }
        }
    }
    out.sort_by(|a, b| a.hwmon_path.cmp(&b.hwmon_path));
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

fn build_sensor(hwmon: &Path, name: &str, idx: u32) -> Option<TempSensor> {
    let input = read_path(&hwmon.join(format!("temp{idx}_input")));
    let millis: i64 = input.trim().parse().ok()?;
    let temp_c = (millis as f32) / 1000.0;

    let label = read_path(&hwmon.join(format!("temp{idx}_label")))
        .trim()
        .to_string();
    let label = if label.is_empty() {
        if name.is_empty() {
            format!("temp{idx}")
        } else {
            format!("{name} temp{idx}")
        }
    } else {
        if name.is_empty() {
            label
        } else {
            format!("{name}: {label}")
        }
    };

    let max_c = parse_celsius(&hwmon.join(format!("temp{idx}_max")));
    let crit_c = parse_celsius(&hwmon.join(format!("temp{idx}_crit")));

    Some(TempSensor {
        label,
        hwmon_path: hwmon.display().to_string(),
        temp_c,
        temp_max_c: max_c,
        temp_crit_c: crit_c,
    })
}

fn parse_celsius(path: &Path) -> Option<f32> {
    let raw = read_celsius(path);
    let millis: i64 = raw.trim().parse().ok()?;
    Some((millis as f32) / 1000.0)
}

pub fn read_path(p: &Path) -> String {
    fs::read_to_string(p).unwrap_or_default()
}

pub fn cpu_package_celsius_estimate() -> Option<f32> {
    list_sensors()
        .into_iter()
        .filter(|s| {
            let l = s.label.to_ascii_lowercase();
            l.contains("cpu") || l.contains("package") || l.contains("coretemp")
        })
        .map(|s| s.temp_c)
        .fold(None, |acc, v| match acc {
            None => Some(v),
            Some(prev) => Some(prev.max(v)),
        })
}

pub fn board_celsius_estimate() -> Option<f32> {
    list_sensors()
        .into_iter()
        .filter(|s| {
            let l = s.label.to_ascii_lowercase();
            l.contains("board") || l.contains("systin") || l.contains("mb")
        })
        .map(|s| s.temp_c)
        .fold(None, |acc, v| match acc {
            None => Some(v),
            Some(prev) => Some(prev.max(v)),
        })
}

/// Map of `chip name -> hwmon path` for tools that need stable paths.
pub fn by_chip() -> BTreeMap<String, PathBuf> {
    let Ok(entries) = fs::read_dir("/sys/class/hwmon") else {
        return BTreeMap::new();
    };
    let mut map = BTreeMap::new();
    for entry in entries.flatten() {
        let p = entry.path();
        let Some(name) = fs::read_to_string(p.join("name"))
            .ok()
            .map(|s| s.trim().to_string())
        else {
            continue;
        };
        if !name.is_empty() {
            map.insert(name, p);
        }
    }
    map
}
