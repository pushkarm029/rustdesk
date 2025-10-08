# Flutter App Activator

A lightweight Rust utility to send activation signals to a Flutter application via Unix sockets (Linux/macOS) or named pipes (Windows).

## Features

- 🚀 Cross-platform: Unix sockets on Linux/macOS, Named Pipes on Windows
- 🔒 Safe error handling with proper timeout configuration
- 📦 Minimal binary size with optimized release builds
- 🔄 Automatic retry logic for Windows named pipes

## Building

```bash
# Development build
cargo build

# Optimized release build
cargo build --release

# The binary will be at: target/release/activator
```

## Usage

```bash
./activator
```

The activator will:
1. Connect to the Flutter app's IPC channel
2. Send a "show" command
3. Wait for acknowledgment
4. Display the response

## Configuration

### Unix (Linux/macOS)
- Socket path: `/tmp/flutter_app.sock`
- Timeout: 5 seconds

### Windows
- Pipe name: `\\.\pipe\flutter_app_pipe`
- Max retries: 5
- Retry delay: 100ms

## Build Optimizations

The release build includes:
- Size optimization (`opt-level = "z"`)
- Link-time optimization (LTO)
- Symbol stripping
- Panic abort for smaller binary
