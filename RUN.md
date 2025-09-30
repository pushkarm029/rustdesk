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

## Run

```bash
cargo run
```

Or for release build:

```bash
cargo build --release
./target/release/rustdesk
```