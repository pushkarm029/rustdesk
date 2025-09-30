# Complete RustDesk Connection Indicator Analysis for Fork

## **Key Connection Indicator Components Found**

### 1. **System Tray Icon** - `src/tray.rs` 🎯
- **Main Function**: `make_tray()` (lines 30-209)  
- **Shows**: Connection count tooltip in bottom-right system tray
- **Tooltip Format**: `"{App Name} - Ready\n{count} sessions"`
- **Updates**: Real-time based on active connections
- **Platform**: Windows, Linux, macOS

### 2. **Windows Toast Notifications** - `src/core_main.rs` 
- **Functions**: Lines 204-210, 238-244
- **Uses**: `tauri_winrt_notification::Toast::new()`
- **Shows**: Installation/update status messages
- **Platform**: Windows only

### 3. **Connection Flow Chain** 🔗
```
Connection Established -> try_start_cm() -> IPC Data::Login -> ConnectionManager -> UI Update
```

**Key Files:**
- **`src/server/connection.rs`**: 
  - `try_start_cm()` (lines 1749-1769) - Triggers connection manager
  - `AuthedConnID::new()` (lines 4738-4768) - Tracks authorized connections
  - Connection event: Line 1309 "A new connection has been established to your device"

- **`src/ipc.rs`**:
  - `Data::Login` enum (lines 190-208) - Connection info structure
  - Carries: peer_id, name, authorized status, permissions

- **`src/ui_cm_interface.rs`**:
  - `add_connection()` (lines 129-178) - Processes new connections 
  - Line 649: "Got new connection" debug log
  - Manages connection UI updates

### 4. **Platform-Specific Notifications**
- **Windows**: `src/platform/windows.rs`
  - `message_box()` (lines 2941-2976) - Windows MessageBoxW dialogs
- **Privacy Mode**: `src/privacy_mode/win_topmost_window.rs`
  - Topmost window handling for privacy mode

### 5. **Flutter UI Components**
- **Chat Overlay**: `flutter/lib/common/widgets/overlay.dart`
- **Connection Widgets**: Various Flutter UI components in `flutter/lib/desktop/`

## **For Your Fork - Critical Modification Points** 🛠️

### **Primary Target**: System Tray Icon
- **File**: `src/tray.rs`
- **Function**: `make_tray()` 
- **Action**: Remove/modify tooltip updates or disable tray entirely

### **Secondary Targets**: Connection Events  
1. **Server Connection Handler**: `src/server/connection.rs`
   - `try_start_cm()` - Disable connection manager notifications
   - Remove "A new connection has been established" message (line 1309)

2. **Connection Manager**: `src/ui_cm_interface.rs` 
   - `add_connection()` - Remove UI notifications
   - Line 649 debug log shows connection detection point

### **Platform-Specific**:
- **Windows**: Modify `message_box()` in `src/platform/windows.rs`
- **Toast Notifications**: `src/core_main.rs` (if using Toast notifications)

## **Connection Detection Flow** 📊
1. **Client connects** → `src/server/connection.rs`
2. **Authentication** → `send_logon_response()` → `try_start_cm()`  
3. **IPC Message** → `Data::Login` → `src/ipc.rs`
4. **UI Update** → `ConnectionManager::add_connection()` → `src/ui_cm_interface.rs`
5. **Tray Update** → Tooltip shows session count → `src/tray.rs`

## **Architecture Notes**
- **Modern Stack**: Rust backend + Flutter UI
- **IPC Communication**: Server ↔ UI communication via `src/ipc.rs`
- **Cross-Platform**: Windows/Linux/macOS support
- **Multi-Session**: Tracks multiple concurrent connections

## **Recommended Fork Strategy** 🎯
1. **Disable System Tray**: Modify `src/tray.rs` → `make_tray()` 
2. **Remove Connection Notifications**: Disable `try_start_cm()` calls
3. **Silent Connection Handling**: Keep connection logic but remove UI indicators
4. **Platform Testing**: Focus on Windows/Linux as user specified

This gives you complete control over removing the "you are connected to this" indicators while maintaining core functionality.