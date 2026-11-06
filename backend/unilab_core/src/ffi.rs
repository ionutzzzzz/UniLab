use std::ffi::{CStr, CString};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::os::raw::c_char;
use pyo3::prelude::*;
use serde_json::json;

static SESSIONS: OnceLock<Mutex<HashMap<String, Py<PyAny>>>> = OnceLock::new();
static BACKEND_PATH: OnceLock<String> = OnceLock::new();
static SIM_EVENT_TX: OnceLock<std::sync::mpsc::Sender<String>> = OnceLock::new();

type WorkspaceCallback = unsafe extern "C" fn(session_id: *const c_char, variables_json: *const c_char);
type EventCallback = unsafe extern "C" fn(session_id: *const c_char, event_type: *const c_char, data_json: *const c_char);

static WORKSPACE_CALLBACK: Mutex<Option<WorkspaceCallback>> = Mutex::new(None);
static EVENT_CALLBACK: Mutex<Option<EventCallback>> = Mutex::new(None);

fn get_sessions_map() -> &'static Mutex<HashMap<String, Py<PyAny>>> {
    SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn to_raw_cstr(mut s: String) -> *mut c_char {
    if s.contains('\0') {
        s = s.replace('\0', "");
    }
    match CString::new(s) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => {
            let fallback = CString::new("{\"error\":\"encoding error\"}").unwrap();
            fallback.into_raw()
        }
    }
}

fn dumps_safe(py: Python<'_>, obj: &Bound<'_, PyAny>) -> String {
    let json_mod = match py.import("json") {
        Ok(m) => m,
        Err(_) => return "{}".to_string(),
    };
    let kwargs = pyo3::types::PyDict::new(py);
    if kwargs.set_item("allow_nan", false).is_ok() {
        if let Ok(res) = json_mod.call_method("dumps", (obj,), Some(&kwargs)) {
            if let Ok(s) = res.extract::<String>() {
                return s;
            }
        }
    }
    let clean_code = pyo3::ffi::c_str!(
        "def _clean(val):\n    import math\n    if isinstance(val, float):\n        if math.isnan(val) or math.isinf(val):\n            return None\n        return val\n    if isinstance(val, dict):\n        return {k: _clean(v) for k, v in val.items()}\n    if isinstance(val, list):\n        return [_clean(v) for v in val]\n    return val\n"
    );
    let _ = py.run(clean_code, None, None);
    if let Ok(clean_fn) = py.eval(pyo3::ffi::c_str!("_clean"), None, None) {
        if let Ok(cleaned) = clean_fn.call1((obj,)) {
            if let Ok(res) = json_mod.call_method1("dumps", (cleaned,)) {
                if let Ok(s) = res.extract::<String>() {
                    return s;
                }
            }
        }
    }
    "{}".to_string()
}

