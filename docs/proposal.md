# Godot MCP Studio: Architecture Proposal

*Generated 2026-04-11*

## 1. Thesis

Build a **production-grade, fully open-source Godot MCP server** that feels native to Godot and mature enough for real daily use.

The quality bar should be much higher than a thin editor bridge. This project should feel like a serious developer tool:

- persistent editor integration
- reliable session routing
- strong read resources and safe write workflows
- thoughtful tool design shaped by real usability feedback
- tests, CI, documentation, diagnostics, and operational discipline

The maintainers are unusually well positioned to do this. You and Scriptwonder have already spent a large amount of time shipping, refining, and hardening a production editor MCP through community feedback and usability-driven iteration. The value here is not copying that product. The value is bringing the same maturity, product judgment, and responsiveness to the Godot community in a project that is openly built for Godot from day one.

---

## 2. Why This Project Exists

Godot is a strong fit for a serious MCP server.

- The Godot ecosystem is open, scriptable, and community-oriented.
- The engine exposes the right core APIs for scenes, nodes, resources, project settings, editor plugins, cameras, materials, shaders, particles, and viewport capture.
- The current Godot MCP landscape still leaves plenty of room for a more mature, better-tested, more usability-focused product.

This project should be built around a simple idea:

- **make an excellent Godot MCP for the Godot community**

That means:

- deep support for common Godot workflows
- practical tooling that improves real day-to-day editor use
- open-source development with clear contributor paths
- product decisions informed by community feedback, not just technical novelty

The reference point for quality should be what a mature editor MCP feels like in practice: stable sessions, useful read surfaces, safe mutation paths, good errors, strong docs, and fast iteration on usability problems reported by real users.

---

## 3. Product Principles

### 3.1 Godot-native naming

Use Godot concepts directly:

- `scene.*`, not generic level abstractions
- `node.*`, not `entity.*`
- `resource.*`, not generic asset fiction
- `signal.*`, `autoload.*`, `input_map.*`, `project_settings.*`

If a concept is Godot-specific, expose it directly. Do not hide it behind fake portability.

### 3.2 Persistent editor plugin first, headless path second

Interactive editor automation should use a **persistent Godot editor plugin** with a long-lived connection to the MCP server.

Headless execution should still exist, but as a separate mode for:

- CI
- project export
- scripted imports
- recovery when the editor plugin is unavailable

This should be a hybrid model, not dogma.

### 3.3 Resources before aggressive mutation

The product should win first on reliable read access:

- scene tree
- selection
- project info
- filesystem index
- logs
- project settings

Then add write tools with proper undo integration and failure handling.

### 3.4 Explicit session targeting

Every tool call must target a specific Godot editor session. Never rely on "last connected editor."

### 3.5 `code.execute` is privileged

Editor-side GDScript execution is useful, but it should be treated as an escape hatch and security boundary, not the main API.

---

## 4. Product Scope

### 4.1 V1 scope

**Godot 4.3+ required. Godot 4.4+ recommended** for UID support and recent EditorInterface improvements.

Build a Godot MCP server that is strong in these areas:

- scene creation and lifecycle
- node hierarchy inspection and mutation
- resource and filesystem operations
- script creation, reading, patching, and attachment
- signals and project configuration
- play/stop and log inspection
- multi-instance support
- real tests and CI

### 4.2 Explicit non-goals for V1

- exhaustive coverage of every Godot editor subsystem in v1
- full parity with every specialized Unity package or editor integration
- premature marketplace or extension-platform ambitions
- giant action-blob tools with dozens of loosely related parameters
- package-management or profiler parity before core workflows are solid
- broad arbitrary code execution as the primary interface

---

## 5. Godot-Native Tool Taxonomy

The tool surface should look like a Godot product, not a generalized game-engine layer.

### 5.1 Session and editor tools

- `session.list`
- `session.activate`
- `editor.state`
- `editor.selection.get`
- `editor.selection.set`
- `editor.screenshot`
- `editor.command.execute`

### 5.2 Scene tools

- `scene.create`
- `scene.open`
- `scene.save`
- `scene.save_as`
- `scene.close`
- `scene.instantiate`
- `scene.inherit`
- `scene.get_hierarchy`
- `scene.get_roots`

### 5.3 Node tools

