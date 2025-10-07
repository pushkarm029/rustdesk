# Connection Manager IPC Integration

## Overview

The Connection Manager (CM) window now supports **Inter-Process Communication (IPC)** for external visibility control. This allows a separate activator binary to toggle the CM window from anywhere in the system, providing true global hotkey functionality across all platforms.

## Architecture

```
┌─────────────────────┐
│  Activator Binary   │ (Rust binary - sends commands)
│  (rustdesk-toggle)  │
└──────────┬──────────┘
           │
           │ IPC Protocol
           │ Commands: toggle/show/hide
           │ Responses: shown/hidden/error
           ▼
┌─────────────────────┐
│  CM Window          │ (Flutter --cm process)
│  IPC Listener       │
│  - Unix Socket      │ Linux/macOS: /tmp/rustdesk_cm.sock
│  - TCP Localhost    │ Windows: 127.0.0.1:21118
└─────────────────────┘
```

## Features Implemented

✅ **Cross-platform IPC:**
- Linux/macOS: Unix domain socket (`/tmp/rustdesk_cm.sock`)
- Windows: TCP localhost (`127.0.0.1:21118`)

✅ **Robust error handling:**
- Stale socket cleanup
- Port conflict resolution (tries ports 21118-21128)
- Permission fallback (user home directory)
- Client timeout (5 seconds)

✅ **Configuration:**
- Environment variable `RUSTDESK_CM_SOCKET_PATH` - custom Unix socket path
- Environment variable `RUSTDESK_CM_IPC_PORT` - custom TCP port
- Automatic fallback to `~/.rustdesk_cm.sock` if `/tmp` permission denied

✅ **Protocol:**
- Commands: `toggle`, `show`, `hide`
- Responses: `shown`, `hidden`, `unknown command`, `error`
- Format: newline-terminated strings

## Files Created/Modified

### New Files

**`flutter/lib/common/cm_ipc_service.dart`**
- Complete IPC service implementation
- Platform detection and socket management
- Client connection handling
- Error recovery and logging

### Modified Files

**`flutter/lib/main.dart`**
- Added import: `import 'package:flutter_hbb/common/cm_ipc_service.dart';`
- Added global `_cmIpcService` variable (line 377)
- Added `_handleCmIpcCommand()` function (line 380-409)
- Added IPC service startup in `runConnectionManagerScreen()` (line 367-383)

## Building RustDesk with IPC Support

The IPC feature is now integrated into the main codebase. No special build flags required.

### Standard Build Process:

```bash
cd /home/pushkarm/rustdesk

# Build Flutter desktop version
python3 build.py --flutter

# Or build with release optimization
python3 build.py --flutter --release
```

### Run CM Window:

```bash
# Start CM window (will start IPC listener automatically)
./target/debug/rustdesk --cm

# Or from Flutter directory
cd flutter
flutter run --cm
```

## Testing the IPC Implementation

### Method 1: Manual Testing with `nc` (netcat)

**Linux/macOS:**

```bash
# Terminal 1: Start RustDesk CM
./target/debug/rustdesk --cm

# Terminal 2: Watch the logs
# (CM should print: "[CM-IPC] ✓ Unix socket listening at: /tmp/rustdesk_cm.sock")

# Terminal 3: Send toggle command
echo "toggle" | nc -U /tmp/rustdesk_cm.sock

# Expected response: "shown\n" or "hidden\n"
# Window should toggle visibility
```

**Windows (PowerShell):**

```powershell
# Terminal 1: Start RustDesk CM
.\target\debug\rustdesk.exe --cm

# Terminal 2: Send toggle command using Test-NetConnection
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect("127.0.0.1", 21118)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.WriteLine("toggle")
$writer.Flush()
$reader = New-Object System.IO.StreamReader($stream)
$response = $reader.ReadLine()
Write-Host "Response: $response"
$client.Close()
```

### Method 2: Testing with Activator Binary

