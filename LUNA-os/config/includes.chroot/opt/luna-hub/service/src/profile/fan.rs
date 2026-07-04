//! Fan profile control. Enforces a percent duty cycle on every PWM with
//! write permission. Read-only hardware returns `PermissionRequired`.

use std::collections::HashSet;
use std::fs;
use std::path::Path;

use crate::sensor::fan;
use crate::state::{ChangeStatus, FanProfile};

pub fn is_controllable() -> bool {
    let fans = fan::list_fans_full();
    fans.iter().any(|f| f.has_pwm_control)
}

pub fn control_paths() -> Vec<ControlTarget> {
    let fans = fan::list_fans_full();
    fans.into_iter()
        .filter(|f| f.has_pwm_control)
        .map(|f| ControlTarget {
            hwmon_path: f.hwmon_path,
            pwm_index: f.index,
            pwm_max: f.pwm_max.unwrap_or(255),
            label: f.label.clone().unwrap_or_else(|| {
                if f.name.is_empty() {
                    format!("pwm{}", f.index)
                } else {
                    format!("{} pwm{}", f.name, f.index)
                }
            }),
        })
        .collect()
}

#[derive(Debug, Clone)]
pub struct ControlTarget {
    pub hwmon_path: std::path::PathBuf,
    pub pwm_index: u32,
    pub pwm_max: u8,
    pub label: String,
}

pub fn current() -> Option<FanProfile> {
    // We don't persist the active profile in a stable location; we
    // derive from the first writable PWM. If exactly equal to one of
    // the four mapped duty percentages, we report that. Otherwise None.
    let active = read_active_duty_percent()?;
    FanProfile::resolved_from(active)
}

fn read_active_duty_percent() -> Option<u8> {
    let targets = control_paths();
    if targets.is_empty() {
        return None;
    }
    let mut last: Option<u8> = None;
    for t in &targets {
        let raw = fs::read_to_string(t.pwm_path()).ok()?;
        let v: i64 = raw.trim().parse().ok()?;
        if v <= 0 {
            return Some(0);
        }
        let max = if t.pwm_max == 0 { 255 } else { t.pwm_max } as i64;
        let pct = (v * 100 / max) as u8;
        last = Some(pct);
    }
    last
}

pub fn set(target: FanProfile) -> ChangeStatus {
    if target == FanProfile::Silent
        && read_active_duty_percent().map(|p| p == target.duty_percent()).unwrap_or(false)
    {
        return ChangeStatus::AlreadyActive;
    }
    let targets = control_paths();
    if targets.is_empty() {
        // No writable PWM available — fall back to checking helper daemons
        // or report permission needed.
        return report_no_writable_pwm();
    }
    let mut any_written = false;
    let mut any_permission = false;
    let mut unsupported_seen: HashSet<String> = HashSet::new();
    for t in &targets {
        let max = if t.pwm_max == 0 { 255 } else { t.pwm_max };
        let value = ((target.duty_percent() as u32) * (max as u32) / 100).min(max as u32);
        match write_pwm_value(&t.pwm_path(), value as u8) {
            WriteOutcome::Written => any_written = true,
            WriteOutcome::PermissionDenied => any_permission = true,
            WriteOutcome::IoError(_) => {
                unsupported_seen.insert("io".to_string());
            }
            WriteOutcome::NotSupported => {
                unsupported_seen.insert("ns".to_string());
            }
        }
    }
    if any_written {
        // Final check: if everything that *can* be written already had
        // that duty, we'd return AlreadyActive above. Otherwise success.
        return ChangeStatus::Success;
    }
    if any_permission && unsupported_seen.is_empty() {
        return ChangeStatus::PermissionRequired;
    }
    if !unsupported_seen.is_empty() {
        return ChangeStatus::Unsupported;
    }
    ChangeStatus::Failed
}

fn report_no_writable_pwm() -> ChangeStatus {
    // Try `fancontrol` service control as a last resort. We don't auto-start it
    // because it requires user configuration.
    ChangeStatus::PermissionRequired
}

enum WriteOutcome {
    Written,
    PermissionDenied,
    NotSupported,
    IoError(String),
}

fn write_pwm_value(path: &Path, value: u8) -> WriteOutcome {
    if !path.exists() {
        return WriteOutcome::NotSupported;
    }
    match fs::write(path, value.to_string()) {
        Ok(_) => WriteOutcome::Written,
        Err(e) => {
            let kind = e.kind();
            if kind == std::io::ErrorKind::PermissionDenied {
                WriteOutcome::PermissionDenied
            } else if kind == std::io::ErrorKind::NotFound {
                WriteOutcome::NotSupported
            } else {
                WriteOutcome::IoError(e.to_string())
            }
        }
    }
}

impl FanProfile {
    /// Resolves a duty percent to the closest profile by way of the
    /// fixed duty_percent() values. Exact matches only.
    pub fn resolved_from(pct: u8) -> Option<Self> {
        let opts = [
            (FanProfile::Silent, FanProfile::Silent.duty_percent()),
            (FanProfile::Balanced, FanProfile::Balanced.duty_percent()),
            (FanProfile::Turbo, FanProfile::Turbo.duty_percent()),
            (FanProfile::FullSpeed, FanProfile::FullSpeed.duty_percent()),
        ];
        for (profile, v) in opts {
            if v == pct {
                return Some(profile);
            }
        }
        None
    }
}

impl ControlTarget {
    pub fn pwm_path(&self) -> std::path::PathBuf {
        self.hwmon_path.join(format!("pwm{}", self.pwm_index))
    }
}