- `node.create`
- `node.delete`
- `node.duplicate`
- `node.reparent`
- `node.rename`
- `node.move`
- `node.find`
- `node.get_properties`
- `node.set_property`
- `node.get_children`
- `node.get_groups`
- `node.add_to_group`
- `node.remove_from_group`
- `node.attach_script`

### 5.4 Resource and filesystem tools

> **Why filesystem tools when AI clients have native file access?** Godot's import system doesn't see raw filesystem writes. Writing a `.png` to `res://` via the OS won't register it as a texture until the editor reimports. These tools exist to trigger `EditorFileSystem.scan()` / `EditorFileSystem.reimport_files()` after writes, ensuring Godot's resource pipeline stays in sync. Without this, AI-written assets are invisible to the editor.

- `resource.search`
- `resource.load`
- `resource.save`
- `resource.create`
- `resource.assign`
- `resource.inspect`
- `filesystem.search`
- `filesystem.read_text`
- `filesystem.write_text`
- `filesystem.move`
- `filesystem.rename`
- `filesystem.delete`
- `import.reimport`

### 5.5 Script tools

- `script.create`
- `script.read`
- `script.patch` — **Deferred to Phase 3+.** Reliable GDScript patching (indent-sensitive, signal-aware, annotation-safe) is a research item, not a V1 tool. V1 should use full-file `script.create` / `script.read` writes instead.
- `script.attach`
- `script.detach`
- `script.find_symbols`
- `script.get_class_info`

### 5.6 Godot-specific project tools

- `signal.list`
- `signal.connect`
- `signal.disconnect`
- `autoload.list`
- `autoload.add`
- `autoload.remove`
- `input_map.list`
- `input_map.add_action`
- `input_map.remove_action`
- `input_map.bind_event`
- `project_settings.get`
- `project_settings.set`
- `uid.get`
- `uid.update`

### 5.7 Visual, material, and camera tools

- `material.create_standard`
- `material.assign`
- `material.inspect`
- `material.set_property`
- `shader.create`
- `shader.read`
- `shader.update`
- `shader.set_uniform`
- `shader.attach`
- `particles.create`
- `particles.inspect`
- `particles.set_process_material`
- `particles.play`
- `particles.stop`
- `camera.create_2d`
- `camera.create_3d`
- `camera.set_current`
- `camera.capture`
- `camera.create_follow_rig`

### 5.8 Runtime and diagnostics tools

- `project.run`
- `project.stop`
- `logs.read`
- `logs.clear`
- `build.export`
- `build.list_presets`
- `performance.get_monitors`
- `batch.execute`

Post-launch scope includes `animation_player.*` tools (play, stop, queue, get/set properties on `AnimationPlayer` and `AnimationTree` nodes) — deferred until the core runtime surface is stable.

### 5.9 MCP resources

Expose read-heavy state as resources, not tools:

- `godot://sessions`
- `godot://scene/current`
- `godot://scene/hierarchy`
- `godot://selection/current`
- `godot://project/info`
- `godot://project/settings`
- `godot://autoloads`
- `godot://input-map`
- `godot://filesystem/index`
- `godot://logs/recent`

---

## 6. Architecture

### 6.1 High-level design

```text
AI Client
   |
   | MCP
   v
Godot MCP Server (Python / FastMCP)
   |
   | session router + job manager + tool/resource registry
   v
Persistent Godot Editor Plugin (GDScript)
   |
   | EditorInterface + SceneTree + ResourceLoader + ProjectSettings + FileAccess
   v
Godot Editor

Optional side path:

Godot MCP Server
   |
   | one-shot headless command runner
   v
godot --headless --script ...
```

### 6.2 Server-side components

The Python server should contain:

- `transport/`: WebSocket or TCP session transport
- `sessions/`: session registry, active-session resolution, reconnect handling
- `jobs/`: long-running task tracking for exports, reimports, screenshots, and scans
- `tools/`: FastMCP tool implementations
- `resources/`: MCP resources
- `protocol/`: request envelopes, version negotiation, error schema
- `godot_client/`: typed client for editor-plugin commands
- `cli/`: local commands for diagnostics and headless workflows

### 6.3 Godot plugin responsibilities

The editor plugin should own:

- connection lifecycle
- editor event hooks
- scene/node/resource operations
- selection tracking
- undo/redo integration where possible
- readiness reporting
- log forwarding
- screenshot capture

