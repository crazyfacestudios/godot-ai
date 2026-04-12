"""Typed async client for sending commands to the Godot editor plugin."""

from __future__ import annotations

from typing import Any

from godot_mcp_studio.protocol.envelope import CommandResponse
from godot_mcp_studio.protocol.errors import ErrorCode
from godot_mcp_studio.sessions.registry import SessionRegistry
from godot_mcp_studio.transport.websocket import GodotWebSocketServer


class GodotClient:
    """High-level client for interacting with connected Godot editors."""

    def __init__(self, ws_server: GodotWebSocketServer, registry: SessionRegistry):
        self.ws_server = ws_server
        self.registry = registry

    async def send(
        self,
        command: str,
        params: dict[str, Any] | None = None,
        session_id: str | None = None,
        timeout: float = 5.0,
    ) -> CommandResponse:
        """Send a command to a Godot session.

        If session_id is None, uses the active session.
        """
        if session_id is None:
            session = self.registry.get_active()
            if session is None:
                raise ConnectionError("No active Godot session")
            session_id = session.session_id

        if self.registry.get(session_id) is None:
            raise ConnectionError(
                f"Session {session_id} not found. Error code: {ErrorCode.SESSION_NOT_FOUND}"
            )

        return await self.ws_server.send_command(
            session_id=session_id,
            command=command,
            params=params,
            timeout=timeout,
        )
