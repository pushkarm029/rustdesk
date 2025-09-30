# RustDesk Post-Connection Popup - Complete Code Locations

## 🎯 **Main UI File - Connection Manager Window**

### **`flutter/lib/desktop/pages/server_page.dart`**
This is the PRIMARY file containing the post-connection popup UI (the screenshot you showed).

**Key Components:**

#### **1. Connection Status Display** (lines 537-554)
```dart
// Shows "Connected" or "Disconnected" text
client.authorized
    ? client.disconnected
        ? translate("Disconnected")
        : translate("Connected")
```

#### **2. Connection Timer** (lines 546-551)
```dart
// Displays connection duration "00:00:5"
Text(
    formatDurationToTime(Duration(seconds: _time.value)),
    style: TextStyle(color: Colors.white),
)
```

#### **3. Permissions Section** (lines 653-793)
```dart
Text(translate("Permissions"), ...) // Header
GridView.count(...) // Grid of permission icons
```

Permission icons include:
- Keyboard (line ~695-707)
- Clipboard (line ~708-720)
- Audio (line ~721-733)
- File transfer (line ~734-746)
- Restart (line ~747-759)
- Recording (line ~760-772)
- Block input (line ~773-785)

#### **4. Disconnect Button** (lines 978-987)
```dart
buildButton(context,
    color: Colors.redAccent,
    onClick: handleDisconnect,
    text: 'Disconnect',
    icon: Icon(Icons.link_off_rounded, ...),
```

#### **5. Disconnect Handler** (lines 1132-1134)
```dart
void handleDisconnect() {
    bind.cmCloseConnection(connId: client.id);
}
```

---

## 📱 **Window Management**

### **`flutter/lib/main.dart`**

#### **Show CM Window Function** (lines 310-335)
```dart
showCmWindow({bool isStartup = false}) async {
    // Key settings:
    // - alwaysOnTop: true (line 313)
    // - Alignment.topRight (line 323) ← Window position!
    // - Size: 300x490 (from consts.dart)
```

**Window Position:** Line 323
```dart
windowManager.setSizeAlignment(
    kConnectionManagerWindowSizeClosedChat, 
    Alignment.topRight  // ← TOP-RIGHT corner!
);
```

#### **Hide CM Window Function** (lines 337-354)
```dart
hideCmWindow({bool isStartup = false}) async {
    // Hides window when no connections
}
```

---

## ⚙️ **Window Display Logic**

### **`flutter/lib/models/server_model.dart`**

#### **Auto-show on Connection** (line 172)
```dart
if (!hideCm) showCmWindow();
```

#### **Multiple Show Triggers:**
- Line 172: When clients connected
- Line 288: Connection event
- Line 546: Connection established
- Line 581: Connection update

---

## 🎨 **Window Configuration**

### **`flutter/lib/consts.dart`** (lines 274-275)

```dart
const Size kConnectionManagerWindowSizeClosedChat = Size(300, 490);
const Size kConnectionManagerWindowSizeOpenChat = Size(700, 490);
```

**Window Properties:**
- Width: 300px (closed), 700px (with chat open)
- Height: 490px
- Position: Top-right corner
- Always on top: Yes
- Hides dock icon: Yes (line 315 main.dart)

---

## 🖥️ **Platform-Specific Rendering**

### **`flutter/lib/desktop/pages/server_page.dart`** (lines 89-98)

```dart
return isLinux
    ? buildVirtualWindowFrame(context, body)  // Linux
    : workaroundWindowBorder(                  // Windows/macOS
          context,
          Container(decoration: BoxDecoration(border: ...))
      );
```

**Platform Detection:**
- Linux: Uses `buildVirtualWindowFrame`
- Windows/macOS: Uses `workaroundWindowBorder`

---

## 🔗 **Backend Connection**

### **IPC Communication** - `src/ui_cm_interface.rs`

#### **Connection Event Handler** (lines 412-421)
```rust
Data::Login{id, peer_id, name, authorized, ...} => {
    self.cm.add_connection(...);  // Adds connection to UI
}
```

#### **Add Connection** (lines 129-178)
```rust
fn add_connection(&self, ...) {
    // Creates Client object
    CLIENTS.write().unwrap().insert(id, client.clone());
    self.ui_handler.add_connection(&client);  // Updates Flutter UI
}
```

---

## 🎯 **To Remove/Modify This Popup:**

### **Option 1: Disable Window Display**
**File:** `flutter/lib/models/server_model.dart` (line 172)
```dart
// Change:
if (!hideCm) showCmWindow();
// To:
// if (!hideCm) showCmWindow();  // Commented out
```

### **Option 2: Auto-hide Window**
**File:** `flutter/lib/main.dart` (line 310-335)
```dart
// Modify showCmWindow() to immediately hide:
showCmWindow({bool isStartup = false}) async {
    await hideCmWindow(isStartup: isStartup);
    return;  // Skip showing
}
```

### **Option 3: Remove Window Position (Top-Right)**
**File:** `flutter/lib/main.dart` (line 323)
```dart
// Remove or comment out:
// await windowManager.setSizeAlignment(
//     kConnectionManagerWindowSizeClosedChat, Alignment.topRight);
```

### **Option 4: Hide Specific UI Elements**
**File:** `flutter/lib/desktop/pages/server_page.dart`
- Comment out permissions section (lines 649-793)
- Comment out disconnect button (lines 975-990)
- Comment out connection status (lines 536-554)

---

## 📝 **Quick Reference**

| Component | File | Line Range |
|-----------|------|------------|
| Main UI | `flutter/lib/desktop/pages/server_page.dart` | 1-1200 |
| Window Show/Hide | `flutter/lib/main.dart` | 310-354 |
| Server Logic | `flutter/lib/models/server_model.dart` | 165-175 |
| Window Size | `flutter/lib/consts.dart` | 274-275 |
| IPC Handler | `src/ui_cm_interface.rs` | 412-421 |

---

## 🚀 **Easiest Modification:**

**Disable popup entirely by commenting one line:**
```dart
// flutter/lib/models/server_model.dart:172
// if (!hideCm) showCmWindow();
```

This will prevent the connection manager window from appearing on Windows, Linux, and macOS!