The plugin should stay thin. Complex orchestration belongs in Python; direct editor mutations belong in GDScript.

### 6.4 Session model

Every connected editor session should report:

- `session_id`
- Godot version
- project path
- plugin version
- protocol version
- current scene
- play state
- capability flags

Every tool call must include or resolve against a session ID.

### 6.5 Readiness and lifecycle

The proposal needs explicit lifecycle handling from day one:

- editor startup
- plugin reload
- scene switch
- project reload
- import in progress
- script parse error state
- play mode start/stop
- dropped socket and reconnect

The server should not fire write operations blindly. It should gate them behind readiness checks and return actionable errors.

### 6.6 Jobs and progress

Long-running tasks should use a job model:

- `build.export`
- `import.reimport`
- large filesystem scans
- screenshot batches
- headless project runs

Each job should have:

- `job_id`
- state
- progress
- result payload
- cancellation support where possible

### 6.7 Undo semantics

Write tools must integrate with undo/redo where Godot allows it. If an operation cannot be undone cleanly, say so in the tool contract.

Do not claim atomicity for `batch.execute`. The correct contract is:

- ordered execution
- optional undo grouping
- per-step result reporting
- partial failure handling

### 6.9 GDScript plugin concurrency model

The Godot editor runs on a single main thread. The plugin cannot block that thread or the editor freezes. The concurrency model must be:

1. **Command queue.** The WebSocket listener receives commands and pushes them onto an internal queue (`Array` or `PackedArray`). It never executes editor operations directly from the socket callback.
2. **Frame-budget dispatch.** A `_process()` tick drains the queue, executing one or more commands per frame. Each command should have a time budget (e.g., 4ms per frame) to avoid stalling the editor. Large operations (hierarchy walks, filesystem scans) must yield across frames.
3. **`call_deferred` pattern.** Any operation that touches the scene tree, selection, or undo system must go through `call_deferred()` to ensure it runs at a safe point in the frame lifecycle. Direct calls risk crashes or undefined behavior during scene tree notification propagation.
4. **Response correlation.** Each inbound command carries a `request_id`. The dispatcher stores pending requests and matches responses (or errors) back to them. This enables the Python server to use async/await patterns cleanly.

If GDScript's performance becomes a bottleneck (e.g., serializing large scene trees or processing heavy filesystem scans), GDExtension (C++) is the contingency path. The plugin architecture should keep the command-dispatch interface stable so the GDScript implementation can be swapped for a GDExtension without changing the Python server or protocol.

### 6.8 Security model

This needs to be part of the proposal, not an afterthought:

- localhost-only by default
- explicit project trust
- optional auth token for external clients
- dangerous-operation annotations
- audit log of mutations and code execution
- separate capability flag for `code.execute`

---

## 7. Architectural Quality Bar

The maintainers already know what a mature editor MCP has to get right. That experience should inform this project heavily.

The point is not to duplicate another product's API. The point is to bring over the operational quality bar and the architectural best practices that actually made a large editor MCP usable in the real world.

### 7.1 Operational practices to carry forward

- persistent server-to-editor connection
- multi-instance routing
- readiness checks before mutations
- pagination for large hierarchies and logs
- resources for read-only state
- batch execution with structured results
- CLI diagnostics
- telemetry and structured logging
- layered testing: unit, integration, e2e

### 7.2 Product and architecture habits to adapt for Godot

- tool grouping can work, but the groups should be Godot-oriented
- script patching workflows are valuable, but need GDScript-specific parsing and anchoring behavior
- scene and object management patterns are useful, but must be re-modeled around nodes and scenes rather than copied conceptually from GameObjects and Components

### 7.3 Patterns to avoid copying literally

- generic `manage_*` blob tools with huge optional parameter surfaces
- Unity-specific group structure
- Unity object identity assumptions
- anything that exposes Unity package concepts as if they were portable

---
## 8. Capability Direction Informed by Mature MCP Work

This section uses the feature coverage of a mature editor MCP as a reference point for the kinds of workflows that a high-quality Godot MCP should cover.

The goal is not feature cloning. The goal is to decide what the **Godot-native version** of those capabilities should look like.

The short version:

- Some Unity MCP capabilities map cleanly to Godot.
- Some map only partially.
- Some do **not** fail because Godot is "less developed"; they fail because they are built around Unity-specific packages and concepts.
- The real maturity gaps for Godot are mostly in advanced editor subsystems, profiling tooling, and specialized ecosystem integrations.