**If you have the activator binary built:**

```bash
# Terminal 1: Start RustDesk CM
./target/debug/rustdesk --cm

# Terminal 2: Run activator
./rustdesk-activator

# Expected output:
# ✓ Window is now visible
# or
# ✓ Window is now hidden
```

### Method 3: Python Test Script

Create `test_ipc.py`:

```python
#!/usr/bin/env python3
import socket
import sys
import os

def test_unix_socket():
    """Test Unix socket IPC (Linux/macOS)"""
    socket_path = '/tmp/rustdesk_cm.sock'

    if not os.path.exists(socket_path):
        print(f"✗ Socket not found: {socket_path}")
        print("  Make sure CM window is running: ./rustdesk --cm")
        return False

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(5)
        client.connect(socket_path)

        # Send toggle command
        client.sendall(b'toggle\n')

        # Receive response
        response = client.recv(1024).decode().strip()
        print(f"✓ Response: {response}")

        client.close()
        return True

    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_tcp_socket():
    """Test TCP socket IPC (Windows)"""
    try:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.settimeout(5)
        client.connect(('127.0.0.1', 21118))

        # Send toggle command
        client.sendall(b'toggle\n')

        # Receive response
        response = client.recv(1024).decode().strip()
        print(f"✓ Response: {response}")

        client.close()
        return True

    except Exception as e:
        print(f"✗ Error: {e}")
        return False

if __name__ == '__main__':
    if sys.platform in ['linux', 'darwin']:
        print("Testing Unix socket...")
        test_unix_socket()
    elif sys.platform == 'win32':
        print("Testing TCP socket...")
        test_tcp_socket()
    else:
        print(f"Unsupported platform: {sys.platform}")
```

**Run test:**

```bash
chmod +x test_ipc.py
./test_ipc.py
```

## Expected Logs

When CM window starts with IPC enabled, you should see:

```
[HOTKEY] runConnectionManagerScreen: Starting initialization
[HOTKEY] Hiding CM window on startup
[HOTKEY] CM window hidden, window is ready
[CM-IPC] Starting IPC service for CM window control
[CM-IPC] Unix socket listening at: /tmp/rustdesk_cm.sock
[CM-IPC] ✓ IPC service started - Unix socket: /tmp/rustdesk_cm.sock
[CM-IPC] ✓ Activator can connect via: /tmp/rustdesk_cm.sock
```

When activator sends a command:

```
[CM-IPC] Client connected from 127.0.0.1:xxxxx
[CM-IPC] Received command: "toggle"
[CM-IPC] Processing command: 'toggle'
[HOTKEY] showCmWindow called: isStartup=false, _isCmWindowVisible=false
[HOTKEY] showCmWindow: Window shown, _isCmWindowVisible=true, hideCm=false
[CM-IPC] Window toggled to shown
[CM-IPC] Command result: "shown"
[CM-IPC] Sent response: "shown"
[CM-IPC] Client connection closed
```

## Configuration

### Environment Variables

**`RUSTDESK_CM_SOCKET_PATH`** (Linux/macOS only)
- Custom Unix socket path
- Default: `/tmp/rustdesk_cm.sock`
- Example: `export RUSTDESK_CM_SOCKET_PATH=/home/user/.rustdesk/cm.sock`

**`RUSTDESK_CM_IPC_PORT`** (Windows only)
- Custom TCP port
- Default: `21118`
- Example: `set RUSTDESK_CM_IPC_PORT=9999`

### Setting Custom Configuration

**Linux/macOS:**

```bash
# Set custom socket path
export RUSTDESK_CM_SOCKET_PATH=/home/user/.rustdesk_cm.sock

# Run CM
./rustdesk --cm
```

**Windows:**

```cmd
# Set custom port
set RUSTDESK_CM_IPC_PORT=9999

# Run CM
rustdesk.exe --cm
```

## Troubleshooting

