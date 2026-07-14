# Agneax OS — Application API Documentation

This document describes the IPC APIs and QML bindings details for custom Agneax OS applications.

---

## 1. System Telemetry Daemon IPC API (`agneax-core`)

The Rust privilege daemon listens on local port `9090` via TCP sockets.

### JSON-RPC Commands

#### A. Request Telemetry (`get_telemetry`)
- **Request**: `{"method": "get_telemetry"}`
- **Response**:
  ```json
  {
    "cpu_usage": 15.2,
    "total_mem": 8589934592,
    "used_mem": 4124930048,
    "mem_usage_pct": 48.0,
    "cpu_temp": 41.5,
    "disks": [
      { "mount_point": "/", "total": 128000000000, "available": 84500000000 }
    ],
    "battery": { "pct": 98, "charging": true },
    "uptime": 7200
  }
  ```

#### B. Toggle Firewall (`toggle_firewall`)
- **Request**: `{"method": "toggle_firewall", "params": {"enable": true}}`
- **Response**: `{"status": "success"}`

#### C. Package Update Cache (`pkg_update_cache`)
- **Request**: `{"method": "pkg_update_cache"}`
- **Response**: `{"status": "success"}`

---

## 2. Python-QML Bridge Bindings (`SystemBridge`)

Exposes host integrations directly inside custom desktop shell windows.

### Properties & Signals
- **`telemetryUpdated(QString data)`**: Emitted periodically with JSON system state details.

### API Methods
- **`getTelemetry()`**: Returns current telemetry parameters directly as a serialized JSON string.
- **`calculateSnapGeometry(int width, int height, int taskbarHeight, int direction)`**: Computes target bounds coordinates for window snapping rules.
- **`launchApp(QString appId)`**: Spawns application sub-processes.