### 8.1 Capabilities that should translate well

- `manage_scene` -> Godot scene lifecycle tools
- `manage_gameobject` -> `node.*` tools
- `find_gameobjects` -> `node.find`
- `manage_components` -> mostly `node.set_property`, `node.create`, and node-type-specific helpers
- `manage_asset` -> `resource.*` and `filesystem.*`
- `manage_script` -> `script.*`
- `find_in_file` -> text search tools
- `manage_editor` play/stop -> `project.run` and `project.stop`
- `read_console` -> `logs.read`
- `batch_execute` -> `batch.execute`

These are the high-value core. They should anchor the first release.

### 8.2 Capabilities that should be adapted for Godot

- `manage_build` should become a Godot export workflow, not a Unity-style build pipeline clone. Model it around export presets, preset inspection, headless export commands, and export logs. The right tools are things like `build.list_presets`, `build.export`, and `build.get_last_result`.
- `manage_material`, `manage_shader`, and `manage_texture` should absolutely exist, but as Godot-native tools. Godot has the APIs here: `StandardMaterial3D`, `BaseMaterial3D`, `Shader`, `ShaderMaterial`, and `VisualShader` are real first-class resources. The adaptation should focus on `material.create_standard`, `material.assign`, `shader.create`, `shader.read`, `shader.update`, and `shader.set_uniform` rather than mirroring Unity's schema one property at a time.
- `manage_ui` should become `ui.*` tools built around `Control` nodes, containers, anchors, offsets, size flags, and themes. The adaptation is viable, but the layout and theming model is different enough that Unity UI assumptions should be thrown away.
- `manage_physics` should be split into a few smaller Godot families: project-wide layer and mask settings, body and shape inspection, collision toggles, and physics-related node property helpers. That will cover most useful workflows without pretending Godot exposes the same editor-time physics stack as Unity.
- `manage_camera` should be ported, but as a Godot camera toolkit rather than a Cinemachine wrapper. Godot has `Camera2D`, `Camera3D`, and viewport APIs, so `camera.create_2d`, `camera.create_3d`, `camera.set_current`, `camera.capture`, and a few rig helpers are realistic. The screenshot and capture path is credible via viewport image capture. The Cinemachine-specific parts are not.
- `run_tests` is possible, but should be designed as a pluggable provider model. The core server can expose `tests.discover` and `tests.run`, while the actual backend can target a custom harness or community framework. Do not hardwire the proposal to one Godot test tool too early.
- `manage_profiler` should become lightweight performance and rendering diagnostics. Godot exposes engine and rendering metrics, so tools like `performance.get_monitors`, `performance.capture_window`, and `rendering.get_info` make sense. What does not make sense is promising direct parity with Unity Profiler, Memory Profiler, and Frame Debugger.

### 8.3 Capabilities that need Godot-native reinterpretation

- `manage_probuilder` should become a lighter Godot geometry toolkit, not a ProBuilder clone. Godot has usable APIs here, but not the same product surface: CSG nodes, `SurfaceTool`, `ArrayMesh`, and `MeshDataTool` are enough for primitive generation, boolean-style blocking, procedural mesh generation, face-level inspection, and simple mesh repair. The right adaptation is `mesh.create_primitive`, `mesh.generate_array_mesh`, `mesh.inspect_surface`, `mesh.apply_surface_tool`, and `csg.create_blockout`, not full editor modeling parity.
- `manage_vfx` should be split into `particles.*`, `material.*`, `shader.*`, and maybe `line.*` tools. Godot has real APIs for VFX-adjacent work: `GPUParticles2D`, `GPUParticles3D`, `CPUParticles2D`, `CPUParticles3D`, `ParticleProcessMaterial`, and `ShaderMaterial`. That is enough for emitter creation, burst setup, curves and gradients, mesh assignment, start and stop control, and shader-driven effects. What it does not give you is Unity VFX Graph parity, so the design should be parameter- and resource-driven rather than graph-driven.
- `manage_camera` features tied to Cinemachine should be adapted into rig recipes. Godot does not have Cinemachine, but it does have enough primitives to build useful abstractions with `Camera2D`, `Camera3D`, `SpringArm3D`, `Path3D`, and `PathFollow3D`. That suggests tools like `camera.create_follow_rig`, `camera.create_orbit_rig`, and `camera.create_rail_rig` instead of trying to emulate Brain, blend, and extension APIs literally.
- `manage_scriptable_object` should become `resource.*`, because Godot `Resource` is the real analog. This is a good fit if you lean into `.tres` and `.res` workflows: `resource.create`, `resource.instantiate`, `resource.set_property`, `resource.save`, and `resource.assign`. That is actually a strong Godot story once it is named correctly.
- `manage_packages` should become add-on and plugin management. Godot does not have a first-party package ecosystem equivalent to Unity Package Manager, but it does have `addons/`, `plugin.cfg`, editor plugins, and Asset Library workflows. So the adaptation is `addon.list`, `addon.enable`, `addon.disable`, `addon.install_local`, and maybe `assetlib.search`, not `package.add`.
- `unity_docs` and `unity_reflect` should be replaced with Godot-specific documentation and reflection helpers. Reflection should focus on node classes, properties, signals, methods, and resource types. Documentation tools should target Godot docs or a local indexed knowledge base.
- Memory snapshot and Frame Debugger workflows from `manage_profiler` should not be promised in v1. The right adaptation is a narrower diagnostics surface: runtime monitors, rendering counters, frame timings where available, scene statistics, and structured project-health checks.

