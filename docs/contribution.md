# Agneax OS — Contribution Guidelines

Thank you for contributing to Agneax OS! Below are guidelines to ensure contributions are solid, secure, and easily maintainable.

---

## 1. Code Standards

- **Rust Code**: Follow `clippy` suggestions. Use standard style guidelines via `rustfmt`.
- **Python (PySide6)**: Keep GUI applications modular. Use absolute path files overlays. Do not hardcode paths.
- **C++ Files**: Place Layout calculation functions inside `extern "C"` blocks to allow linking through PySide6 ctypes wrappers.

---

## 2. Directory Layout Architecture

Always conform to the standard project layout:
- `branding/`: Contains custom vector logos and desktop backgrounds.
- `desktop/`: Holds desktop shell widgets, panels, and terminal apps.
- `store/`: Handles package updates and download loops.
- `packages/`: Holds native systems services and telemetry daemons.

---

## 3. Pull Request Checklist

Before submitting changes:
1. Ensure all code blocks pass standard compile checks (`cargo check` / `cmake`).
2. Run localized python verification tests to check layout geometry and API parsers:
   ```bash
   python tests/test_agneax.py
   ```
3. Update relevant guides in `docs/` if modifying configurations or IPC parameters.
