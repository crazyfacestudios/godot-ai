"""MCP tools for session management."""

from fastmcp import FastMCP

from godot_mcp_studio.sessions.registry import SessionRegistry


def register_session_tools(mcp: FastMCP, registry: SessionRegistry) -> None:
    @mcp.tool()
    def session_list() -> dict:
        """List all connected Godot editor sessions.

        Returns session metadata including Godot version, project path,
        and connection state for each connected editor instance.
        """
        sessions = registry.list_all()
        active_id = registry.active_session_id
        return {
            "sessions": [{**s.to_dict(), "is_active": s.session_id == active_id} for s in sessions],
            "count": len(sessions),
        }

    @mcp.tool()
    def session_activate(session_id: str) -> dict:
        """Set the active Godot editor session.

        Subsequent tool calls that don't specify a session_id will
        target this session.

        Args:
            session_id: The ID of the session to activate.
        """
        try:
            registry.set_active(session_id)
            return {"status": "ok", "active_session_id": session_id}
        except KeyError:
            return {"status": "error", "message": f"Session {session_id} not found"}
