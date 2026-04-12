"""Session registry — tracks connected Godot editor instances."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass
class Session:
    """A connected Godot editor session."""

    session_id: str
    godot_version: str
    project_path: str
    plugin_version: str
    protocol_version: int = 1
    current_scene: str = ""
    play_state: str = "stopped"
    connected_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        return {
            "session_id": self.session_id,
            "godot_version": self.godot_version,
            "project_path": self.project_path,
            "plugin_version": self.plugin_version,
            "protocol_version": self.protocol_version,
            "current_scene": self.current_scene,
            "play_state": self.play_state,
            "connected_at": self.connected_at.isoformat(),
        }


class SessionRegistry:
    """Tracks all connected Godot editor sessions."""

    def __init__(self):
        self._sessions: dict[str, Session] = {}
        self._active_session_id: str | None = None

    def register(self, session: Session) -> None:
        self._sessions[session.session_id] = session
        if self._active_session_id is None:
            self._active_session_id = session.session_id

    def unregister(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)
        if self._active_session_id == session_id:
            self._active_session_id = next(iter(self._sessions), None)

    def get(self, session_id: str) -> Session | None:
        return self._sessions.get(session_id)

    def get_active(self) -> Session | None:
        if self._active_session_id:
            return self._sessions.get(self._active_session_id)
        return None

    def set_active(self, session_id: str) -> None:
        if session_id not in self._sessions:
            raise KeyError(f"Session {session_id} not found")
        self._active_session_id = session_id

    def list_all(self) -> list[Session]:
        return list(self._sessions.values())

    @property
    def active_session_id(self) -> str | None:
        return self._active_session_id

    def __len__(self) -> int:
        return len(self._sessions)
