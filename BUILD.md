# RustDesk Windows Build Guide

## Build Errors Encountered
- vcpkg packages not pre-installed (required manual installation of aom, libjpeg-turbo, libvpx, libyuv, mfx-dispatch, opus)
- FileExistsError when renaming installer (delete existing `rustdesk-{version}-install.exe` before rebuilding)

## Prerequisites

1. **Required Software**
   - Python 3.13+
   - Flutter 3.35+
   - Rust/Cargo 1.75+
   - Visual Studio 2022 with C++ tools
   - LLVM 18+ (for hardware codec support)
   - Git

2. **System Requirements**
   - **IMPORTANT:** Ensure system date/time is correct (vcpkg SSL certificate validation will fail otherwise)
   - At least 20GB free disk space
   - 8GB+ RAM recommended

3. **Environment Setup**
   ```powershell
   # Set vcpkg root (required)
   $env:VCPKG_ROOT = "C:\Users\root\Downloads\rustdesk\vcpkg"

   # Set LLVM path (required for hwcodec feature)
   $env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"

   # Optional: Add to PATH permanently
   [System.Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:\Users\root\Downloads\rustdesk\vcpkg', 'User')
   [System.Environment]::SetEnvironmentVariable('LIBCLANG_PATH', 'C:\Program Files\LLVM\bin', 'User')
   ```
cargo install cargo-expand --version 1.0.95 --locked
>> cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid" --locked
>> flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
>> cp ./flutter/macos/Runner/bridge_generated.h ./flutter/ios/Runner/bridge_generated.h
## Build Steps

### 1. Clone Repository
```bash
git clone https://github.com/rustdesk/rustdesk.git
cd rustdesk
```

### 2. Initialize vcpkg (if not present)
```bash
git submodule update --init --recursive
cd vcpkg
.\bootstrap-vcpkg.bat
cd ..
```

### 3. Install vcpkg Dependencies
```bash
.\vcpkg\vcpkg.exe install --x-install-root=".\vcpkg\installed"
```
**Note:**
- This takes 30-60 minutes, builds: aom, libjpeg-turbo, libvpx, libyuv, mfx-dispatch, opus
- **CRITICAL:** Verify system date/time is correct before running (vcpkg requires accurate time for SSL)
- Ensure stable internet connection (downloads source packages)

### 4. Install Flutter Dependencies
```bash
cd flutter
flutter pub get
cd ..
```

### 5. Build RustDesk
```bash
python build.py --flutter
```

This will:
- Build virtual display driver (libs/virtual_display/dylib)
- Build Rust library with Flutter features
- Build Flutter Windows app
- Copy required DLLs
- Create portable installer

### 6. Output Location
- Installer: `rustdesk-{version}-install.exe`
- Flutter build: `flutter\build\windows\x64\runner\Release\`

## Build Options

```bash
# Release build with hardware codec
python build.py --flutter --hwcodec

# With VRAM optimization
python build.py --flutter --vram

# Skip portable pack creation
python build.py --flutter --skip-portable-pack
```

## Troubleshooting

### vcpkg build fails
- **SSL/Certificate errors**: Check system date/time is correct
- Ensure Visual Studio C++ tools installed
- Check VCPKG_ROOT environment variable set
- Delete vcpkg\buildtrees and retry
- Verify internet connection (downloads sources from GitHub/Google)

### Flutter build fails
- Run `flutter doctor` to check setup
- Ensure `flutter pub get` completed successfully
- Check Windows SDK installed (via Visual Studio)

### Cargo build fails (hwcodec)
- Verify LLVM installed and LIBCLANG_PATH set
- Install LLVM from: https://releases.llvm.org/download.html
- Update Rust: `rustup update`
- Clean build: `cargo clean`
- Check all git submodules initialized

### Environment Variables not persisting
```powershell
# Set permanently (requires new terminal after):
[System.Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:\Users\root\Downloads\rustdesk\vcpkg', 'User')
[System.Environment]::SetEnvironmentVariable('LIBCLANG_PATH', 'C:\Program Files\LLVM\bin', 'User')
```

### FileExistsError during installer rename
```bash
# Delete old installer before rebuilding:
rm rustdesk-1.4.2-install.exe

# Or use --skip-portable-pack to skip installer creation:
python build.py --flutter --skip-portable-pack
```

## Clean Build
```bash
cargo clean
rm -rf flutter\build
rm -rf vcpkg\buildtrees
rm -rf vcpkg\packages
```

## Build Time Estimates
- vcpkg dependencies: 30-60 minutes (first time only)
- Rust compilation: 10-20 minutes
- Flutter build: 5-10 minutes
- **Total first build: ~45-90 minutes**
- **Subsequent builds: ~15-30 minutes**
