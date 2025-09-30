# RustDesk Connection Indicator Code Findings

## Project Architecture Summary
- **Main UI**: Flutter-based UI in `flutter/` directory (modern approach)
- **Legacy UI**: Sciter-based UI in `src/ui/` (deprecated)
- **Platform code**: `src/platform/` contains Windows, Linux, macOS specific implementations
- **Server code**: `src/server/connection.rs` handles connection management
- **Tray functionality**: `src/tray.rs` handles system tray icon

## Key Files for Connection Indicator

### System Tray Icon (`src/tray.rs`)
- Contains `make_tray()` function that creates system tray icon
- Shows tooltip with connection count: "RustDesk - Ready" + session count
- Displays in system tray (bottom-right on Windows)
- Updates tooltip based on active session count

### Windows Platform Code (`src/platform/windows.rs`)
- Contains `message_box()` function for showing popup dialogs
- Windows-specific UI implementations
- No direct notification balloon/popup code found in initial search

### Connection Management (`src/server/connection.rs`) 
- `Connection` struct handles individual client connections
- Tracks connection state, authorization, session data
- Has fields like `authorized`, `from_switch`, `closed` for connection status

### Flutter UI (`flutter/lib/`)
- Modern UI implementation
- Contains desktop and mobile specific UI code
- Various popup/dialog widgets in `desktop/widgets/`

## Connection Indicator Locations

1. **System Tray Icon**: Shows in bottom-right notification area
2. **Main Application**: Connection status likely shown in main Flutter UI
3. **Popup/Overlay**: Potentially shown when connection established

## Next Steps for Fork Planning
- System tray icon code is in `src/tray.rs` - can be modified/disabled
- Connection status display likely in Flutter UI components
- Windows-specific behavior in `src/platform/windows.rs`