fn get_sim_event_sender() -> &'static std::sync::mpsc::Sender<String> {
    SIM_EVENT_TX.get_or_init(|| {
        let (tx, rx) = std::sync::mpsc::channel::<String>();
        let _ = std::thread::Builder::new()
            .name("unilab_sim_event_worker".to_string())
            .spawn(move || {
                while let Ok(event_str) = rx.recv() {
                    let _ = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                        Python::with_gil(|py| {
                            if let Ok(sim_mod) = import_module(py, "backend.core.simulation.engine") {
                                if let Ok(push_func) = sim_mod.getattr("push_sim_event") {
                                    let _ = push_func.call1((&event_str,));
                                }
                            }
                            if event_str.contains("STOP") {
                                let sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
                                for engine in sessions.values() {
                                    let bound = engine.bind(py);
                                    if bound.hasattr("request_cancel").unwrap_or(false) {
                                        let _ = bound.call_method0("request_cancel");
                                    }
                                }
                            }
                        });
                    }));
                }
            });
        tx
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_set_event_callback(callback: Option<EventCallback>) {
    let _ = std::panic::catch_unwind(|| {
        let mut cb = EVENT_CALLBACK.lock().unwrap_or_else(|e| e.into_inner());
        *cb = callback;
    });
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_set_workspace_callback(callback: Option<WorkspaceCallback>) {
    let _ = std::panic::catch_unwind(|| {
        let mut cb = WORKSPACE_CALLBACK.lock().unwrap_or_else(|e| e.into_inner());
        *cb = callback;
    });
}

fn add_venv_site_packages(pypath: &Bound<'_, PyAny>, venv_path: &std::path::Path) {
    if !venv_path.exists() {
        return;
    }
    // Unix: lib/python*/site-packages
    let venv_lib = venv_path.join("lib");
    if venv_lib.exists() {
        if let Ok(entries) = std::fs::read_dir(&venv_lib) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    let sp = path.join("site-packages");
                    if sp.exists() {
                        if let Some(s) = sp.to_str() {
                            let _ = pypath.call_method1("insert", (0, s));
                        }
                    }
                }
            }
        }
    }
    // Windows: Lib/site-packages
    let win_lib = venv_path.join("Lib").join("site-packages");
    if win_lib.exists() {
        if let Some(s) = win_lib.to_str() {
            let _ = pypath.call_method1("insert", (0, s));
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_init(backend_path: *const c_char) -> i32 {
    let result = std::panic::catch_unwind(|| {
        if backend_path.is_null() {
            return -1;
        }

        #[cfg(all(target_os = "linux", feature = "python-bridge"))]
        unsafe {
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

        let path_str = unsafe { CStr::from_ptr(backend_path) }
            .to_string_lossy()
            .to_string();

        let abs_backend_parent = std::path::Path::new(&path_str)
            .canonicalize()
            .unwrap_or_else(|_| std::path::PathBuf::from(&path_str));
        let abs_path_str = abs_backend_parent.to_string_lossy().to_string();

        BACKEND_PATH.set(abs_path_str.clone()).ok();
        let _ = get_sessions_map();
        let _ = get_sim_event_sender();

        let py_init_ok = Python::with_gil(|py| -> PyResult<()> {
            if let Ok(os) = py.import("os") {
                if let Ok(environ) = os.getattr("environ") {
                    let _ = environ.set_item("UNILAB_BRIDGE_MODE", "1");
                    let _ = environ.set_item("UNILAB_WEB_MODE", "1");
                }
            }

            if let Ok(m) = py.import("matplotlib") {
                let _ = m.call_method1("use", ("Agg",));
            }

            let sys = py.import("sys")?;
            let pypath = sys.getattr("path")?;

            pypath.call_method1("insert", (0, &abs_path_str))?;

            // Discover and add virtualenvs to sys.path (both venv and .venv, Unix and Windows)
            let base_dirs = [
                std::path::PathBuf::from("/opt/unilab"),
                abs_backend_parent.clone(),
                abs_backend_parent.parent().map(|p| p.to_path_buf()).unwrap_or_default(),
                abs_backend_parent.parent().and_then(|p| p.parent()).map(|p| p.to_path_buf()).unwrap_or_default(),
                abs_backend_parent.parent().and_then(|p| p.parent()).and_then(|p| p.parent()).map(|p| p.to_path_buf()).unwrap_or_default(),
            ];

            for base in &base_dirs {
                if base.as_os_str().is_empty() {
                    continue;
                }
                add_venv_site_packages(&pypath, &base.join("venv"));
                add_venv_site_packages(&pypath, &base.join(".venv"));
            }

            Ok(())
        });

        if py_init_ok.is_ok() { 0 } else { -1 }
    });

    result.unwrap_or(-1)
}

fn import_module<'py>(py: Python<'py>, module_name: &str) -> PyResult<Bound<'py, PyModule>> {
    match py.import(module_name) {
        Ok(m) => Ok(m),
        Err(original_err) => {
            let relative_name = if module_name.starts_with("backend.") {
                &module_name[8..]
            } else {
                module_name
            };
            match py.import(relative_name) {
                Ok(m) => Ok(m),
                Err(_) => Err(original_err),
            }
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_create_session(username: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if username.is_null() {
            let err = json!({"success": false, "error": "username is null"}).to_string();
            return to_raw_cstr(err);
        }

        let username_str = unsafe { CStr::from_ptr(username) }
            .to_string_lossy()
            .to_string();

        let session_id = uuid::Uuid::new_v4().to_string();
        let workspace = std::env::temp_dir().join(format!("unilab_{}", session_id));
        let workspace_str = workspace.to_string_lossy().to_string();
        let _ = std::fs::create_dir_all(&workspace);

        let py_result = Python::with_gil(|py| -> Result<String, String> {
            let time_mod = py.import("time").map_err(|e| e.to_string())?;
            let started_at: f64 = time_mod
                .call_method0("time")
                .map_err(|e| e.to_string())?
                .extract()
                .map_err(|e| e.to_string())?;

            let pathlib = py.import("pathlib").map_err(|e| e.to_string())?;
            let workspace_py = pathlib
                .getattr("Path")
                .map_err(|e| e.to_string())?
                .call1((&workspace_str,))
                .map_err(|e| e.to_string())?;

            let models_mod = import_module(py, "backend.core.models").map_err(|e| e.to_string())?;
            let session_info_cls = models_mod.getattr("SessionInfo").map_err(|e| e.to_string())?;

            let session_info = session_info_cls.call1((
                session_id.as_str(),
                username_str.as_str(),
                "transpiler",
                started_at,
                workspace_py,
            )).map_err(|e| e.to_string())?;

            let engine_mod = import_module(py, "backend.core.engines.transpiler").map_err(|e| e.to_string())?;
            let engine_cls = engine_mod.getattr("TranspilerEngine").map_err(|e| e.to_string())?;
            let engine = engine_cls.call1((session_info,)).map_err(|e| e.to_string())?;

            let py_session_id = session_id.clone();
            let on_changed = pyo3::types::PyCFunction::new_closure(py, None, None, move |args, _kwargs| {
                let py = args.py();
                if let Ok(variables) = args.get_item(0) {
                    let variables_json = dumps_safe(py, &variables);
                    let cb_opt = *WORKSPACE_CALLBACK.lock().unwrap_or_else(|e| e.into_inner());
                    if let Some(cb) = cb_opt {
                        let c_sid = to_raw_cstr(py_session_id.clone());
                        let c_json = to_raw_cstr(variables_json);
                        unsafe {
                            cb(c_sid, c_json);
                        }
                    }
                }
                Ok::<PyObject, PyErr>(py.None())
            }).map_err(|e| e.to_string())?;

            let py_session_id_event = session_id.clone();
            let on_event = pyo3::types::PyCFunction::new_closure(py, None, None, move |args, _kwargs| {
                let py = args.py();
                let event_type: String = args.get_item(0).and_then(|a| a.extract()).unwrap_or_default();
                let data_json: String = args.get_item(1).and_then(|a| a.extract()).unwrap_or_else(|_| "{}".to_string());

                let cb_opt = *EVENT_CALLBACK.lock().unwrap_or_else(|e| e.into_inner());
                if let Some(cb) = cb_opt {
                    let c_sid = to_raw_cstr(py_session_id_event.clone());
                    let c_type = to_raw_cstr(event_type);
                    let c_json = to_raw_cstr(data_json);
                    unsafe {
                        cb(c_sid, c_type, c_json);
                    }
                }
                Ok::<PyObject, PyErr>(py.None())
            }).map_err(|e| e.to_string())?;

            engine.setattr("on_event", on_event).map_err(|e| e.to_string())?;
            engine.setattr("on_workspace_changed", on_changed).map_err(|e| e.to_string())?;

            let mut sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            sessions.insert(session_id.clone(), engine.into());

            Ok(json!({
                "session_id": session_id,
                "success": true
            }).to_string())
        });

        match py_result {
            Ok(json) => to_raw_cstr(json),
            Err(e) => to_raw_cstr(json!({"success": false, "error": format!("Python error: {}", e)}).to_string()),
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"success": false, "error": "Failed to create session (panic)"}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_destroy_session(session_id: *const c_char) -> i32 {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() {
            return -1;
        }
        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();

        if uuid::Uuid::parse_str(&session_id_str).is_err() {
            return -1;
        }

        let engine_opt = {
            let mut sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            sessions.remove(&session_id_str)
        };

        if let Some(engine) = engine_opt {
            Python::with_gil(|py| {
                let bound = engine.bind(py);
                if bound.hasattr("request_cancel").unwrap_or(false) {
                    let _ = bound.call_method0("request_cancel");
                }
            });
        }

        let workspace_path = std::env::temp_dir().join(format!("unilab_{}", session_id_str));
        if workspace_path.exists() {
            let _ = std::fs::remove_dir_all(&workspace_path);
        }

        0
    });

    result.unwrap_or(-1)
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_transpile(code: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if code.is_null() {
            let err = json!({"success": false, "error": "code is null"}).to_string();
            return to_raw_cstr(err);
        }

        let code_str = unsafe { CStr::from_ptr(code) }
            .to_string_lossy()
            .to_string();

        let py_res = Python::with_gil(|py| -> Result<String, String> {
            let transpiler_mod = import_module(py, "backend.core.transpiler_core").map_err(|e| e.to_string())?;
            let transpiler_cls = transpiler_mod.getattr("UniLabTranspiler").map_err(|e| e.to_string())?;
            let transpiler = transpiler_cls.call0().map_err(|e| e.to_string())?;

            let py_result = transpiler.call_method1("transpile", (code_str,)).map_err(|e| e.to_string())?;
            let python_code: String = py_result
                .get_item(0)
                .map_err(|e| e.to_string())?
                .extract()
                .map_err(|e| e.to_string())?;

            let result = json!({
                "success": true,
                "python_code": python_code
            });
            Ok(result.to_string())
        });

        match py_res {
            Ok(json) => to_raw_cstr(json),
            Err(e) => to_raw_cstr(json!({"success": false, "error": e}).to_string()),
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"success": false, "error": "Transpilation failed (panic)"}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_execute(
    session_id: *const c_char,
    code: *const c_char,
    timeout: f64,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() || code.is_null() {
            let err = json!({"success": false, "error": "null pointer"}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let code_str = unsafe { CStr::from_ptr(code) }
            .to_string_lossy()
            .to_string();

        let py_res = Python::with_gil(|py| -> Result<String, String> {
            let sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            let engine = sessions.get(&session_id_str)
                .ok_or_else(|| "Session not found".to_string())?;
            let engine = engine.bind(py);

            let py_result = engine.call_method1("run_code_sync", (&code_str, timeout)).map_err(|e| e.to_string())?;

            let dataclasses = py.import("dataclasses").map_err(|e| e.to_string())?;
            let result_dict = dataclasses.call_method1("asdict", (py_result,)).map_err(|e| e.to_string())?;

            Ok(dumps_safe(py, &result_dict))
        });

        match py_res {
            Ok(json) => to_raw_cstr(json),
            Err(e) => to_raw_cstr(json!({"success": false, "error": e, "stderr": format!("Python Error: {}", e)}).to_string()),
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"success": false, "error": "Execution failed (panic)"}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_execute_with_filename(
    session_id: *const c_char,
    code: *const c_char,
    filename: *const c_char,
    timeout: f64,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() || code.is_null() {
            let err = json!({"success": false, "error": "null pointer"}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let code_str = unsafe { CStr::from_ptr(code) }
            .to_string_lossy()
            .to_string();
        let filename_str = if filename.is_null() {
            None
        } else {
            Some(unsafe { CStr::from_ptr(filename) }.to_string_lossy().to_string())
        };

        let py_res = Python::with_gil(|py| -> Result<String, String> {
            let sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            let engine = sessions.get(&session_id_str)
                .ok_or_else(|| "Session not found".to_string())?;
            let engine = engine.bind(py);

            let py_result = engine.call_method1("run_code_sync", (&code_str, timeout, filename_str)).map_err(|e| e.to_string())?;

            let dataclasses = py.import("dataclasses").map_err(|e| e.to_string())?;
            let result_dict = dataclasses.call_method1("asdict", (py_result,)).map_err(|e| e.to_string())?;

            Ok(dumps_safe(py, &result_dict))
        });

        match py_res {
            Ok(json) => to_raw_cstr(json),
            Err(e) => to_raw_cstr(json!({"success": false, "error": e, "stderr": format!("Python Error: {}", e)}).to_string()),
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"success": false, "error": "Execution failed (panic)"}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_get_workspace(session_id: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() {
            let err = json!({"variables": {}}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();

        let py_res = Python::with_gil(|py| -> Result<String, String> {
            let sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            let engine = sessions.get(&session_id_str)
                .ok_or_else(|| "Session not found".to_string())?;
            let engine = engine.bind(py);

            let vars_dict = engine.call_method0("_get_variables").map_err(|e| e.to_string())?;
            Ok(dumps_safe(py, &vars_dict))
        });

        match py_res {
            Ok(json) => to_raw_cstr(format!("{{\"variables\": {}}}", json)),
            Err(e) => to_raw_cstr(json!({"variables": {}, "error": e}).to_string()),
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"variables": {}}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_get_autocomplete(
    session_id: *const c_char,
    text: *const c_char,
    line: *const c_char,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() || text.is_null() || line.is_null() {
            let err = json!({"suggestions": []}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let text_str = unsafe { CStr::from_ptr(text) }
            .to_string_lossy()
            .to_string();
        let line_str = unsafe { CStr::from_ptr(line) }
            .to_string_lossy()
            .to_string();

        let opt_json = Python::with_gil(|py| -> Option<String> {
            let sessions = get_sessions_map().lock().unwrap_or_else(|e| e.into_inner());
            let engine = sessions.get(&session_id_str)?.bind(py);

            let suggestions: Vec<String> = engine
                .call_method1("complete", (text_str.clone(), line_str.clone()))
                .ok()?
                .extract()
                .ok()?;

            let result = json!({
                "suggestions": suggestions
            });
            Some(result.to_string())
        });

        to_raw_cstr(opt_json.unwrap_or_else(|| json!({"suggestions": []}).to_string()))
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"suggestions": []}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_list_files(session_id: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() {
            let err = json!({"files": []}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();

        if uuid::Uuid::parse_str(&session_id_str).is_err() {
            let err = json!({"files": [], "error": "Invalid session_id"}).to_string();
            return to_raw_cstr(err);
        }

        let workspace_path = std::env::temp_dir().join(format!("unilab_{}", session_id_str));
        let workspace_path_str = workspace_path.to_string_lossy().to_string();
        let mut files = Vec::new();

        if let Ok(entries) = std::fs::read_dir(&workspace_path) {
            for entry in entries.flatten() {
                if let Ok(metadata) = entry.metadata() {
                    let name = entry.file_name().to_string_lossy().to_string();
                    let path = entry.path().to_string_lossy().to_string();
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
            "path": workspace_path_str
        });
        to_raw_cstr(result.to_string())
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"files": []}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_create_file(
    session_id: *const c_char,
    filename: *const c_char,
    content: *const c_char,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if session_id.is_null() || filename.is_null() || content.is_null() {
            let err = json!({"success": false, "error": "null pointer"}).to_string();
            return to_raw_cstr(err);
        }

        let session_id_str = unsafe { CStr::from_ptr(session_id) }
            .to_string_lossy()
            .to_string();
        let filename_str = unsafe { CStr::from_ptr(filename) }
            .to_string_lossy()
            .to_string();
        let content_str = unsafe { CStr::from_ptr(content) }
            .to_string_lossy()
            .to_string();

        if uuid::Uuid::parse_str(&session_id_str).is_err() {
            let err = json!({"success": false, "error": "Invalid session_id"}).to_string();
            return to_raw_cstr(err);
        }

        let rel_path = std::path::Path::new(&filename_str);
        if rel_path.is_absolute()
            || rel_path.components().any(|c| matches!(c, std::path::Component::ParentDir | std::path::Component::Prefix(_)))
        {
            let err = json!({"success": false, "error": "Invalid relative filename"}).to_string();
            return to_raw_cstr(err);
        }

        let workspace_path = std::env::temp_dir().join(format!("unilab_{}", session_id_str));
        let file_path = workspace_path.join(rel_path);

        if let Some(parent) = file_path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        match std::fs::write(&file_path, &content_str) {
            Ok(_) => {
                let result = json!({
                    "success": true,
                    "path": file_path.to_string_lossy().to_string()
                });
                to_raw_cstr(result.to_string())
            }
            Err(e) => {
                let err = json!({"success": false, "error": format!("Write error: {}", e)}).to_string();
                to_raw_cstr(err)
            }
        }
    });

    result.unwrap_or_else(|_| to_raw_cstr(json!({"success": false, "error": "Failed to create file (panic)"}).to_string()))
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_ping() -> i32 {
    let result = std::panic::catch_unwind(|| {
        Python::with_gil(|py| {
            match py.import("sys") {
                Ok(_) => 0,
                Err(_) => -1,
            }
        })
    });
    result.unwrap_or(-1)
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_free_string(ptr: *mut c_char) {
    let _ = std::panic::catch_unwind(|| {
        if !ptr.is_null() {
            unsafe {
                drop(CString::from_raw(ptr));
            }
        }
    });
}

#[unsafe(no_mangle)]
pub extern "C" fn unilab_send_sim_event(event_json: *const c_char) {
    let _ = std::panic::catch_unwind(|| {
        if event_json.is_null() {
            return;
        }
        let event_str = unsafe { CStr::from_ptr(event_json) }
            .to_string_lossy()
            .to_string();
        let _ = get_sim_event_sender().send(event_str);
    });
}
