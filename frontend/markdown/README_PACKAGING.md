# UniLab Desktop Packaging

This project supports one-click installers for Windows, Linux, and macOS.

## Prerequisites

- Flutter SDK
- Rust (Cargo)
- Python 3.10+ (System Python)
- `flutter_distributor` (installed automatically by the build script)

## Building the App

To build the installers for your current platform, run the following script from the project root:

```bash
./script/build_unilab_desktop.sh
```

The installers will be generated in `frontend/dist/`.

### Supported Targets

- **Windows**: `.exe` (NSIS), `.msix`
- **Linux**: `.AppImage`, `.deb`
- **macOS**: `.dmg`, `.pkg`

## How it works

1.  **Rust Core**: The backend's Rust core is compiled into a dynamic library (`.so`, `.dll`, or `.dylib`).
2.  **Bundling**: This library is copied into the Flutter project's native build directory and bundled with the executable.
3.  **Backend Logic**: The Python-based backend logic is bundled as Flutter assets and located at runtime by the FFI bridge.
4.  **FFI Bridge**: The Flutter app communicates with the Rust core via FFI, which in turn manages an embedded Python interpreter to run the simulation and transpilation logic.

## Troubleshooting

### Python dependencies
Ensure that you have the required Python packages installed on your system if you are running in a development environment. For the packaged app, we are currently relying on the system Python. Future versions will bundle a portable Python distribution.

### Missing library error
If the app fails to start with a "Could not load library" error, ensure that the Rust core was built successfully and that the library file exists in the expected location (e.g., `frontend/linux/libunilab_core.so`).
