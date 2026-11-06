"""
cli_client.py

A simple Tkinter desktop client that provides a terminal-like interface to
the UniLabCore backend (core/main.py). It runs an asyncio event loop in a
background thread and communicates with UniLabCore via run_coroutine_threadsafe.

Place this file at: <project_root>/client/cli_client.py
Run from project root (so `core` package/module is importable):
    python client/cli_client.py
"""

import sys
import threading
import asyncio
import pathlib
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, simpledialog, filedialog

# ensure project root is on sys.path so `backend` package is importable
PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# import UniLabCore from your core/unilab_core.py module
try:
    from backend.core.unilab_core import UniLabCore
    from backend.core.models import BackendConfig
except Exception as e:
    raise RuntimeError("Could not import UniLabCore from core.unilab_core") from e


class AsyncRunner:
    """
    Helper that runs an asyncio event loop in a background thread and provides
    a run(coro) -> concurrent.futures.Future convenience via run_coroutine_threadsafe.
    """

    def __init__(self):
        self.loop = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._start_loop, daemon=True)
        self._thread.start()

    def _start_loop(self):
        asyncio.set_event_loop(self.loop)
        self.loop.run_forever()

    def run(self, coro):
        """Schedule a coroutine on the loop and return a Future (concurrent.futures.Future)."""
        return asyncio.run_coroutine_threadsafe(coro, self.loop)

    def stop(self):
        def _stop():
            for task in asyncio.all_tasks(loop=self.loop):
                task.cancel()
            self.loop.stop()
        self.loop.call_soon_threadsafe(_stop)
        self._thread.join(timeout=1)


class UniLabCLIApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UniLab CLI Client")
        self.geometry("900x600")
        # dark terminal style
        self.configure(bg="#1e1e1e")
        ttk.Style(self)
        # default ttk style may not change much; we'll style manual widgets

        # Async runner & core backend
        self.runner = AsyncRunner()
        cfg = BackendConfig(
            workspace_root=pathlib.Path("./.console_workspaces/client_workspaces"),
            use_docker=False
        )
        self.core = UniLabCore(cfg)
        # start core
        self.runner.run(self.core.start())

        # current session id
        self.session_id = None

        # Build UI
        self._build_ui()

        # bind Enter in the entry to run small commands
        self.cmd_entry.bind("<Return>", lambda e: self._on_run_command())

        # on close, ensure cleanup
        self.protocol("WM_DELETE_WINDOW", self._on_close)

        # friendly prompt
        self._print_banner()

    def _build_ui(self):
        # top control frame
        top = tk.Frame(self, bg="#1e1e1e")
        top.pack(side=tk.TOP, fill=tk.X, padx=6, pady=6)

        btn_create = tk.Button(top, text="Create Session", command=self._on_create_session, bg="#252526", fg="#d4d4d4")
        btn_create.pack(side=tk.LEFT, padx=4)
        btn_stop = tk.Button(top, text="Stop Session", command=self._on_stop_session, bg="#252526", fg="#d4d4d4")
        btn_stop.pack(side=tk.LEFT, padx=4)

        btn_files = tk.Button(top, text="List Files", command=self._on_list_files, bg="#252526", fg="#d4d4d4")
        btn_files.pack(side=tk.LEFT, padx=4)
        btn_vars = tk.Button(top, text="List Vars", command=self._on_list_vars, bg="#252526", fg="#d4d4d4")
        btn_vars.pack(side=tk.LEFT, padx=4)

        btn_run_script = tk.Button(top, text="Run Script...", command=self._on_run_script_dialog, bg="#007acc", fg="#ffffff")
        btn_run_script.pack(side=tk.LEFT, padx=6)

        btn_export_data = tk.Button(top, text="Export Data...", command=self._on_export_data_dialog, bg="#6a9955", fg="#ffffff")
        btn_export_data.pack(side=tk.LEFT, padx=4)

        btn_export_plot = tk.Button(top, text="Export Plot...", command=self._on_export_plot_dialog, bg="#0e639c", fg="#ffffff")
        btn_export_plot.pack(side=tk.LEFT, padx=4)

        self.session_label = tk.Label(top, text="No session", bg="#1e1e1e", fg="#9cdcfe")
        self.session_label.pack(side=tk.RIGHT, padx=8)

        # central text area (terminal-like)
        self.terminal = scrolledtext.ScrolledText(self, wrap=tk.WORD, height=30, bg="#1e1e1e", fg="#d4d4d4",
                                                  insertbackground="#d4d4d4", font=("Consolas", 11))
        self.terminal.pack(fill=tk.BOTH, expand=True, padx=6, pady=(0,6))
        self.terminal.configure(state=tk.DISABLED)

        # command entry frame
        bottom = tk.Frame(self, bg="#1e1e1e")
        bottom.pack(side=tk.BOTTOM, fill=tk.X, padx=6, pady=6)

        self.cmd_entry = tk.Entry(bottom, bg="#252526", fg="#d4d4d4", insertbackground="#d4d4d4", font=("Consolas", 11))
        self.cmd_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0,6))
        btn_send = tk.Button(bottom, text="Run", command=self._on_run_command, bg="#0e639c", fg="#fff")
        btn_send.pack(side=tk.RIGHT)

    # ---------------------------
    # UI helpers
    # ---------------------------
    def _print_banner(self):
        self._write_terminal("UniLab CLI Client\nType UniLab commands and press Run. Create a session first.\n\n", "banner")

    def _write_terminal(self, text: str, tag: str = None):
        self.terminal.configure(state=tk.NORMAL)
        if tag == "error":
            self.terminal.insert(tk.END, text + "\n", ("err",))
        elif tag == "success":
            self.terminal.insert(tk.END, text + "\n", ("ok",))
        else:
            self.terminal.insert(tk.END, text + "\n")
        self.terminal.see(tk.END)
        self.terminal.configure(state=tk.DISABLED)
        # add tags style
        self.terminal.tag_config("err", foreground="#f48771")
        self.terminal.tag_config("ok", foreground="#6a9955")
        self.terminal.tag_config("banner", foreground="#9cdcfe")

    # ---------------------------
    # UI callbacks -> schedule coros
    # ---------------------------
    def _on_create_session(self):
        username = simpledialog.askstring("Create session", "Enter username:", parent=self, initialvalue="alice")
        if not username:
            return
        fut = self.runner.run(self.core.create_session(username=username, engine="transpiler", use_docker=False))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_session_created(f)))

    def _on_session_created(self, fut):
        try:
            s = fut.result()
        except Exception as e:
            self._write_terminal(f"Failed to create session: {e}", "error")
            return
        self.session_id = s.session_id
        self.session_label.configure(text=f"Session: {s.username} ({s.session_id[:8]})")
        self._write_terminal(f"Session created: {s.session_id} workspace={s.workspace_path}", "success")

    def _on_stop_session(self):
        if not self.session_id:
            self._write_terminal("No active session to stop.", "error")
            return
        fut = self.runner.run(self.core.stop_session(self.session_id))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_session_stopped(f)))

    def _on_session_stopped(self, fut):
        try:
            fut.result()
        except Exception as e:
            self._write_terminal(f"Error stopping session: {e}", "error")
            return
        self._write_terminal(f"Session stopped: {self.session_id}", "success")
        self.session_id = None
        self.session_label.configure(text="No session")

    def _on_run_command(self):
        cmd = self.cmd_entry.get().strip()
        if not cmd:
            return
        if not self.session_id:
            self._write_terminal("No active session. Create a session first.", "error")
            return
        self._write_terminal(f"> {cmd}")
        # run code in core.run_code
        fut = self.runner.run(self.core.run_code(self.session_id, cmd, timeout=30.0))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_run_complete(f)))

        # clear entry
        self.cmd_entry.delete(0, tk.END)

    def _on_run_complete(self, fut):
        try:
            res = fut.result()
        except Exception as e:
            self._write_terminal(f"Execution error: {e}", "error")
            return
        if res.stdout:
            self._write_terminal(res.stdout)
        if res.stderr:
            self._write_terminal("[stderr]\n" + res.stderr, "error")
        self._write_terminal(f"-- exit={res.return_code}  time={res.duration_s:.2f}s", "banner")

    def _on_list_files(self):
        if not self.session_id:
            self._write_terminal("No active session. Create a session first.", "error")
            return
        fut = self.runner.run(self.core.list_files(self.session_id))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_list_files_done(f)))

    def _on_list_files_done(self, fut):
        try:
            files = fut.result()
        except Exception as e:
            self._write_terminal(f"Failed to list files: {e}", "error")
            return
        lines = ["Files:"]
        for e in files:
            lines.append(f" - {e['name']} {'(dir)' if e['is_dir'] else f'{e['size']} bytes'}")
        self._write_terminal("\n".join(lines))

    def _on_list_vars(self):
        if not self.session_id:
            self._write_terminal("No active session. Create a session first.", "error")
            return
        fut = self.runner.run(self.core._fetch_variables(self.session_id))
        # schedule the GUI-safe callback on the Tk event loop:
        fut.add_done_callback(lambda f: self.after(0, lambda f=f: self._on_list_vars_done(f)))

    def _on_list_vars_done(self, fut):
        """
        NOTE: This method is now always executed in the main thread because the
        add_done_callback above schedules it with `self.after(0, ...)`.
        """
        try:
            vars_map = fut.result()
        except Exception as e:
            # show error in the UI
            self._write_terminal(f"Failed to fetch variables: {e}", "error")
            return
        if not vars_map:
            self._write_terminal("No variables in workspace.")
            return
        lines = ["Variables in workspace:"]
        # vars_map is expected to be a dict: name -> { 'name', 'dtype', 'shape', 'preview' }
        for k, v in vars_map.items():
            # be defensive about types
            if isinstance(v, dict):
                dtype = v.get("dtype", v.get("class", "unknown"))
                shape = v.get("shape", None)
                preview = v.get("preview", v.get("value", ""))
            else:
                # older backends might return VariableInfo-like objects
                dtype = getattr(v, "dtype", "unknown")
                shape = getattr(v, "shape", None)
                preview = getattr(v, "preview", str(v))
            lines.append(f" - {k} : {dtype} shape={shape} preview={preview}")
        self._write_terminal("\n".join(lines))

    def _on_run_script_dialog(self):
        if not self.session_id:
            self._write_terminal("Create a session first.", "error")
            return
        path = filedialog.askopenfilename(title="Choose .m script to run", filetypes=[("UniLab files", "*.m"), ("All files", "*.*")])
        if not path:
            return
        # copy script into workspace and run
        fut = self.runner.run(self._copy_and_run_script(path))
        fut.add_done_callback(lambda f: self._on_run_complete(f))

    async def _copy_and_run_script(self, local_path):
        # copy file to session workspace
        import shutil
        session = self.core._get_session(self.session_id)
        dst = session.workspace_path / pathlib.Path(local_path).name
        shutil.copy(local_path, dst)
        self._write_terminal(f"Copied script to workspace: {dst}")
        return await self.core.run_script_file(self.session_id, dst, timeout=60.0)

    def _on_export_data_dialog(self):
        if not self.session_id:
            self._write_terminal("Create a session first.", "error")
            return
        
        # Simple choice between JSON and CSV
        fmt = simpledialog.askstring("Export Data", "Enter format (json or csv):", initialvalue="json")
        if not fmt or fmt.lower() not in ["json", "csv"]:
            if fmt: self._write_terminal("Invalid format. Use 'json' or 'csv'.", "error")
            return
            
        fut = self.runner.run(self.core.export_workspace(self.session_id, format=fmt.lower()))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_export_data_done(f)))

    def _on_export_data_done(self, fut):
        try:
            path = fut.result()
            self._write_terminal(f"Data exported successfully to: {path}", "success")
        except Exception as e:
            self._write_terminal(f"Data export failed: {e}", "error")

    def _on_export_plot_dialog(self):
        if not self.session_id:
            self._write_terminal("Create a session first.", "error")
            return
        # Ask user for plot commands (multi-line)
        dialog = PlotCommandDialog(self, title="Export Plot (UniLab commands)")
        self.wait_window(dialog)
        if dialog.result is None:
            return
        plot_cmds = dialog.result
        # schedule export
        fut = self.runner.run(self.core.export_plot(self.session_id, plot_cmds, fmt="png", timeout=60.0))
        fut.add_done_callback(lambda f: self.after(0, lambda: self._on_export_plot_done(f)))

    def _on_export_plot_done(self, fut):
        try:
            path = fut.result()
        except Exception as e:
            self._write_terminal(f"Plot export failed: {e}", "error")
            return
        self._write_terminal(f"Plot exported to: {path}", "success")

    # ---------------------------
    # Cleanup
    # ---------------------------
    def _on_close(self):
        if messagebox.askokcancel("Quit", "Shut down UniLab client and backend?"):
            # stop core and runner
            try:
                if self.session_id:
                    self.runner.run(self.core.stop_session(self.session_id)).result(timeout=5)
            except Exception:
                pass
            try:
                self.runner.run(self.core.stop()).result(timeout=5)
            except Exception:
                pass
            # stop loop/thread
            self.runner.stop()
            self.destroy()


