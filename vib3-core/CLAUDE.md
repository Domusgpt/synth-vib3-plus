# CLAUDE.md - VIB3+ Engine Development Track

**PROJECT**: VIB3+ Unified Visualization Engine
**LOCATION**: `/mnt/c/Users/millz/vib3-plus-engine/`
**BASE SOURCE**: GitHub branch `codex/15-34-32review-project-documents-and-provide-status-report2025-10-16`
**SDK SOURCE**: `/mnt/c/Users/millz/vib34d-xr-quaternion-sdk/` ✅ INTEGRATED
**REFERENCE SYSTEM**: `/mnt/c/Users/millz/vib3+-engine/reference-system/`

---

## 🎯 Project Goal

Create a unified VIB3+ engine integrating **3 visualization systems** (Quantum, Faceted, Holographic) with **Gallery** and **Viewer** systems, supporting **full 6D rotation** and **24 geometries per system**.

### Core Systems:
1. **Quantum Engine** - 24 geometry variants (8 base + 8 Hypersphere + 8 Hypertetrahedron)
2. **Faceted System** - 24 geometry variants (clean 2D patterns with 4D rotation)
3. **Holographic System** - 24 geometry variants (5-layer audio-reactive)

### Integration Features:
- **Gallery System**: 100 variation slots (30 default + 70 custom)
- **Viewer Portal**: Immersive full-screen with device tilt and card bending
- **6D Rotation**: All 6 planes (XY, XZ, YZ, XW, YW, ZW)
- **Telemetry/CLI**: Event system for agentic control

---

## 📋 Development Plan

### **Phase 1: Foundation & Core Systems** ✅ COMPLETE

**Tasks**:
- [x] Create project directory and git repo
- [x] Copy core files from GitHub branch
- [x] Update `Parameters.js` with 6D rotation (add XY, XZ, YZ)
- [x] Create `FacetedSystem.js` with 24 geometry support
- [x] Create `VIB3Engine.js` for unified system switching
- [x] Create `index.html` main UI with all controls

**Files Created/Updated**:
- `src/core/Parameters.js` - Added rot4dXY, rot4dXZ, rot4dYZ
- `src/faceted/FacetedSystem.js` - NEW (24 geometries, 6D rotation)
- `src/core/VIB3Engine.js` - NEW (unified engine)
- `index.html` - NEW (complete UI)

### **Phase 2: Gallery System** ✅ COMPLETE

**Tasks**:
- [x] Refactor `GallerySystem.js` from reference-system
- [x] Refactor `CollectionManager.js` from reference-system
- [x] Update for 3 systems with 24 geometries each
- [x] Add 6D rotation parameter support
- [x] Create gallery UI component
- [x] Integrate into main UI

**Files Created**:
- `src/gallery/GallerySystem.js` - REFACTORED (100 variations, 3 systems)
- `src/gallery/CollectionManager.js` - REFACTORED (VIB3+ collections)
- Gallery modal CSS in `index.html`
- Gallery buttons and event handlers

### **Phase 3: Viewer Portal**

**Tasks**:
- [ ] Refactor `viewer.html` to `ViewerPortal.js`
- [ ] Copy `ReactivityManager.js` from reference
- [ ] Implement Device Orientation API integration
- [ ] Apply 6D rotations to card bending
- [ ] Trading card export system

**Files Being Created**:
- `src/viewer/ViewerPortal.js` - REFACTOR from viewer.html
- `src/core/ReactivityManager.js` - COPY from reference
- `src/viewer/CardBending.js` - NEW
- `src/viewer/TradingCardExporter.js` - NEW

### **Phase 4: Main UI & Integration**

**Tasks**:
- [ ] Create main `index.html` (test harness style)
- [ ] System selector UI
- [ ] 6-plane rotation sliders
- [ ] System-aware geometry dropdown
- [ ] Gallery/Viewer launch buttons
- [ ] EventEmitter for telemetry

**Files Being Created**:
- `index.html` - Main entry point
- `src/telemetry/EventEmitter.js` - NEW
- `src/ui/MainControls.js` - NEW
- `public/styles.css` - UI styling