### 8.4 Does Godot actually have the APIs for this?

Mostly yes.

- Editor integration: yes. `EditorPlugin` and `EditorInterface` are exactly the right foundation for a persistent editor plugin.
- Filesystem and resources: yes. `EditorFileSystem`, `ResourceLoader`, `ResourceSaver`, and normal file APIs are enough for project indexing, resource inspection, and reimport-aware workflows.
- Shaders and materials: yes. `Shader`, `ShaderMaterial`, `VisualShader`, `StandardMaterial3D`, and `BaseMaterial3D` give you a strong material and shader tool surface.
- Particles and VFX: yes, for a practical MCP product. `GPUParticles2D/3D`, `CPUParticles2D/3D`, and `ParticleProcessMaterial` are enough for structured particle tooling. The gap is not "no APIs"; the gap is "no VFX Graph-style package to mirror."
- Camera and capture: yes. `Camera2D`, `Camera3D`, and viewport capture APIs are enough for camera creation, switching, and screenshot workflows.
- Mesh and procedural geometry: yes, partially. `SurfaceTool`, `ArrayMesh`, `MeshDataTool`, and CSG are enough for useful geometry helpers, but not enough to market full ProBuilder-equivalent editor modeling.
- Performance and profiling: partial yes. Godot has performance monitors and debugger hooks, but not the same breadth of built-in profiler product surface that Unity exposes.
- Package and ecosystem tooling: partial yes. Add-ons and Asset Library workflows exist, but there is no direct Unity Package Manager equivalent.

The right conclusion is:

- Godot is mature enough for shader, VFX, camera, resource, and project-automation tools.
- The things that do not map cleanly usually fail because they depend on specialized Unity packages or editor subsystems, not because Godot lacks core engine APIs.

### 8.5 The strategic takeaway

The right target is:

- the maturity, usefulness, and reliability of a production editor MCP
- expressed through Godot-native concepts, APIs, and workflows

---

## 9. Proposed Repo Structure

```text
godot-mcp-studio/
├── pyproject.toml
├── src/
│   ├── core/
│   ├── protocol/
│   ├── transport/
│   ├── sessions/
│   ├── jobs/
│   ├── tools/
│   │   ├── session.py
│   │   ├── editor.py
│   │   ├── scene.py
│   │   ├── node.py
│   │   ├── resource.py
│   │   ├── script.py
│   │   ├── signal.py
│   │   ├── project.py
│   │   ├── build.py
│   │   └── batch.py
│   ├── resources/
│   ├── godot_client/
│   └── cli/
├── plugin/
│   └── addons/godot_mcp_studio/
│       ├── plugin.cfg
│       ├── plugin.gd
│       ├── connection.gd
│       ├── handlers/
│       ├── state/
│       └── utils/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── e2e/
└── docs/
    ├── protocol.md
    ├── install.md
    ├── tool-reference.md
    ├── compatibility.md
    └── contributor-guide.md
```

---

## 10. Testing Strategy

