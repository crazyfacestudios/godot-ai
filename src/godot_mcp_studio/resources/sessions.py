"""MCP resources for session state."""

from fastmcp import FastMCP

from godot_mcp_studio.sessions.registry import SessionRegistry


def register_session_resources(mcp: FastMCP, registry: SessionRegistry) -> None:
    @mcp.resource("godot://sessions")
    def get_sessions() -> dict:
        """All connected Godot editor sessions and their metadata."""
        sessions = registry.list_all()
        active_id = registry.active_session_id
        return {
            "sessions": [{**s.to_dict(), "is_active": s.session_id == active_id} for s in sessions],
            "count": len(sessions),
        }
