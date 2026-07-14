# Agneax OS Developer Guide

Welcome to the development guide for **Agneax OS**. This document explains the system architecture, code layout, styling systems, and how to create new system applications.

## System Architecture

Agneax OS uses a modular layout that separates the user interface, system level controls, and window rendering:

```
  +----------------------------------------------+
  |              Agneax Desktop UI               |
  |     (PySide6 App Shell + QtQuick QML)        |
  +-------+-----------------------------+--------+
          |                             |
     (C++ ctypes)                    (TCP IPC)
          |                             |
  +-------v---------------------+  +----v--------+
  |    C++ Layout Helper        |  | Rust Daemon |
  | (compositor_helper.so math) |  | (Telemetry) |
  +-----------------------------+  +-------------+
```

1. **Agneax Desktop UI**: Beautiful frontend styled in dark glassmorphism. It uses QML for the animations and PySide6 as the runtime.
2. **C++ Layout Helper (`libcompositor_helper.so`)**: Handles zero-overhead math calculations for window grid tiling and snap region shapes.
3. **Rust System Daemon (`agneax-core`)**: Runs in the background as a systemd service. Collects telemetry (CPU, memory, disk, network) and executes administrative tasks safely.

---

## Code Layout

- `desktop/`: Custom desktop environment files.
  - `main.py`: Entrypoint initializing the PySide6 bridge.
  - `qml/`: Viewports containing the shell panel, start menu, quick settings, and icons.
  - `cpp_src/`: Compositor grid tiling calculations code.
- `packages/agneax-core/`: System daemon (Rust).
- `control-center/`: System Settings app.
- `store/`: Flatpak and APT app store client.
- `installer/`: System partition installer.
- `configs/`: Root filesystem overlays (LightDM, systemd, GRUB configs).
- `tests/`: Automated unit tests.

---

## Styling Guidelines

For design consistency, all QML applications should inherit variables from the root viewport:
- **Primary Accent**: `#00F2FE` (Teal-blue neon)
- **Secondary Accent**: `#FF5E62` (Pink-red neon)
- **Glass Background**: `rgba(20, 24, 33, 0.75)` (dark semi-transparent pane)
- **Card Background**: `rgba(45, 55, 72, 0.5)`
- **Border Overlay**: `rgba(255, 255, 255, 0.08)` (1px solid border)
- **Font Face**: `Segoe UI` (default), `Inter`, `Roboto` or system sans-serif.

### Designing a Glassmorphic Pane
```qml
Rectangle {
    width: 300; height: 200
    color: "rgba(20, 24, 33, 0.75)"
    radius: 12
    border.color: "rgba(255, 255, 255, 0.08)"
    border.width: 1
}
```

---

## Creating a System App Module

To add a new application (e.g. `agneax-updater`):
1. Create your application logic in python or compile it into a binary.
2. Register the application in the Start Menu by appending it to the `appsList` inside `desktop/qml/StartMenu.qml`:
   ```qml
   {"name": "System Update", "icon": "🔄", "id": "agneax-updater", "category": "System"}
   ```
3. Modify the launcher bridge inside `desktop/main.py` under `launchApp`:
   ```python
   elif app_name == "agneax-updater":
       os.system("python3 /opt/agneax/updater/main.py &")
   ```