### Issue: "Socket already exists" or "Address already in use"

**Cause:** Previous CM instance didn't clean up properly

**Solution (Linux/macOS):**
```bash
rm /tmp/rustdesk_cm.sock
./rustdesk --cm
```

**Solution (Windows):**
```bash
# Service will auto-try ports 21118-21128
# Or set custom port:
set RUSTDESK_CM_IPC_PORT=21119
rustdesk.exe --cm
```

### Issue: "Permission denied" on `/tmp/rustdesk_cm.sock`

**Cause:** No write permission to `/tmp`

**Solution:** Service automatically falls back to `~/.rustdesk_cm.sock`

Or set custom path:
```bash
export RUSTDESK_CM_SOCKET_PATH=$HOME/.rustdesk_cm.sock
./rustdesk --cm
```

### Issue: Activator times out or "Connection refused"

**Cause:** CM window not running or IPC service failed to start

**Check:**
1. Verify CM is running: `ps aux | grep "rustdesk --cm"`
2. Check logs for IPC startup errors
3. Verify socket exists: `ls -la /tmp/rustdesk_cm.sock` (Linux/macOS)
4. Verify port is listening: `netstat -an | grep 21118` (Windows)

### Issue: Response is always "unknown command"

**Cause:** Command not recognized or malformed

**Check:**
- Ensure command is lowercase: `toggle`, `show`, or `hide`
- Ensure newline termination: `echo "toggle\n"`
- Check for extra whitespace

### Issue: IPC works but window doesn't toggle

**Cause:** Window manager state issue

**Check:**
- Look for errors in CM logs related to windowManager
- Verify `_isCmWindowVisible` state is accurate
- Check if window is in a zombie state

## Protocol Specification

### Request Format

```
<command>\n
```

Where `<command>` is one of:
- `toggle` - Toggle window visibility based on current state
- `show` - Always show window (bring to front and focus)
- `hide` - Always hide window

### Response Format

```
<status>\n
```

Where `<status>` is one of:
- `shown` - Window is now visible
- `hidden` - Window is now hidden
- `unknown command` - Invalid command received
- `error` - Error processing command
- `timeout` - Client read timeout

### Connection Flow

1. Client connects to socket/port
2. Client sends command with `\n` terminator
3. Server receives command
4. Server processes command (toggle/show/hide window)
5. Server sends response with `\n` terminator
6. Server closes connection
7. Client reads response and closes socket

### Example Session

```
Client → Server: "toggle\n"
Server → Client: "shown\n"
Connection closed
```

## Integration with Activator Binary

Your activator binary should be configured to connect to:

**Linux/macOS:**
- Socket path: `/tmp/rustdesk_cm.sock`
- Or read from `RUSTDESK_CM_SOCKET_PATH` environment variable

**Windows:**
- TCP address: `127.0.0.1:21118`
- Or read from `RUSTDESK_CM_IPC_PORT` environment variable

The activator can be triggered by:
- Global system hotkey (implemented in activator)
- System tray menu item
- CLI command
- External script

## Security Considerations

1. **Localhost only (Windows):** TCP server binds to `127.0.0.1` (loopback), not accessible from network
2. **Unix socket permissions:** Set to `600` (user read/write only)
3. **No authentication:** IPC assumes local processes are trusted
4. **Timeout protection:** Clients timeout after 5 seconds to prevent resource exhaustion

## Next Steps

1. ✅ Test IPC on Linux with Unix socket
2. ✅ Test IPC on Windows with TCP
3. ✅ Test with activator binary
4. 🔲 Configure activator binary hotkey
5. 🔲 Add system tray integration
6. 🔲 Package activator with RustDesk distribution

## Support

If you encounter issues:

1. Check CM window logs for `[CM-IPC]` messages
2. Verify socket/port is accessible
3. Test with manual `nc` or `telnet` commands
4. Check environment variable configuration
5. Ensure no firewall blocking (Windows)
