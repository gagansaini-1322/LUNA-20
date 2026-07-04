//! Snapshot data structures and capability enums shared across the
//! process and exposed over IPC.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Capability {
    MonitorOnly,
    ControlAvailable,
    PermissionRequired,
    Unsupported,
    Error,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PerformanceProfile {
    Eco,
    Balanced,
    Performance,
    LunaBoost,
}

impl PerformanceProfile {
    pub fn from_name(s: &str) -> Option<Self> {
        match s {
            "eco" => Some(Self::Eco),
            "balanced" => Some(Self::Balanced),
            "performance" => Some(Self::Performance),
            "luna_boost" => Some(Self::LunaBoost),
            _ => None,
        }
    }

    pub fn name(&self) -> &'static str {
        match self {
            Self::Eco => "eco",
            Self::Balanced => "balanced",
            Self::Performance => "performance",
            Self::LunaBoost => "luna_boost",
        }
    }
}

impl std::str::FromStr for PerformanceProfile {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::from_name(s).ok_or_else(|| format!("unknown performance profile: {s}"))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FanProfile {
    Silent,
    Balanced,
    Turbo,
    FullSpeed,
}

impl FanProfile {
    pub fn from_name(s: &str) -> Option<Self> {
        match s {
            "silent" => Some(Self::Silent),
            "balanced" => Some(Self::Balanced),
            "turbo" => Some(Self::Turbo),
            "full_speed" => Some(Self::FullSpeed),
            _ => None,
        }
    }

    pub fn name(&self) -> &'static str {
        match self {
            Self::Silent => "silent",
            Self::Balanced => "balanced",
            Self::Turbo => "turbo",
            Self::FullSpeed => "full_speed",
        }
    }

    /// Percent duty cycle hint the daemon attempts to enforce when the
    /// hardware accepts writes for PWM controls.
    pub fn duty_percent(&self) -> u8 {
        match self {
            Self::Silent => 35,
            Self::Balanced => 55,
            Self::Turbo => 80,
            Self::FullSpeed => 100,
        }
    }
}

impl std::str::FromStr for FanProfile {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::from_name(s).ok_or_else(|| format!("unknown fan profile: {s}"))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ChangeStatus {
    Success,
    Unsupported,
    PermissionRequired,
    Failed,
    AlreadyActive,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CpuCore {
    pub idx: u32,
    pub freq_mhz: Option<u32>,
    pub util_pct: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CpuSnapshot {
    pub model: Option<String>,
    pub util_pct: f32,
    pub freq_mhz: Option<u32>,
    pub temp_c: Option<f32>,
    pub cores: Vec<CpuCore>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemorySnapshot {
    pub used_bytes: u64,
    pub total_bytes: u64,
    pub avail_bytes: u64,
    pub cached_bytes: u64,
    pub swap_used_bytes: u64,
    pub swap_total_bytes: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuSnapshot {
    pub idx: u32,
    pub vendor: String,
    pub name: String,
    pub util_pct: Option<f32>,
    pub temp_c: Option<f32>,
    pub vram_used_bytes: Option<u64>,
    pub vram_total_bytes: Option<u64>,
    pub power_w: Option<f32>,
    pub clock_mhz: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FanSnapshot {
    pub label: Option<String>,
    pub hwmon_path: String,
    pub rpm: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TempSensor {
    pub label: String,
    pub hwmon_path: String,
    pub temp_c: f32,
    pub temp_max_c: Option<f32>,
    pub temp_crit_c: Option<f32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkSnapshot {
    pub interface: String,
    pub rx_bps: f64,
    pub tx_bps: f64,
    pub latency_ms: Option<f32>,
    pub packet_loss_pct: Option<f32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Fps {
    pub current: f32,
    pub avg_pct: Option<f32>,
    pub one_low_pct: Option<f32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActiveGame {
    pub source: String,
    pub app_id: Option<String>,
    pub title: Option<String>,
    pub pid: u32,
    pub started_ms: u128,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ProfileState {
    pub power: Option<PerformanceProfile>,
    pub fan: Option<FanProfile>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetectedGame {
    pub source: String,
    pub app_id: String,
    pub title: Option<String>,
    pub runtime: String,
    pub detected_ms: u128,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetrySnapshot {
    pub timestamp_ms: u128,
    pub cpu: CpuSnapshot,
    pub memory: MemorySnapshot,
    pub gpus: Vec<GpuSnapshot>,
    pub fans: Vec<FanSnapshot>,
    pub temps: Vec<TempSensor>,
    pub network: NetworkSnapshot,
    pub active_game: Option<ActiveGame>,
    pub profile: ProfileState,
    pub fps: Option<Fps>,
    pub capability: Capability,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemInfo {
    pub hostname: String,
    pub kernel: String,
    pub os_release: String,
    pub cpu_model: String,
    pub cpu_cores_physical: u32,
    pub cpu_cores_logical: u32,
    pub memory_total_bytes: u64,
    pub gpus: Vec<GpuSnapshot>,
    pub has_nvidia_smi: bool,
    pub has_thermald: bool,
    pub has_gamemode: bool,
    pub has_powerprofilesctl: bool,
    pub has_fancontrol: bool,
    pub capability: Capability,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub uptime_s: u64,
    pub capability: Capability,
    pub current_profile: ProfileState,
    pub polls_total: u64,
    pub monitor_running: bool,
    pub last_error: Option<String>,
}
