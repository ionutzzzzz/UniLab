use std::ffi::{CStr, CString};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::os::raw::c_char;
use pyo3::prelude::*;
use serde_json::json;

static SESSIONS: OnceLock<Mutex<HashMap<String, Py<PyAny>>>> = OnceLock::new();
static BACKEND_PATH: OnceLock<String> = OnceLock::new();

fn get_sessions_map() -> &'static Mutex<HashMap<String, Py<PyAny>>> {
    SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Initialize the FFI bridge: set sys.path, create sessions map, set UNILAB_WEB_MODE.
/// Returns 0 on success, -1 on failure.
#[unsafe(no_mangle)]
pub extern "C" fn unilab_init(backend_path: *const c_char) -> i32 {
    if backend_path.is_null() {
        return -1;
    }

    let catch_result = std::panic::catch_unwind(|| {
        let path_str = unsafe { CStr::from_ptr(backend_path) }
            .to_string_lossy()
            .to_string();

        BACKEND_PATH.set(path_str.clone()).ok();
        let _ = get_sessions_map();

        unsafe {
            std::env::set_var("UNILAB_WEB_MODE", "1");
        }

        Python::with_gil(|py| {
            let sys = py.import("sys")?;
            let pypath = sys.getattr("path")?;

            pypath.call_method1("insert", (0, path_str.as_str()))?;

            let parent = std::path::Path::new(&path_str).parent();
            if let Some(p) = parent {
                if let Some(p_str) = std::ffi::OsStr::new(p.as_os_str()).to_str() {
                    let _ = pypath.call_method1("insert", (0, p_str));
                }
            }

            PyResult::Ok(())
        }).is_ok()
    });

    match catch_result {
        Ok(true) => 0,
        _ => -1,
    }
}

/// Create a session and return JSON: {"session_id":"...","success":true}
#[unsafe(no_mangle)]
pub extern "C" fn unilab_create_session(username: *const c_char) -> *mut c_char {
    if username.is_null() {
        let err = json!({"error": "username is null"}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let username_str = unsafe { CStr::from_ptr(username) }
            .to_string_lossy()
            .to_string();

        let session_id = uuid::Uuid::new_v4().to_string();
        let workspace = format!("/tmp/unilab_{}", session_id);
        let _ = std::fs::create_dir_all(&workspace);

        Python::with_gil(|py| {
            // Import time and get current timestamp
            let time_mod = py.import("time")
                .map_err(|e| format!("Failed to import time: {}", e))?;
            let started_at: f64 = time_mod.call_method0("time")
                .map_err(|e| format!("Failed to get time: {}", e))?
                .extract()
                .map_err(|e| format!("Failed to extract float from time: {}", e))?;

            // Import pathlib and create Path object
            let pathlib = py.import("pathlib")
                .map_err(|e| format!("Failed to import pathlib: {}", e))?;
            let path_cls = pathlib.getattr("Path")
                .map_err(|e| format!("Failed to get Path class: {}", e))?;
            let workspace_py = path_cls.call1((&workspace,))
                .map_err(|e| format!("Failed to create Path object: {}", e))?;

            // Import SessionInfo and create session
            let session_info_cls = py.import("backend.core.models")
                .map_err(|e| format!("Failed to import backend.core.models: {}", e))?
                .getattr("SessionInfo")
                .map_err(|e| format!("Failed to get SessionInfo class: {}", e))?;

            let session_info = session_info_cls.call1((
                session_id.as_str(),
                username_str.as_str(),
                "transpiler",
                started_at,
                workspace_py,
            ))
                .map_err(|e| format!("Failed to create SessionInfo: {}", e))?;

            // Import TranspilerEngine and create engine
            let engine_mod = py.import("backend.core.engines.transpiler")
                .map_err(|e| format!("Failed to import backend.core.engines.transpiler: {}", e))?;
            let engine_cls = engine_mod.getattr("TranspilerEngine")
                .map_err(|e| format!("Failed to get TranspilerEngine class: {}", e))?;
            let engine = engine_cls.call1((session_info,))
                .map_err(|e| format!("Failed to create TranspilerEngine: {}", e))?;

            // Store session
            let mut sessions = get_sessions_map().lock().unwrap();
            sessions.insert(session_id.clone(), engine.into());

            let result = json!({
                "session_id": session_id,
                "success": true
            });
            Ok(result.to_string())
        })
        .or_else::<String, _>(|e: String| {
            eprintln!("Python error: {}", e);
            Ok(json!({"success": false, "error": e}).to_string())
        })
    });

    let json_result = match result {
        Ok(Ok(json)) => json,
        Ok(Err(e)) => json!({"success": false, "error": e}).to_string(),
        Err(_) => json!({"success": false, "error": "Failed to create session (panic)"}).to_string(),
    };

    CString::new(json_result).unwrap().into_raw()
}

