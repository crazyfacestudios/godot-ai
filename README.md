# Godot MCP Studio

Production-grade Godot MCP server with persistent editor integration.

> **Status: Under construction.** This project is in early development.

## What is this?

Godot MCP Studio is an MCP server that connects AI assistants (Claude, Cursor, etc.) to the Godot editor through a persistent plugin. It exposes Godot-native tools for scene inspection, node manipulation, script management, and more.

## Architecture

```
AI Client (Claude Desktop, Cursor, etc.)
   │ MCP protocol
   ▼
Python MCP Server (FastMCP)
   │ WebSocket
   ▼
Godot Editor Plugin (GDScript)
   │ EditorInterface + SceneTree APIs
   ▼
Godot Editor
```

## Development

```bash
# Install dependencies
pip install -e ".[dev]"

# Run the server
python -m godot_mcp_studio

# Run tests
pytest

# Lint
ruff check src/ tests/
```

## License

TBD
