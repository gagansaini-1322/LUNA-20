//! Power profile control via `powerprofilesctl`. Validates against an
//! internal enum and surfaces `UNSUPPORTED`/`PERMISSION_REQUIRED`/
//! `FAILED`/`SUCCESS`/`ALREADY_ACTIVE` to the caller.

use std::process::Command;

use crate::state::{ChangeStatus, PerformanceProfile};

pub fn is_available() -> bool {
    binary_in_path("powerprofilesctl")
}

fn binary_in_path(cmd: &str) -> bool {
    if let Some(paths) = std::env::var_os("PATH") {
        for path in std::env::split_paths(&paths) {
            if path.join(cmd).is_file() {
                return true;
            }
        }
    }
    false
}

pub fn current() -> Option<PerformanceProfile> {
    if !is_available() {
        return None;
    }
    let output = Command::new("powerprofilesctl")
        .arg("get")
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let raw = String::from_utf8_lossy(&output.stdout);
    let trimmed = raw.trim();
    log_debug_body(&output.stderr);
    PerformanceProfile::from_name(trimmed)
}

fn log_debug_body(_bytes: &[u8]) {
    // Reserved for future tracing field.
}

pub fn set(profile: PerformanceProfile) -> ChangeStatus {
    if !is_available() {
        return ChangeStatus::Unsupported;
    }
    if let Some(active) = current() {
        if active == profile {
            return ChangeStatus::AlreadyActive;
        }
    }
    let output = Command::new("powerprofilesctl")
        .arg("set")
        .arg(profile.name())
        .output();
    match output {
        Ok(o) if o.status.success() => ChangeStatus::Success,
        Ok(o) => classify_failure(&o.stderr),
        Err(_) => ChangeStatus::Failed,
    }
}

fn classify_failure(stderr_bytes: &[u8]) -> ChangeStatus {
    let s = String::from_utf8_lossy(stderr_bytes).to_ascii_lowercase();
    if s.contains("polkit")
        || s.contains("permission")
        || s.contains("not authorized")
        || s.contains("authentication")
    {
        ChangeStatus::PermissionRequired
    } else if s.contains("not found") || s.contains("unknown") || s.contains("no such") {
        ChangeStatus::Unsupported
    } else {
        ChangeStatus::Failed
    }
}