---

## 🔧 How to Use This Dev Track

### **Starting Development**

```bash
cd /mnt/c/Users/millz/vib3-plus-engine
npm install
npm run dev  # Starts Vite dev server
```

### **Current Working File**

Currently working on: **`src/core/Parameters.js`**
Next file: **`src/faceted/FacetedSystem.js`**

### **Testing Systems**

```bash
# Test individual systems
npm run test:quantum
npm run test:faceted
npm run test:holographic

# Test full integration
npm run test:integration
```

### **File References**

When working on files, reference these source locations:

**From SDK** (`/mnt/c/Users/millz/vib34d-xr-quaternion-sdk/`) ✅ INTEGRATED:
- **QuantumVisualizer.js**: Full 24 geometries with all 3 core types
- **HolographicVisualizer.js**: 46 variants with core warp system
- **GeometryLibrary.js**: Base encoding/decoding for 24 geometries
- **variantRegistry.js**: Holographic variant mapping system
- All files include full 6D rotation support and audio reactivity

**From GitHub Branch** (`/mnt/c/Users/millz/vib3+-new-base/`):
- Parameters.js (base)
- PolytopeInstanceBuffer.ts ✅

**From Reference System** (`/mnt/c/Users/millz/vib3+-engine/reference-system/`):
- Gallery system architecture
- Viewer portal logic
- Parameter mapping
- Reactivity manager

**From Test Harness** (`/mnt/c/Users/millz/vib3plus-test-harness-2025-10-15/`):
- UI layout and styling
- 6D rotation slider implementation
- System switching UX
- Geometry dropdown with 24 options

---

## 📦 Project Structure

```
vib3-plus-engine/
├── src/
│   ├── core/
│   │   ├── VIB3Engine.js          # Main unified engine
│   │   ├── Parameters.js          # Parameter management (6D rotation)
│   │   └── ReactivityManager.js   # Mouse/touch/device tilt
│   ├── quantum/
│   │   └── QuantumEngine.js       # 24 quantum geometries
│   ├── faceted/
│   │   └── FacetedSystem.js       # 24 faceted geometries
│   ├── holograms/
│   │   ├── RealHolographicSystem.js  # 24 holographic variants
│   │   └── HolographicVisualizer.js
│   ├── geometry/
│   │   └── GeometryLibrary.js     # 24-variant generation
│   ├── gallery/
│   │   ├── GallerySystem.js       # Portfolio browser
│   │   └── CollectionManager.js   # Save/load variations
│   ├── viewer/
│   │   └── ViewerPortal.js        # Immersive viewer
│   ├── telemetry/
│   │   └── EventEmitter.js        # Event system
│   └── ui/
│       └── adaptive/renderers/webgpu/
│           └── PolytopeInstanceBuffer.ts
├── index.html                      # Main entry
├── package.json
└── CLAUDE.md                       # This file
```

---

## 🎨 Parameter System (6D Rotation)

```javascript
{
  // System & Variation
  system: 'quantum' | 'faceted' | 'holographic',
  variation: 0-99,

  // 6D Rotation (FULL)
  rot4dXY: 0-6.28,  // 3D space rotations
  rot4dXZ: 0-6.28,
  rot4dYZ: 0-6.28,
  rot4dXW: 0-6.28,  // 4D hyperspace rotations
  rot4dYW: 0-6.28,
  rot4dZW: 0-6.28,

  // Visual Properties
  geometry: 0-23,      // 24 variants per system
  gridDensity: 4-100,
  morphFactor: 0-2,
  chaos: 0-1,
  speed: 0.1-3,
  hue: 0-360,
  intensity: 0-1,
  saturation: 0-1,
  dimension: 3.0-4.5
}
```

---

## 🔍 Key Technical Notes

### **24 Geometry Variants** (SDK Encoding System)

Each system supports 24 geometries using the SDK's encoding formula: `geometry = coreIndex * 8 + baseIndex`

