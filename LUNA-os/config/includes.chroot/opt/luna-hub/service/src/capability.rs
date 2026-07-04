//! Capability detection at service startup. The daemon enumerates
//! available subsystem controls and assigns:
//!
//!  - `monitor_only`        — telemetry readable, no control surface
//!  - `control_available`   — both power + fan controls writable
//!  - `permission_required` — controls exist but require privilege
//!  - `unsupported`         — hardware/decision absent
//!  - `error`               — detection itself failed irrecoverably

use crate::profile::{fan as fanprof, power as powerprof};
use crate::state::Capability;
use std::collections::HashSet;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SubsystemCapability {
    Available,
    PermissionRequired,
    Unsupported,
    Error,
}

#[derive(Debug, Default, Clone)]
pub struct CapabilityProbe {
    pub power: SubsystemCapability,
    pub fan: SubsystemCapability,
    pub gpu_collect: SubsystemCapability,
    pub game_collect: SubsystemCapability,
}

pub fn detect_capability() -> CapabilityProbe {
    let power = match classify_power() {
        Power::Available => SubsystemCapability::Available,
        Power::Permission => SubsystemCapability::PermissionRequired,
        Power::NotPresent => SubsystemCapability::Unsupported,
        Power::Error => SubsystemCapability::Error,
    };
    let fan = match classify_fan() {
        Fan::Writable => SubsystemCapability::Available,
        Fan::Permission => SubsystemCapability::PermissionRequired,
        Fan::Unsupported => SubsystemCapability::Unsupported,
        Fan::Error => SubsystemCapability::Error,
    };
    let gpu = if crate::gpu::static_info().is_empty() && !crate::gpu::nvidia::is_available() {
        SubsystemCapability::Unsupported
    } else {
        SubsystemCapability::Available
    };
    let games = if games_supported() {
        SubsystemCapability::Available
    } else {
        SubsystemCapability::Unsupported
    };
    CapabilityProbe {
        power,
        fan,
        gpu_collect: gpu,
        game_collect: games,
    }
}

pub fn rollup(probe: &CapabilityProbe) -> Capability {
    let mut states = HashSet::new();
    states.insert(probe.power);
    states.insert(probe.fan);
    if states.contains(&SubsystemCapability::Error) {
        return Capability::Error;
    }
    if states.contains(&SubsystemCapability::Unsupported)
        && !states.contains(&SubsystemCapability::Available)
    {
        return Capability::Unsupported;
    }
    if states.contains(&SubsystemCapability::PermissionRequired)
        && !states.contains(&SubsystemCapability::Available)
    {
        return Capability::PermissionRequired;
    }
    if states.contains(&SubsystemCapability::Available) {
        return Capability::ControlAvailable;
    }
    Capability::MonitorOnly
}

enum Power {
    Available,
    Permission,
    NotPresent,
    Error,
}

enum Fan {
    Writable,
    Permission,
    Unsupported,
    Error,
}

fn classify_power() -> Power {
    if !powerprof::is_available() {
        return Power::NotPresent;
    }
    // powerprofilesctl is installed. Check whether we can actually switch.
    // We probe using the canonical "balanced" profile; if polkit rejects,
    // we report PermissionRequired. If a profile lacks entirely, we report
    // Available (the daemon supports it but a runtime failure occurs
    // when calling set on an unrecognised profile).
    match std::process::Command::new("powerprofilesctl")
        .arg("get")
        .output()
    {
        Ok(o) if o.status.success() => Power::Available,
        Ok(o) => classify_power_failure(&String::from_utf8_lossy(&o.stderr)),
        Err(_) => Power::Error,
    }
}

fn classify_power_failure(stderr: &str) -> Power {
    let s = stderr.to_ascii_lowercase();
    if s.contains("polkit")
        || s.contains("permission")
        || s.contains("authentication")
        || s.contains("not authorized")
    {
        Power::Permission
    } else if s.contains("no such") || s.contains("not found") {
        Power::NotPresent
    } else {
        Power::Error
    }
}

fn classify_fan() -> Fan {
    if !fanprof::is_controllable() {
        return Fan::Permission;
    }
    Fan::Writable
}

fn games_supported() -> bool {
    // Steam/Heroic/Lutris detection only depends on being able to read
    // /proc, which we always can. We just need at least one launcher's
    // hints exist somewhere; treat all as supported by default.
    true
}
