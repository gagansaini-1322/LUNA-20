//! luna-telemetryd — Luna OS telemetry collection service.
//!
//! This crate provides background collectors for CPU, memory, GPUs, fans,
//! temperatures, network, active games, and the control surfaces for power
//! and fan profiles. Communication with the daemon happens over a Unix
//! domain socket using a length-prefixed JSON line protocol.
//!
//! See `packaging/README.md` for the IPC contract.

pub mod games;
pub mod gpu;
pub mod ipc;
pub mod logging;
pub mod monitor;
pub mod profile;
pub mod sensor;
pub mod state;

mod capability;
mod runtime;

pub use crate::capability::{detect_capability, CapabilityProbe, SubsystemCapability};
pub use crate::runtime::{AppState, AppStateBuilder, RunOptions};
pub use crate::state::*;