### 10.1 Unit tests

Cover:

- request validation
- protocol serialization
- pagination
- session routing
- error mapping
- job state transitions

### 10.2 Integration tests

Use a mocked Godot client to test:

- tool orchestration
- failure handling
- reconnect behavior
- stale reference detection
- partial batch failures

### 10.3 Contract tests

Define a contract suite for the plugin/server boundary:

- handshake
- version mismatch behavior
- readiness checks
- event payloads
- log streaming
- job updates

### 10.4 End-to-end tests

Run against a real Godot project in CI:

- open project
- connect plugin
- create scene
- add and mutate nodes
- create and attach script
- run project
- read logs
- export using a sample preset

Godot is relatively CI-friendly compared with Unity and Unreal. That is a real strategic advantage and should be exploited.

---

## 11. Roadmap

### Phase 0: Prove the foundation (Weeks 1-2)

- Build the minimal Godot editor plugin that connects persistently to the Python server.
- Define protocol envelope, version handshake, session ID, and error schema.
- Prove selection read, scene hierarchy read, and play/stop against a real Godot project.
- Add a basic headless execution path for CI and exports.

Exit criteria:

- one editor session can connect reliably
- the server can route commands to that session
- the plugin survives reconnects and scene switches

### Phase 0.5: Distribution design (Week 2)

- Spike PyInstaller packaging: single binary that bundles the Python server, all dependencies, and a launcher script.
- Test on macOS, Windows, and Linux.
- Define the end-user install flow: download binary → run → configure Claude Desktop / Cursor / etc.
- Validate that the binary can auto-discover or be pointed at the Godot editor plugin.
- Document the build pipeline so any contributor can produce a release binary.

Exit criteria:

- a single command produces a working binary on at least one platform
- the binary starts the MCP server without requiring a Python installation

### Phase 1: Read-first product slice (Weeks 2-4)

- `session.*`
- `editor.state`
- `editor.selection.*`
- `scene.get_hierarchy`
- `node.find`
- `project.info`
- `project_settings.get`
- `logs.read`
- MCP resources for current scene, hierarchy, selection, project info, recent logs

Exit criteria:

- the server is already useful as an inspection and navigation tool
- large hierarchies and logs are paged and stable

### Phase 2: Safe write path (Weeks 4-7)

- `scene.create`, `scene.open`, `scene.save`
- `node.create`, `node.delete`, `node.reparent`
- `node.set_property` (simple types only: `bool`, `int`, `float`, `String`, `Vector2/3`, `Color`)
- `resource.search`, `resource.load`, `resource.assign`
- `script.create`, `script.read`, `script.attach`
- undo grouping where supported
- readiness checks and better mutation errors

**Deferred to Phase 3:**
- `node.rename` (requires UID and reference fixup considerations)
- `node.set_property` for complex types (`Resource` refs, `NodePath`, `Array`, `Dictionary`)
- `script.patch` (GDScript-aware patching — research item)

Exit criteria:

- the server can create and modify small Godot projects safely
- write operations are not flaky under normal editor use

### Phase 3: Godot-native depth (Weeks 7-10)

- `signal.*`
- `autoload.*`
- `input_map.*`
- `uid.*`
- `build.list_presets`
- `build.export`
- `editor.screenshot`
- `batch.execute`
- multi-instance support

Exit criteria:

- the server feels like a mature Godot tool

### Phase 4: Hardening and launch (Weeks 10-12)

- polished install flow
- full docs
- compatibility matrix
- telemetry and diagnostics
- CI coverage
- release packaging and launch materials

Exit criteria:

- a new user can install it, connect it, and complete common workflows without repo archaeology

### Phase 5: Advanced tooling (Post-launch)

- richer shader and material workflows
- particle and VFX tooling
- camera rig helpers and capture workflows
- lightweight procedural mesh and CSG helpers
- richer performance inspection
- community-requested extensions
- possible test-framework integrations

After the core product is stable, growth should be driven by real Godot community demand rather than breadth for its own sake.

---

## 12. Positioning and Differentiation

This should be positioned as:

- **a cutting-edge, mature, fully open-source MCP server for Godot**

The most credible differentiators are:

- persistent editor integration
- multi-instance routing
- rich read resources
- real write workflows
- tests
- CI
- docs
- operational discipline shaped by years of real MCP maintenance
- usability work driven by community feedback
- a Godot-native tool surface instead of a thin command bridge

