use std::ffi::{CStr, CString};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::os::raw::c_char;
use pyo3::prelude::*;
use serde_json::json;

static SESSIONS: OnceLock<Mutex<HashMap<String, Py<PyAny>>>> = OnceLock::new();
static BACKEND_PATH: OnceLock<String> = OnceLock::new();

type WorkspaceCallback = unsafe extern "C" fn(session_id: *const c_char, variables_json: *const c_char);
type EventCallback = unsafe extern "C" fn(session_id: *const c_char, event_type: *const c_char, data_json: *const c_char);
static WORKSPACE_CALLBACK: Mutex<Option<WorkspaceCallback>> = Mutex::new(None);
static EVENT_CALLBACK: Mutex<Option<EventCallback>> = Mutex::new(None);

fn get_sessions_map() -> &'static Mutex<HashMap<String, Py<PyAny>>> {
    SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Set a callback to be invoked when the workspace variables change.
#[unsafe(no_mangle)]

#[unsafe(no_mangle)]
pub extern "C" fn unilab_set_event_callback(callback: EventCallback) {
    let mut cb = EVENT_CALLBACK.lock().unwrap();
    *cb = Some(callback);
}
#[unsafe(no_mangle)]pub extern "C" fn unilab_set_workspace_callback(callback: WorkspaceCallback) {
    let mut cb = WORKSPACE_CALLBACK.lock().unwrap();
    *cb = Some(callback);
}

/// Initialize the FFI bridge: set sys.path, create sessions map, set UNILAB_WEB_MODE.
/// Returns 0 on success, -1 on failure.
#[unsafe(no_mangle)]
pub extern "C" fn unilab_init(backend_path: *const c_char) -> i32 {
    if backend_path.is_null() {
        return -1;
    }

    #[cfg(target_os = "linux")]
    unsafe {
        // Fix for "undefined symbol: PyContextVar_Type" when loading Python extensions.
        // We need to load libpython with RTLD_GLOBAL so that extension modules can see core symbols.
        let libs = [
            "libpython3.13.so.1.0\0",
            "libpython3.12.so.1.0\0",
            "libpython3.11.so.1.0\0",
            "libpython3.10.so.1.0\0",
            "libpython3.so\0",
        ];
        for lib in libs {
            if !libc::dlopen(lib.as_ptr() as *const _, libc::RTLD_GLOBAL | libc::RTLD_NOW).is_null() {
                break;
            }
        }
    }

    let catch_result = std::panic::catch_unwind(|| {
        let path_str = unsafe { CStr::from_ptr(backend_path) }
            .to_string_lossy()
            .to_string();

        BACKEND_PATH.set(path_str.clone()).ok();
        let _ = get_sessions_map();

        unsafe {
            std::env::set_var("UNILAB_WEB_MODE", "1");
            std::env::set_var("UNILAB_BRIDGE_MODE", "1");
        }

        Python::with_gil(|py| {
            // Force headless matplotlib backend
            if let Ok(m) = py.import("matplotlib") {
                let _ = m.call_method1("use", ("Agg",));
            }

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

            // Set up real-time workspace update callback for FFI
            let py_session_id = session_id.clone();
            let on_changed = pyo3::types::PyCFunction::new_closure(py, None, None, move |args, _kwargs| {
                let py = args.py();
                let variables = args.get_item(0).unwrap();
                let py = variables.py();
                
                let variables_json = (|| {
                    let json_mod = py.import("json").ok()?;
                    let vars_json: String = json_mod
                        .call_method1("dumps", (variables,))
                        .ok()?
                        .extract()
                        .ok()?;
                    Some(vars_json)
                })().unwrap_or_else(|| "{}".to_string());

                if let Some(cb) = *WORKSPACE_CALLBACK.lock().unwrap() {
                    let c_sid = CString::new(py_session_id.clone()).unwrap();
                    let c_json = CString::new(variables_json).unwrap();
                    unsafe {
                        // Transfer ownership to Dart. Dart MUST call unilab_free_string on these pointers.
                        cb(c_sid.into_raw(), c_json.into_raw());
                    }
                }
                Ok::<PyObject, PyErr>(py.None())
            }).map_err(|e| format!("Failed to create closure: {}", e))?;

            
            // Set up real-time event callback for FFI
            let py_session_id_event = session_id.clone();
            let on_event = pyo3::types::PyCFunction::new_closure(py, None, None, move |args, _kwargs| {
                let py = args.py();
                let event_type: String = args.get_item(0).unwrap().extract().unwrap();
                let data_json: String = args.get_item(1).unwrap().extract().unwrap();
                
                if let Some(cb) = *EVENT_CALLBACK.lock().unwrap() {
                    let c_sid = CString::new(py_session_id_event.clone()).unwrap();
                    let c_type = CString::new(event_type).unwrap();
                    let c_json = CString::new(data_json).unwrap();
                    unsafe {
                        cb(c_sid.into_raw(), c_type.into_raw(), c_json.into_raw());
                    }
                }
                Ok::<PyObject, PyErr>(py.None())
            }).map_err(|e| format!("Failed to create event closure: {}", e))?;

            engine.setattr("on_event", on_event)
                .map_err(|e| format!("Failed to set on_event: {}", e))?;

            engine.setattr("on_workspace_changed", on_changed)
                .map_err(|e| format!("Failed to set on_workspace_changed: {}", e))?;

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
            Ok(json!({
                "success": false, 
                "error": e,
                "stderr": format!("Python Error: {}", e),
                "stdout": "",
                "duration_s": 0.0,
                "variables_snapshot": {},
                "plots": []
            }).to_string())
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

            // Call _get_variables() instead of just getting globals
            let vars_dict = engine.call_method0("_get_variables")
                .map_err(|e| format!("Failed to call _get_variables: {}", e))?;

            let json_mod = py.import("json")
                .map_err(|e| format!("Failed to import json: {}", e))?;
            let vars_json = json_mod
                .call_method1("dumps", (vars_dict,))
                .map_err(|e| format!("Failed to dumps variables: {}", e))?
                .extract::<String>()
                .map_err(|e| format!("Failed to extract JSON: {}", e))?;

            let vars_value: serde_json::Value = serde_json::from_str(&vars_json)
                .unwrap_or(json!({}));

            let result = json!({
                "variables": vars_value,
                "total_size_bytes": 0,
                "variable_count": if let Some(obj) = vars_value.as_object() { obj.len() } else { 0 }
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
    line: *const c_char,
) -> *mut c_char {
    if session_id.is_null() || text.is_null() || line.is_null() {
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
        let line_str = unsafe { CStr::from_ptr(line) }
            .to_string_lossy()
            .to_string();

        Python::with_gil(|py| {
            let sessions = get_sessions_map().lock().unwrap();
            let engine = sessions.get(&session_id_str)?.bind(py);

            // Call engine.complete(text, line)
            let suggestions: Vec<String> = engine
                .call_method1("complete", (text_str.clone(), line_str.clone()))
                .ok()?
                .extract()
                .ok()?;

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

/// Send a simulation event (e.g. slider change) to the active Python simulation.
#[unsafe(no_mangle)]
pub extern "C" fn unilab_send_sim_event(event_json: *const c_char) {
    if event_json.is_null() {
        return;
    }

    let event_str = unsafe { CStr::from_ptr(event_json) }
        .to_string_lossy()
        .to_string();

    Python::with_gil(|py| {
        if let Ok(sim_mod) = py.import("backend.core.simulation.engine") {
            if let Ok(push_func) = sim_mod.getattr("push_sim_event") {
                let _ = push_func.call1((event_str,));
            }
        }
    });
}