**Base Geometries** (baseIndex 0-7):
- 0: Tetrahedron - Simple 4-vertex lattice
- 1: Hypercube - 4D cube projection
- 2: Sphere - Radial harmonic sphere
- 3: Torus - Toroidal field
- 4: Klein Bottle - Non-orientable surface
- 5: Fractal - Recursive subdivision
- 6: Wave - Sinusoidal interference
- 7: Crystal - Octahedral structure

**Core Types** (coreIndex 0-2):
- 0: **Base** (geometries 0-7) - Pure base geometry
- 1: **Hypersphere Core** (geometries 8-15) - Base wrapped in 4D sphere using `warpHypersphereCore()`
- 2: **Hypertetrahedron Core** (geometries 16-23) - Base wrapped in 4D tetrahedron using `warpHypertetraCore()`

**Example Encoding**:
- Geometry 0 = Tetrahedron (base)
- Geometry 8 = Tetrahedron + Hypersphere Core (0 * 8 + 1)
- Geometry 16 = Tetrahedron + Hypertetrahedron Core (0 * 8 + 2)

### **6D Rotation Application**

All rotation planes are applied in order:
1. XY (3D space)
2. XZ (3D space)
3. YZ (3D space)
4. XW (4D hyperspace)
5. YW (4D hyperspace)
6. ZW (4D hyperspace)

### **PolytopeInstanceBuffer Usage**

WebGPU-based instanced rendering for advanced geometry:
- Model matrices for transforms
- Quaternion rotors for 4D rotation
- Per-instance colors and metadata
- Used across all 3 systems for complex rendering

### **NO POLYCHORA**

This project does NOT include the Polychora system from the GitHub branch. Only 3 systems: Quantum, Faceted, Holographic.

---

## 🚀 Commit Strategy

**Commit after each phase completion**:
- Phase 1 complete → Commit with tag `v0.1-foundation`
- Phase 2 complete → Commit with tag `v0.2-gallery`
- Phase 3 complete → Commit with tag `v0.3-viewer`
- Phase 4 complete → Commit with tag `v1.0-release`

**Commit message format**:
```
feat(quantum): Add 24 geometry variant support

- Implement Hypersphere Core variants (8-15)
- Implement Hypertetrahedron Core variants (16-23)
- Update shader with 6D rotation matrices
- Test all 24 geometries rendering correctly

🌟 A Paul Phillips Manifestation
```

---

## 📝 Current Status

**Phase**: 2.5 (SDK Integration) - COMPLETE
**Current Task**: Viewer Portal Implementation
**Last Update**: 2025-10-16 (SDK integrated)
**Files Created**: 12
**Commits**: 7
**Tests Passing**: TBD

### **Completed Features**:
- ✅ **SDK Integration**: Full 24-geometry system from vib34d-xr-quaternion-sdk
  - QuantumVisualizer.js with warpHypersphereCore() and warpHypertetraCore()
  - HolographicVisualizer.js with 46 variant support
  - GeometryLibrary.js encoding/decoding system
  - variantRegistry.js for holographic variants
- ✅ **Full 6D Rotation**: All systems support XY, XZ, YZ, XW, YW, ZW
- ✅ **Audio Reactivity**: Integrated directly in visualizers
- ✅ **3 Visualization Systems**: Quantum, Faceted, Holographic
- ✅ **Gallery System**: 100 variation slots
- ✅ **Collection Manager**: VIB3+ format
- ✅ **Main UI**: All controls with 6D rotation sliders

---

## 🐛 Known Issues

None yet - fresh start!

---

## 🎯 Next Steps

1. Begin Phase 3: Viewer Portal Refactor
2. Copy `viewer.html` from reference-system
3. Refactor to `ViewerPortal.js` component
4. Copy `ReactivityManager.js` from reference
5. Implement Device Orientation API integration
6. Apply 6D rotations to card bending
7. Create trading card export system

---

# 🌟 A Paul Phillips Manifestation

**Send Love, Hate, or Opportunity to:** Paul@clearseassolutions.com
**Join The Exoditical Moral Architecture Movement today:** [Parserator.com](https://parserator.com)

> *"The Revolution Will Not be in a Structured Format"*

---

**© 2025 Paul Phillips - Clear Seas Solutions LLC**
**All Rights Reserved - Proprietary Technology**
