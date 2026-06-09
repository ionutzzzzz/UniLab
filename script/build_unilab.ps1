# build_unilab.ps1 - Windows Build & Packaging Script for UniLab
# Enhanced for standalone distribution (no-dependencies required)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "[INFO] Building UniLab for Windows (Standalone)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 1. Build Rust Core (DLL and CLI)
Write-Host "[STEP 1] Building Rust Core components..." -ForegroundColor Yellow
Set-Location backend
cargo build --release -p unilab_core
cargo build --release -p unilab_cli
Set-Location ..

# 2. Sync Bridge to Flutter (Required for Windows build)
Write-Host "[STEP 2] Syncing Rust Bridge to Flutter..." -ForegroundColor Yellow
If (!(Test-Path frontend/windows)) { New-Item -ItemType Directory -Path frontend/windows }
Copy-Item "backend/target/release/unilab_core.dll" "frontend/windows/"

# 3. Build Flutter GUI
Write-Host "[STEP 3] Building Flutter GUI for Windows..." -ForegroundColor Yellow
Set-Location frontend
$FLUTTER_CMD = "flutter"
$USER_FLUTTER_PATH = "C:\Users\John\flutter\bin\flutter.bat"

if (Test-Path $USER_FLUTTER_PATH) {
    $FLUTTER_CMD = $USER_FLUTTER_PATH
} elseif (!(Get-Command $FLUTTER_CMD -ErrorAction SilentlyContinue)) {
    $commonPath = "$HOME/flutter/bin/flutter.bat"
    if (Test-Path $commonPath) { $FLUTTER_CMD = $commonPath } 
    else { Write-Host "Error: 'flutter' command not found." -ForegroundColor Red; Exit 1 }
}
& $FLUTTER_CMD build windows --release
Set-Location ..

# 4. Prepare Release Directory
$RELEASE_DIR = "release-windows"
Write-Host "[STEP 4] Packaging into $RELEASE_DIR..." -ForegroundColor Yellow

If (Test-Path $RELEASE_DIR) { Remove-Item -Recurse -Force $RELEASE_DIR }
New-Item -ItemType Directory -Path "$RELEASE_DIR/Unilab"

# --- PACKAGE: Unilab (GUI Bundle) ---
Write-Host "  - Packaging Unilab (GUI)..."
$FLUTTER_BUNDLE = "frontend/build/windows/x64/runner/Release/"
If (!(Test-Path $FLUTTER_BUNDLE)) { $FLUTTER_BUNDLE = "frontend/build/windows/x64/release/bundle/" }

If (Test-Path $FLUTTER_BUNDLE) {
    Copy-Item -Recurse "$FLUTTER_BUNDLE*" "$RELEASE_DIR/Unilab/"
    If (Test-Path "$RELEASE_DIR/Unilab/unilab.exe") { Rename-Item "$RELEASE_DIR/Unilab/unilab.exe" "UniLab.exe" }
} Else {
    Write-Host "Error: Flutter build output not found!" -ForegroundColor Red; Exit 1
}

# --- PACKAGE: Backend & Samples (Crucial for Bridge) ---
Write-Host "  - Bundling Backend logic and Samples..."
# Copy backend excluding target/release and pycache
New-Item -ItemType Directory -Path "$RELEASE_DIR/Unilab/backend" | Out-Null
Copy-Item -Recurse "backend/*" "$RELEASE_DIR/Unilab/backend/" -Exclude "target","__pycache__",".git"
# Copy samples
Copy-Item -Recurse "sample" "$RELEASE_DIR/Unilab/"

# --- PACKAGE: Python Environment ---
Write-Host "[STEP 5] Preparing Embedded Python..." -ForegroundColor Yellow
$PYTHON_DIR = "temp_python"
$PYTHON_ZIP = "python-3.13.1-embed-amd64.zip"
$PYTHON_URL = "https://www.python.org/ftp/python/3.13.1/$PYTHON_ZIP"

If (!(Test-Path $PYTHON_DIR)) {
    Write-Host "  - Downloading Python 3.13 Embeddable..."
    New-Item -ItemType Directory -Path $PYTHON_DIR | Out-Null
    Invoke-WebRequest -Uri $PYTHON_URL -OutFile "$PYTHON_DIR/$PYTHON_ZIP"
    Expand-Archive -Path "$PYTHON_DIR/$PYTHON_ZIP" -DestinationPath $PYTHON_DIR -Force
    Remove-Item "$PYTHON_DIR/$PYTHON_ZIP"
}

# Setup pip in embedded python
If (!(Test-Path "$PYTHON_DIR/Scripts/pip.exe")) {
    Write-Host "  - Installing pip for embedded python..."
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$PYTHON_DIR/get-pip.py"
    # Enable site-packages in .pth
    $pthFile = Get-ChildItem -Path $PYTHON_DIR -Filter "python3*._pth" | Select-Object -First 1
    $pthPath = $pthFile.FullName
    $content = Get-Content $pthPath
    $content = $content -replace "#import site", "import site"
    if ($content -notcontains "./Lib/site-packages") {
        $content = $content + "`r`n./Lib/site-packages"
    }
    $content | Set-Content $pthPath
    & "$PYTHON_DIR/python.exe" "$PYTHON_DIR/get-pip.py"
    Remove-Item "$PYTHON_DIR/get-pip.py"
}

# Install requirements
Write-Host "  - Installing requirements..."
& "$PYTHON_DIR/python.exe" -m pip install -r backend/requirements.txt --target "$PYTHON_DIR/Lib/site-packages" --upgrade

# Copy Python to Release
Write-Host "  - Copying Python environment to release bundle..."
Copy-Item -Recurse "$PYTHON_DIR/*" "$RELEASE_DIR/Unilab/"

# 6. Create ZIP archive
Write-Host "[STEP 6] Creating ZIP archive..." -ForegroundColor Yellow
Compress-Archive -Path "$RELEASE_DIR/Unilab" -DestinationPath "UniLab-Windows-Standalone.zip" -Update

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "DONE! Standalone release is ready." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Location: $RELEASE_DIR/Unilab/"
Write-Host "Executable: $RELEASE_DIR/Unilab/UniLab.exe"
