# Agneax Plymouth — Custom Branded Boot Splash for Agneax OS

This is the customized, performance-optimized, and brand-hardened Plymouth boot splash implementation for Agneax OS. 

It is natively integrated into the Agneax OS build pipeline as a debian package (`agneax-plymouth`), featuring custom graphics alignment, faster fade transitions, and stripped components to maintain a lightweight footprint.

---

## 🌟 Key Customizations

1. **Anti-Aliased Logo Centering (C Level Defaults)**:
   - Modified `src/plugins/splash/two-step/plugin.c` to natively stack the watermark logo at `0.5` horizontal alignment and `0.42` vertical alignment.
   - Designed to avoid overlap with the cyan progress spinner at early kernel resolutions (`380x96`).

2. **Smooth Fade Animations**:
   - Adjusted transition durations default to `0.4` seconds (400ms) for high-performance fade transitions.

3. **Solid Pitch-Black Fallbacks**:
   - Compiles with hardcoded background variables (`-Dbackground-color=0x000000`, etc.) to guarantee a completely black viewport on graphics drivers initialization, preventing grey console screen blinks.

4. **Lean Compilations**:
   - Stripped obsolete upstream layout plugins (such as `space-flares`, `fade-throbber`, etc.).
   - Kept only critical system graphics composites (`two-step`, `script`, `text`, `details`), preserving Safe Graphics Mode compatibilities.

---

## 🛠️ Build and Packaging

To compile the source code and generate the Debian package:

```bash
# Build script executes compiler hooks
./scripts/package_plymouth.sh
```

This automates Meson configurations, strips unneeded symbols, and outputs `build/agneax-plymouth_1.0.0_amd64.deb` which is automatically integrated into the ISO build pipeline.
