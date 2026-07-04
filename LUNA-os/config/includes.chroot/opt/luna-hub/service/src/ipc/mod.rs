//! IPC subsystem. Exposes typed request/response wrappers and a TCP-less
//! Unix domain socket server.

pub mod protocol;
pub mod server;

pub use server::Server;

use anyhow::Result;
use std::path::Path;
use std::sync::Arc;

use crate::runtime::AppState;

/// Convenience helper: bind a server at `socket_path` and run it forever.
///
/// Errors propagate. The caller is expected to surface them; in production
/// they are recorded in the journal and the daemon exits so systemd can
/// restart us.
pub async fn serve_unix(socket_path: &str, state: AppState) -> Result<()> {
    let server = Server::bind(Path::new(socket_path), Arc::new(state))?;
    server.run().await
}
