"""FastMCP server — the main entry point for Godot MCP Studio."""

from fastmcp import FastMCP

from godot_mcp_studio.resources.sessions import register_session_resources
from godot_mcp_studio.sessions.registry import SessionRegistry
from godot_mcp_studio.tools.session import register_session_tools


def create_server() -> FastMCP:
    mcp = FastMCP(
        "Godot MCP Studio",
        instructions="Production-grade Godot MCP server with persistent editor integration. "
        "Use session tools to manage connections to Godot editor instances.",
    )

    registry = SessionRegistry()

    register_session_tools(mcp, registry)
    register_session_resources(mcp, registry)

    return mcp