/// Execute code in a session. Returns JSON ExecutionResult.
#[unsafe(no_mangle)]
pub extern "C" fn unilab_execute(
    session_id: *const c_char,
    code: *const c_char,
) -> *mut c_char {
    if session_id.is_null() || code.is_null() {
        let err = json!({"success": false, "error": "null pointer"}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let code_str = unsafe { CStr::from_ptr(code) }
            .to_string_lossy()
            .to_string();

        Python::with_gil(|py| -> Result<String, String> {
            let sessions = get_sessions_map().lock().unwrap();
            let engine = sessions.get(&session_id_str)
                .ok_or_else(|| "Session not found".to_string())?;
            let engine = engine.bind(py);

            // Call synchronous wrapper instead of async run_code
            let py_result = engine.call_method1("run_code_sync", (&code_str,))
                .map_err(|e| format!("Failed to call run_code_sync: {}", e))?;

            let dataclasses = py.import("dataclasses")
                .map_err(|e| format!("Failed to import dataclasses: {}", e))?;
            let result_dict = dataclasses.call_method1("asdict", (py_result,))
                .map_err(|e| format!("Failed to convert to dict: {}", e))?;

            let json_mod = py.import("json")
                .map_err(|e| format!("Failed to import json: {}", e))?;
            let json_str = json_mod
                .call_method1("dumps", (result_dict,))
                .map_err(|e| format!("Failed to serialize to JSON: {}", e))?
                .extract::<String>()
                .map_err(|e| format!("Failed to extract JSON string: {}", e))?;

            Ok(json_str)
        })
        .or_else(|e: String| -> Result<String, String> {
            eprintln!("Python error in unilab_execute: {}", e);
            Ok(json!({"success": false, "error": e}).to_string())
        })
    });

    let json_result = match result {
        Ok(Ok(json)) => json,
        Ok(Err(e)) => json!({"success": false, "error": e}).to_string(),
        Err(_) => json!({"success": false, "error": "Execution failed (panic)"}).to_string(),
    };

    CString::new(json_result).unwrap().into_raw()
}

/// Get workspace variables. Returns JSON: {"variables":{...}}
#[unsafe(no_mangle)]
pub extern "C" fn unilab_get_workspace(session_id: *const c_char) -> *mut c_char {
    if session_id.is_null() {
        let err = json!({"variables": {}}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();

        Python::with_gil(|py| -> Result<String, String> {
            let sessions = get_sessions_map().lock().unwrap();
            let engine = sessions.get(&session_id_str)
                .ok_or_else(|| "Session not found".to_string())?;
            let engine = engine.bind(py);

            // Get globals dict directly
            let globals_dict = engine.getattr("globals")
                .map_err(|e| format!("Failed to get globals: {}", e))?;

            let json_mod = py.import("json")
                .map_err(|e| format!("Failed to import json: {}", e))?;
            let globals_json = json_mod
                .call_method1("dumps", (globals_dict,))
                .map_err(|e| format!("Failed to dumps globals: {}", e))?
                .extract::<String>()
                .map_err(|e| format!("Failed to extract JSON: {}", e))?;

            let globals_value: serde_json::Value = serde_json::from_str(&globals_json)
                .unwrap_or(json!({}));

            let result = json!({
                "variables": globals_value,
                "total_size_bytes": 0,
                "variable_count": if let Some(obj) = globals_value.as_object() { obj.len() } else { 0 }
            });

            Ok(result.to_string())
        })
        .or_else(|e: String| -> Result<String, String> {
            eprintln!("Python error in unilab_get_workspace: {}", e);
            Ok(json!({"variables": {}}).to_string())
        })
    });

    let json_result = match result {
        Ok(Ok(json)) => json,
        Ok(Err(e)) => json!({"variables": {}}).to_string(),
        Err(_) => json!({"variables": {}}).to_string(),
    };

    CString::new(json_result).unwrap().into_raw()
}

