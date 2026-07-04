//! Compact logging setup. Logs go to stderr by default; when launched by
//! systemd they end up in the journal of the user instance because we
//! honour `JOURNAL_STREAM` and `RUST_LOG` env variables.

use std::io::IsTerminal;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

pub fn init() {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("luna_telemetryd=info,tokio=warn,hyper=warn"));

    let is_terminal = std::io::stderr().is_terminal();

    let layer = fmt::layer()
        .with_writer(std::io::stderr)
        .with_ansi(is_terminal)
        .with_target(true)
        .with_thread_ids(false)
        .with_level(true)
        .compact();

    let _ = tracing_subscriber::registry().with(filter).with(layer).try_init();
}
