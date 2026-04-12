# CLAUDE.md — Godot AI

## What this project is

A production-grade MCP server for Godot. Python server (FastMCP v3) communicates over WebSocket with a GDScript editor plugin. AI clients call MCP tools → Python routes commands → Godot plugin executes against the editor API → results flow back.

## Architecture

```
AI Client → MCP (stdio/sse) → Python FastMCP server → WebSocket (port 9500) → Godot EditorPlugin
```

- **Python server**: `src/godot_ai/` — FastMCP v3, async, lifespan manages WebSocket server
- **GDScript plugin**: `plugin/addons/godot_ai/` — canonical source; copied into `test_project/addons/` for testing
- **Protocol**: JSON over WebSocket. Request/response with `request_id` correlation. Handshake on connect.
- **Session model**: Multiple Godot editors can connect. Tools route through active session.

## Key conventions

- **GDScript plugin is the canonical copy** in `plugin/`. After editing, copy to `test_project/addons/godot_ai/` for testing.
- **Error codes**: Defined in `protocol/errors.py` (Python) and as constants at the top of `connection.gd` (GDScript). Keep in sync.
- **Tools return `dict`**: `GodotClient.send()` returns `response.data` (a dict) or raises `GodotCommandError`. Tools just `return await app.client.send(...)`.
- **Plugin runs on main thread**: All GDScript executes in `_process()` with a 4ms frame budget. Never block. Use `call_deferred` for scene tree mutations.
- **Scene paths are clean**: `/Main/Camera3D` format, not raw Godot internal paths. Use `_scene_path(node, scene_root)` in GDScript.
- **MCP logging**: Plugin prints `MCP | [recv] command(params)` / `MCP | [send] command -> ok` to Godot console. Controlled by `mcp_logging` var.

## Dev workflow

```bash
cd ~/Downloads/godot-ai
source .venv/bin/activate
pytest -v                    # run tests
ruff check src/ tests/       # lint
ruff format src/ tests/      # format

# Start server for testing (stays up)
python -m godot_ai --transport sse

# Start server for Claude Desktop / Claude Code (stdio)
python -m godot_ai
```

## Testing against Godot

1. Start server: `python -m godot_ai --transport sse`
2. Open `test_project/` in Godot, enable plugin in Project Settings > Plugins
3. Open a scene (e.g. `main.tscn`)
4. Server logs should show `Session connected`

## Client configuration

The plugin can configure MCP clients via `client_configurator.gd`:
- **Claude Code**: uses `claude mcp add` CLI to register the server
- **Antigravity**: writes directly to `~/.gemini/antigravity/mcp_config.json`

MCP tools `client_configure` and `client_status` expose this to AI clients.

## Adding a new tool

1. Add a GDScript handler in `connection.gd`: `_handle_<name>(params) -> Dictionary`
2. Add the command string to the `match` block in `_dispatch_command`
3. Add a Python tool in `tools/<domain>.py` that calls `app.client.send("<command>", params)`
4. Register the tool in `server.py` if it's a new module
5. Copy updated plugin files to `test_project/addons/godot_ai/`

## What NOT to do

- Don't call `EditorInterface` methods from WebSocket callbacks — always queue
- Don't cache `get_edited_scene_root()` across frames — it changes on scene switch
- Don't use `pop_front()` on arrays in hot paths — use index + slice
- Don't add error handling in individual tools — `GodotClient.send()` raises on errors
- Don't use Python-style `"""docstrings"""` in GDScript — use `##` comments
