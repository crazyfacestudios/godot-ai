# Godot MCP Studio

Production-grade MCP server for Godot with persistent editor integration.

> **Status: Early development.** Core tools working, more coming.

## How it works

```
AI Client (Claude Code, Antigravity, etc.)
   │ MCP (HTTP)
   ▼
Python Server (FastMCP) ← started by the Godot plugin
   │ WebSocket
   ▼
Godot Editor Plugin (GDScript)
   │ EditorInterface + SceneTree APIs
   ▼
Godot Editor
```

The Godot plugin starts a shared Python server. MCP clients connect via HTTP. The plugin connects via WebSocket. All clients share the same server and see the same Godot sessions.

## Quick start

### 1. Install the server

```bash
# With uv (recommended)
uv tool install /path/to/godot-mcp-studio

# Or with pip
pip install -e /path/to/godot-mcp-studio
```

### 2. Install the plugin

Copy `plugin/addons/godot_mcp_studio/` into your Godot project's `addons/` folder.

### 3. Enable the plugin

In Godot: **Project > Project Settings > Plugins** — enable "Godot MCP Studio".

The plugin will:
- Start the MCP server automatically
- Connect to the server via WebSocket
- Auto-configure Claude Code and Antigravity (if installed)

### 4. Use from an AI client

The plugin auto-configures supported clients on first enable. If you need to configure manually:

**Claude Code:**
```bash
claude mcp add --scope user --transport http godot-mcp-studio http://127.0.0.1:8000/mcp
```

**Antigravity** (`~/.gemini/antigravity/mcp_config.json`):
```json
{
  "mcpServers": {
    "godot-mcp-studio": {
      "serverUrl": "http://127.0.0.1:8000/mcp",
      "disabled": false
    }
  }
}
```

## Working tools

| Tool | Description |
|------|-------------|
| `session_list` | List connected Godot editor sessions |
| `session_activate` | Set the active session for multi-editor routing |
| `editor_state` | Get Godot version, project name, current scene, play state |
| `editor_selection_get` | Get currently selected nodes |
| `scene_get_hierarchy` | Read the full scene tree with node types and paths |
| `node_create` | Create nodes by type with optional name and parent path |
| `logs_read` | Read recent MCP command log from the Godot console |
| `client_configure` | Configure an MCP client (Claude Code / Antigravity) |
| `client_status` | Check which clients are configured |

## Ports

| Port | Purpose |
|------|---------|
| 9500 | WebSocket — Godot plugin connects here |
| 8000 | HTTP — MCP clients connect here (`/mcp` endpoint) |

## Requirements

- Godot 4.3+ (4.4+ recommended, tested on 4.6.2)
- Python 3.11+
- FastMCP 3.x

## Development

```bash
# Setup
pip install -e ".[dev]"

# Run tests
pytest -v

# Lint
ruff check src/ tests/

# Start server manually (for testing without the plugin)
python -m godot_mcp_studio --transport streamable-http --port 8000
```

## License

TBD