That is already enough to win.

### 12.1 Competitive positioning vs existing godot-mcp

The existing `godot-mcp` project is a thin bridge: it exposes a handful of editor commands over MCP but lacks persistent connections, session management, structured error handling, undo integration, resource-based reads, or a test suite. It is closer to a proof-of-concept than a production tool.

**Godot MCP Studio** occupies a different tier:

- **Architecture:** persistent editor plugin with WebSocket connection, session routing, job management, and lifecycle handling — not one-shot command relay.
- **Tool surface:** ~80+ Godot-native tools organized by domain vs a flat list of generic commands.
- **Reliability:** readiness gating, reconnect handling, undo integration, and structured error responses vs fire-and-hope.
- **Distribution:** standalone binary (PyInstaller) — no Python environment required for end users.
- **Quality bar:** unit, integration, contract, and e2e tests; CI; docs; compatibility matrix.

The positioning is not "better godot-mcp." It is "what a production-grade Godot MCP should look like." The existing project validates demand; this project delivers on it.

---

## 13. Community and Long-Term Growth

The long-term strategy should stay rooted in the Godot community.

- prioritize the workflows users actually ask for
- harden core editing workflows before chasing novelty
- document contributor paths clearly
- maintain a visible compatibility matrix across Godot versions
- design extension points only after the core tool surface is stable
- use community feedback to drive usability work, naming, defaults, and docs

This project should grow the same way good developer tools grow:

- by becoming more useful, more reliable, and easier to contribute to over time

---

## 14. Naming Strategy

The name should optimize for three things at once:

- search relevance for "Godot MCP"
- distinct identity from the existing `godot-mcp` project
- room to grow into a serious long-term tool, not a throwaway repo name

### 14.1 Recommendation

Do **not** use the bare canonical project name `godot-mcp` if another active project is already identified by that name.

You can still rank for the same searches by making the exact phrase "Godot MCP" part of:

- the repo name
- the package name
- the README title
- the GitHub description
- the website title and H1

The cleanest strategy is:

- pick a distinct brand
- attach a highly searchable descriptive suffix

Example:

- Product name: **Forge**
- Repo/package/display name: **Forge Godot MCP**
- GitHub description: **Production-grade Godot MCP server with persistent editor integration**

That gives you search relevance without looking like a clone or causing name confusion.

### 14.2 Best name patterns

These are the strongest options in descending order of practicality.

#### Option A: Brand + exact keyword

This is the best balance.

- `forge-godot-mcp`
- `anvil-godot-mcp`
- `ember-godot-mcp`
- `arc-godot-mcp`

Why this works:

- strong SEO because `godot-mcp` is in the repo/package name
- avoids direct naming collision
- gives the project a real brand

#### Option B: Exact keyword + clarifier

This is more utilitarian and very SEO-friendly.

- `godot-mcp-server`
- `godot-editor-mcp`
- `godot-mcp-toolkit`
- `godot-mcp-studio`

Why this works:

- very obvious in search
- easy to understand immediately
- less brandable than Option A

#### Option C: Brand-first public name, keyword in subtitle

This is the cleanest branding but the weakest SEO unless the metadata is disciplined.

- `Forge`
- subtitle: `A production-grade Godot MCP server`

Why this works:

- best long-term brand
- worse discoverability unless every page and package includes "Godot MCP"

### 14.3 My recommendation

If you want the most straightforward descriptive option, I think your instinct is good:

- **Repo:** `godot-mcp-studio`
- **Display name:** `Godot MCP Studio`

Why this is strong:

- it is extremely clear in search results
- it keeps the exact `godot-mcp` keyword string
- it feels more like a product than `godot-mcp-server`
- it avoids stepping directly on the existing bare `godot-mcp` identity

If you want a stronger brand later, you can still brand the site and docs while keeping the repo name descriptive.

### 14.4 Should you call it `godot-mcp` anyway?

Technically, you can use the phrase in many places. Strategically, I would not make the bare exact string your main identity.

Reasons:

- it creates immediate confusion with the existing project
- it weakens your distinct project identity
- it makes the project easy to misread as a continuation or replacement fight even if the implementation is fully new
- package and marketplace naming collisions become annoying fast

Use `Godot MCP` as a keyword, not as your only identity.
