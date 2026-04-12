"""Godot MCP Studio — production-grade Godot MCP server."""

__version__ = "0.0.1"


def main():
    from godot_mcp_studio.server import create_server

    server = create_server()
    server.run()
