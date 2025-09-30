# Run RustDesk

## Install Dependencies

```bash
sudo apt install -y zip g++ gcc git curl wget nasm yasm libgtk-3-dev clang libxcb-randr0-dev libxdo-dev \
        libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev libasound2-dev libpulse-dev cmake make \
        libclang-dev ninja-build libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpam0g-dev
```

## Download Sciter Library

```bash
mkdir -p target/debug
wget https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so -O target/debug/libsciter-gtk.so
```

## Set VCPKG_ROOT

```bash
export VCPKG_ROOT=/home/pushkarm/rustdesk/vcpkg
```

## Run (Sciter UI - Legacy)

```bash
cargo run
```

Or for release build:

```bash
cargo build --release
./target/release/rustdesk
```

## Build Flutter Version

### Install Flutter 3.24.5

RustDesk requires Flutter 3.24.5 specifically. Newer versions (3.35+) have breaking API changes.

```bash
# Remove existing Flutter if needed
rm -rf ~/flutter

# Download Flutter 3.24.5
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar -xf flutter_linux_3.24.5-stable.tar.xz
rm flutter_linux_3.24.5-stable.tar.xz

# Add to PATH
export PATH="$HOME/flutter/bin:$PATH"

# Verify version
flutter --version  # Should show 3.24.5
```

### Install Flutter Rust Bridge Codegen

```bash
cargo install flutter_rust_bridge_codegen --version 1.80.1
```

### Install Flutter Dependencies

```bash
cd /home/pushkarm/rustdesk/flutter
flutter pub get
```

### Generate Bridge Code

```bash
cd /home/pushkarm/rustdesk
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart
```

### Build Flutter Version

```bash
export VCPKG_ROOT=/home/pushkarm/rustdesk/vcpkg
export PATH="$HOME/flutter/bin:$PATH"
python3 build.py --flutter
```

### Run Flutter Version

**Run Connection Manager (Modified Version):**

```bash
./flutter/build/linux/x64/release/bundle/rustdesk --cm
```

This launches the connection manager window which will:
- Start hidden (invisible but focused at opacity 0)
- Stay hidden when clients connect
- Show/hide when you press **Ctrl+Shift+Alt+M** (works from anywhere)

**Run Full RustDesk Server (includes tray + CM):**

```bash
./flutter/build/linux/x64/release/bundle/rustdesk --server
```

This starts the complete RustDesk server daemon which spawns the connection manager automatically.