class PlotCommandDialog(tk.Toplevel):
    def __init__(self, parent, title="Plot commands"):
        super().__init__(parent)
        self.title(title)
        self.geometry("600x300")
        self.configure(bg="#1e1e1e")
        tk.Label(self, text="Enter UniLab plotting commands (example: x=0:0.1:2*pi; y=sin(x); plot(x,y);)", bg="#1e1e1e", fg="#d4d4d4").pack(padx=8, pady=8)
        self.text = tk.Text(self, height=10, width=80, bg="#252526", fg="#d4d4d4", font=("Consolas", 11))
        self.text.pack(padx=8, pady=(0,8))
        btn_frame = tk.Frame(self, bg="#1e1e1e")
        btn_frame.pack(fill=tk.X, padx=8, pady=8)
        tk.Button(btn_frame, text="Cancel", command=self._on_cancel, bg="#333", fg="#fff").pack(side=tk.RIGHT, padx=4)
        tk.Button(btn_frame, text="OK", command=self._on_ok, bg="#0e639c", fg="#fff").pack(side=tk.RIGHT, padx=4)
        self.result = None

    def _on_ok(self):
        self.result = self.text.get("1.0", tk.END).strip()
        self.destroy()

    def _on_cancel(self):
        self.result = None
        self.destroy()


if __name__ == "__main__":
    app = UniLabCLIApp()
    app.mainloop()