/// Get tab autocomplete suggestions. Returns JSON: {"suggestions":[...]}
#[unsafe(no_mangle)]
pub extern "C" fn unilab_get_autocomplete(
    session_id: *const c_char,
    text: *const c_char,
) -> *mut c_char {
    if session_id.is_null() || text.is_null() {
        let err = json!({"suggestions": []}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let text_str = unsafe { CStr::from_ptr(text) }
            .to_string_lossy()
            .to_string();

        Python::with_gil(|py| {
            let sessions = get_sessions_map().lock().unwrap();
            let engine = sessions.get(&session_id_str)?.bind(py);

            let globals_dict = engine.getattr("globals").ok()?;

            // Get dir() of globals and filter
            let builtins = py.import("builtins").ok()?;
            let dir_fn = builtins.getattr("dir").ok()?;
            let all_items = dir_fn.call1((globals_dict,)).ok()?;
            let all_items: Vec<String> = all_items.extract().ok()?;

            let suggestions: Vec<String> = all_items
                .iter()
                .filter(|s| s.starts_with(&text_str))
                .cloned()
                .collect();

            let result = json!({
                "suggestions": suggestions
            });
            Some(result.to_string())
        })
    });

    let json_result = result
        .ok()
        .flatten()
        .unwrap_or_else(|| json!({"suggestions": []}).to_string());

    CString::new(json_result).unwrap().into_raw()
}

/// List files in the session workspace. Returns JSON: {"files":[...]}
#[unsafe(no_mangle)]
pub extern "C" fn unilab_list_files(session_id: *const c_char) -> *mut c_char {
    if session_id.is_null() {
        let err = json!({"files": []}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();

        let workspace_path = format!("/tmp/unilab_{}", session_id_str);
        let mut files = Vec::new();

        if let Ok(entries) = std::fs::read_dir(&workspace_path) {
            for entry in entries.flatten() {
                if let Ok(metadata) = entry.metadata() {
                    let name = entry
                        .file_name()
                        .to_string_lossy()
                        .to_string();
                    let path = entry
                        .path()
                        .to_string_lossy()
                        .to_string();
                    let size = metadata.len();
                    let is_directory = metadata.is_dir();

                    files.push(json!({
                        "name": name,
                        "path": path,
                        "size": size,
                        "is_directory": is_directory
                    }));
                }
            }
        }

        let result = json!({
            "files": files,
            "total": files.len(),
            "path": workspace_path
        });
        Some(result.to_string())
    });

    let json_result = result
        .ok()
        .flatten()
        .unwrap_or_else(|| json!({"files": []}).to_string());

    CString::new(json_result).unwrap().into_raw()
}

/// Create or overwrite a file in the session workspace. Returns JSON: {"success":true}
#[unsafe(no_mangle)]
pub extern "C" fn unilab_create_file(
    session_id: *const c_char,
    filename: *const c_char,
    content: *const c_char,
) -> *mut c_char {
    if session_id.is_null() || filename.is_null() || content.is_null() {
        let err = json!({"success": false, "error": "null pointer"}).to_string();
        return CString::new(err).unwrap().into_raw();
    }

    let result = std::panic::catch_unwind(|| {
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let filename_str = unsafe { CStr::from_ptr(filename) }
            .to_string_lossy()
            .to_string();
        let content_str = unsafe { CStr::from_ptr(content) }
            .to_string_lossy()
            .to_string();

        let workspace_path = format!("/tmp/unilab_{}", session_id_str);
        let file_path = std::path::Path::new(&workspace_path).join(&filename_str);

        std::fs::write(&file_path, &content_str).ok()?;

        let result = json!({
            "success": true,
            "path": file_path.to_string_lossy().to_string()
        });
        Some(result.to_string())
    });

    let json_result = result
        .ok()
        .flatten()
        .unwrap_or_else(|| json!({"success": false, "error": "Failed to create file"}).to_string());

    CString::new(json_result).unwrap().into_raw()
}

/// Free a string allocated by the FFI bridge. MUST be called after every function that returns *mut c_char.
#[unsafe(no_mangle)]
pub extern "C" fn unilab_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}
