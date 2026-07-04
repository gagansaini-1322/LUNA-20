// SPDX-License-Identifier: MIT OR Apache-2.0
//
// luna-telemetryd binary entry point.
//
use anyhow::{Context, Result};
use tracing::{error, info};
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

use luna_telemetryd::ipc::server::serve_unix;
use luna_telemetryd::logging;
use luna_telemetryd::runtime::{AppState, AppStateBuilder, RunMode, RunOptions};

#[tokio::main]
async fn main() -> Result<()> {
    logging::init();

    let options = parse_options();
    let mut state = AppStateBuilder::new(options.clone())
        .with_probe(luna_telemetryd::capability::detect_capability())
        .build();

    let bg_state = state.clone();
    let bg = tokio::spawn(async move {
        luna_telemetryd::monitor::run_collectors(bg_state).await
    });

    let ipc_state = state.clone();
    let ipc_handle = tokio::spawn(async move {
        if let Err(err) = serve_unix(&options.socket_path, ipc_state).await {
            error!("ipc server error: {err:?}");
        }
    });

    info!(
        mode = ?options.mode,
        socket = %options.socket_path,
        "luna-telemetryd ready"
    );

    let rc = tokio::select! {
        r = tokio::signal::ctrl_c() => {
            info!("ctrl-c received");
            r.context("signal handler")
        }
        r = bg => r.context("collector join"),
        r = ipc_handle => r.context("ipc join"),
    };
    if let Err(err) = rc {
        error!("shutdown error: {err:?}");
        std::process::exit(2);
    }
    Ok(())
}

fn parse_options() -> RunOptions {
    let opts = RunOptions {
        mode: RunMode::Foreground,
        ..RunOptions::default()
    };
    // Env overrides for path / dbus name keep systemd ops simple.
    if let Ok(p) = std::env::var("LUNA_TELEMETRY_SOCKET") {
        RunOptions { socket_path: p, ..opts.clone() }
    } else {
        opts
    }
}
