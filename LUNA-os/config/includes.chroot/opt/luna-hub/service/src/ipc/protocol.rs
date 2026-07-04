//! IPC method enumeration.

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, Deserialize)]
pub struct Request {
    pub id: u64,
    pub method: String,
    #[serde(default)]
    pub params: Option<Value>,
}

#[derive(Debug, Clone, Serialize)]
pub struct Response {
    pub id: u64,
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<ErrorBody>,
}

impl Response {
    pub fn ok(id: u64, data: impl Serialize) -> Self {
        Self {
            id,
            ok: true,
            data: Some(serde_json::to_value(data).unwrap_or(Value::Null)),
            error: None,
        }
    }

    pub fn err(id: u64, code: ErrorCode, message: impl Into<String>) -> Self {
        Self {
            id,
            ok: false,
            data: None,
            error: Some(ErrorBody {
                code: code.into(),
                message: message.into(),
            }),
        }
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct ErrorBody {
    pub code: ErrorCode,
    pub message: String,
}

#[derive(Debug, Clone, Copy)]
pub enum ErrorCode {
    InvalidArgs,
    UnknownMethod,
    InternalError,
    SerializationError,
}

impl From<ErrorCode> for &'static str {
    fn from(c: ErrorCode) -> Self {
        match c {
            ErrorCode::InvalidArgs => "INVALID_ARGS",
            ErrorCode::UnknownMethod => "UNKNOWN_METHOD",
            ErrorCode::InternalError => "INTERNAL_ERROR",
            ErrorCode::SerializationError => "SERIALIZATION_ERROR",
        }
    }
}

impl serde::Serialize for ErrorCode {
    fn serialize<S: serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
        let v: &'static str = (*self).into();
        s.serialize_str(v)
    }
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub struct ChangeResult {
    pub status: crate::state::ChangeStatus,
    pub message: Option<String>,
}
