//! Unix domain socket IPC server. Wire format:
//!
//! `[  u32 BE length  ][ JSON line terminated by \n ]`
//!
//! Each request/response is one frame on the connection. Connections are
//! short-lived by design; the daemon handles one request per connection.

use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::Context;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{UnixListener, UnixStream};

use crate::ipc::protocol::{ChangeResult, ErrorCode, Request, Response};
use crate::runtime::AppState;
use crate::state::*;

const MAX_FRAME_BYTES: usize = 2 * 1024 * 1024;
const HEADER_LEN: usize = 4;

pub struct Server {
    listener: UnixListener,
    state: Arc<AppState>,
}

impl Server {
    pub fn bind(socket_path: &Path, state: Arc<AppState>) -> anyhow::Result<Self> {
        if let Some(parent) = socket_path.parent() {
            std::fs::create_dir_all(parent)
                .with_context(|| format!("create_dir_all({})", parent.display()))?;
            std::fs::set_permissions(parent, std::fs::Permissions::from_mode(0o755))?;
        }
        if socket_path.exists() {
            let _ = std::fs::remove_file(socket_path);
        }
        let listener = UnixListener::bind(socket_path)
            .with_context(|| format!("bind({})", socket_path.display()))?;
        std::fs::set_permissions(socket_path, std::fs::Permissions::from_mode(0o660))?;
        tracing::info!(path = %socket_path.display(), "IPC socket bound");
        Ok(Self { listener, state })
    }

    pub async fn run(self) -> anyhow::Result<()> {
        let listener = self.listener;
        loop {
            match listener.accept().await {
                Ok((stream, _addr)) => {
                    let state = self.state.clone();
                    tokio::spawn(async move {
                        if let Err(e) = handle_connection(stream, state).await {
                            tracing::debug!(error = %e, "connection ended with error");
                        }
                    });
                }
                Err(e) => {
                    tracing::warn!(error = %e, "accept failed");
                }
            }
        }
    }

    pub fn local_addr(&self) -> Option<PathBuf> {
        // Returns the bound socket path. tokio's `UnixListener` exposes this
        // as `local_addr` returning a `std::os::unix::net::SocketAddr`.
        self.listener.local_addr().ok().map(|a| {
            if let Some(path) = a.as_pathname() {
                path.to_path_buf()
            } else {
                PathBuf::new()
            }
        })
    }
}

async fn handle_connection(stream: UnixStream, state: Arc<AppState>) -> anyhow::Result<()> {
    let (mut read, mut write) = stream.into_split();
    let mut header = [0u8; HEADER_LEN];
    if let Err(e) = read.read_exact(&mut header).await {
        if e.kind() == std::io::ErrorKind::UnexpectedEof {
            return Ok(());
        }
        return Err(e.into());
    }
    let len = u32::from_be_bytes(header) as usize;
    if len == 0 || len > MAX_FRAME_BYTES {
        return Ok(());
    }
    let mut body = vec![0u8; len];
    read.read_exact(&mut body).await?;
    let req: Request = match serde_json::from_slice(&body) {
        Ok(r) => r,
        Err(e) => {
            let resp = Response::err(0, ErrorCode::SerializationError, e.to_string());
            write_frame(&mut write, &resp).await?;
            return Ok(());
        }
    };
    let resp = dispatch(&req, &state).await;
    write_frame(&mut write, &resp).await?;
    Ok(())
}

async fn write_frame<W: AsyncWriteExt + Unpin>(w: &mut W, resp: &Response) -> anyhow::Result<()> {
    let mut body = serde_json::to_vec(resp)?;
    if !body.ends_with(b"\n") {
        body.push(b'\n');
    }
    let len: u32 = body.len().try_into().unwrap_or(u32::MAX);
    w.write_all(&len.to_be_bytes()).await?;
    w.write_all(&body).await?;
    w.flush().await?;
    Ok(())
}

async fn dispatch(req: &Request, state: &AppState) -> Response {
    match req.method.as_str() {
        "GetTelemetrySnapshot" => Response::ok(req.id, state.snapshot().await),
        "GetSystemInfo" => match state.system_info_clone() {
            Some(info) => Response::ok(req.id, info),
            None => Response::err(req.id, ErrorCode::InternalError, "system_info not yet initialised"),
        },
        "GetServiceStatus" => Response::ok(req.id, state.service_status()),
        "SetPerformanceProfile" => {
            let Some(name) = req
                .params
                .as_ref()
                .and_then(|v| v.get("name"))
                .and_then(|v| v.as_str())
            else {
                return Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    "missing string param 'name' for SetPerformanceProfile",
                );
            };
            match crate::state::PerformanceProfile::from_name(name) {
                Some(profile) => {
                    let status = state.set_power_profile(profile).await;
                    Response::ok(
                        req.id,
                        ChangeResult {
                            status,
                            message: None,
                        },
                    )
                }
                None => Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    format!(
                        "unknown performance profile '{name}'; valid: eco, balanced, performance, luna_boost"
                    ),
                ),
            }
        }
        "SetFanProfile" => {
            let Some(name) = req
                .params
                .as_ref()
                .and_then(|v| v.get("name"))
                .and_then(|v| v.as_str())
            else {
                return Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    "missing string param 'name' for SetFanProfile",
                );
            };
            match crate::state::FanProfile::from_name(name) {
                Some(profile) => {
                    let status = state.set_fan_profile(profile);
                    Response::ok(
                        req.id,
                        ChangeResult {
                            status,
                            message: None,
                        },
                    )
                }
                None => Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    format!(
                        "unknown fan profile '{name}'; valid: silent, balanced, turbo, full_speed"
                    ),
                ),
            }
        }
        "GetDetectedGames" => Response::ok(req.id, state.detected_games()),
        "AddGameToQueue" => {
            let Some(id) = req
                .params
                .as_ref()
                .and_then(|v| v.get("id"))
                .and_then(|v| v.as_str())
            else {
                return Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    "missing string param 'id' for AddGameToQueue",
                );
            };
            let title = req
                .params
                .as_ref()
                .and_then(|v| v.get("title"))
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());
            let runtime = req
                .params
                .as_ref()
                .and_then(|v| v.get("runtime"))
                .and_then(|v| v.as_str())
                .unwrap_or("manual")
                .to_string();
            let entry = state.add_game_to_queue(id.to_string(), title, runtime);
            Response::ok(
                req.id,
                ChangeResult {
                    status: ChangeStatus::Success,
                    message: Some(format!("queued {}", entry.id)),
                },
            )
        }
        "RemoveGameToQueue" => {
            let Some(id) = req
                .params
                .as_ref()
                .and_then(|v| v.get("id"))
                .and_then(|v| v.as_str())
            else {
                return Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    "missing string param 'id' for RemoveGameToQueue",
                );
            };
            let removed = state.remove_game_to_queue(id);
            if removed {
                Response::ok(
                    req.id,
                    ChangeResult {
                        status: ChangeStatus::Success,
                        message: Some(format!("removed {id}")),
                    },
                )
            } else {
                Response::err(
                    req.id,
                    ErrorCode::InvalidArgs,
                    format!("no queued game with id '{id}'"),
                )
            }
        }
        "RestartMonitoring" => {
            let monitor_running = state.restart_monitoring().await;
            Response::ok(
                req.id,
                ChangeResult {
                    status: if monitor_running {
                        ChangeStatus::Success
                    } else {
                        ChangeStatus::Failed
                    },
                    message: None,
                },
            )
        }
        _ => Response::err(req.id, ErrorCode::UnknownMethod, req.method.clone()),
    }
}
