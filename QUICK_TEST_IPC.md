# Quick Test Guide: CM IPC Feature

## 🚀 Fast Build & Test (5 minutes)

### Step 1: Build RustDesk

```bash
cd /home/pushkarm/rustdesk

# Clean build (if needed)
# cargo clean

# Build Flutter version
python3 build.py --flutter

# Should complete in 2-5 minutes depending on system
```

### Step 2: Start CM Window

```bash
# Start Connection Manager with IPC enabled
./target/debug/rustdesk --cm
```

**Expected logs:**
```
[CM-IPC] Starting IPC service for CM window control
[CM-IPC] Unix socket listening at: /tmp/rustdesk_cm.sock
[CM-IPC] ✓ IPC service started - Unix socket: /tmp/rustdesk_cm.sock
[CM-IPC] ✓ Activator can connect via: /tmp/rustdesk_cm.sock
```

### Step 3: Test with `nc` (netcat)

**Open a new terminal:**

```bash
# Hide the window
echo "hide" | nc -U /tmp/rustdesk_cm.sock
# Response: hidden

# Show the window
echo "show" | nc -U /tmp/rustdesk_cm.sock
# Response: shown

# Toggle the window
echo "toggle" | nc -U /tmp/rustdesk_cm.sock
# Response: shown or hidden (depending on current state)
```

### Step 4: Test with Your Activator Binary

```bash
# If you have the activator built
./rustdesk-activator

# Window should toggle visibility
# Activator should print: "✓ Window is now visible" or "✓ Window is now hidden"
```

## 🐛 Troubleshooting

### Socket doesn't exist

```bash
# Check if CM is running
ps aux | grep "rustdesk --cm"

# Check socket
ls -la /tmp/rustdesk_cm.sock

# If missing, check CM logs for errors
```

### Permission denied

```bash
# Set custom socket path in your home directory
export RUSTDESK_CM_SOCKET_PATH=$HOME/.rustdesk_cm.sock
./target/debug/rustdesk --cm

# Then test with
echo "toggle" | nc -U $HOME/.rustdesk_cm.sock
```

### Socket already in use

```bash
# Remove stale socket
rm /tmp/rustdesk_cm.sock

# Restart CM
./target/debug/rustdesk --cm
```

## ✅ Success Criteria

- [x] CM window starts hidden
- [x] IPC service logs show successful startup
- [x] Socket file exists at `/tmp/rustdesk_cm.sock`
- [x] `nc` command gets response ("shown", "hidden", etc.)
- [x] Window actually toggles visibility on command
- [x] Activator binary can control window

## 📊 Performance Check

IPC should respond in **< 100ms**:

```bash
# Time the toggle command
time echo "toggle" | nc -U /tmp/rustdesk_cm.sock

# Should be around 0.01-0.05 seconds
```

## 🔧 Custom Configuration

### Use different socket path

```bash
export RUSTDESK_CM_SOCKET_PATH=/tmp/my_custom.sock
./target/debug/rustdesk --cm

# Test
echo "toggle" | nc -U /tmp/my_custom.sock
```

### Windows Testing (TCP)

```powershell
# Start CM
.\target\debug\rustdesk.exe --cm

# Should see:
# [CM-IPC] ✓ TCP server listening on 127.0.0.1:21118

# Test with PowerShell
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect("127.0.0.1", 21118)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.WriteLine("toggle")
$writer.Flush()
$response = $reader.ReadLine()
Write-Host "Response: $response"
$client.Close()
```

## 🎯 Next Steps

After verifying IPC works:

1. **Configure activator hotkey** - Set global hotkey in activator binary
2. **Test on Windows** - Build and test TCP-based IPC
3. **System tray integration** - Add "Toggle CM" menu item
4. **Package activator** - Include activator in RustDesk distribution

## 📝 Notes

- IPC service starts automatically when running `--cm`
- No configuration files needed (uses environment variables)
- Works alongside existing hotkey_manager implementation
- Safe to run multiple instances (auto-increments port on Windows)
- Activator binary is platform-agnostic (just sends IPC commands)
