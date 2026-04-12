"""MCP tools for editor state inspection."""

from __future__ import annotations

from fastmcp import Context, FastMCP


def register_editor_tools(mcp: FastMCP) -> None:
    @mcp.tool()
    async def editor_state(ctx: Context) -> dict:
        """Get the current Godot editor state.

        Returns Godot version, project name, current scene path,
        and whether the project is currently playing.
        """
        app = ctx.lifespan_context
        return await app.client.send("get_editor_state")

    @mcp.tool()
    async def editor_selection_get(ctx: Context) -> dict:
        """Get the currently selected nodes in the Godot editor.

        Returns a list of selected node paths.
        """
        app = ctx.lifespan_context
        return await app.client.send("get_selection")

    @mcp.tool()
    async def logs_read(ctx: Context, count: int = 50) -> dict:
        """Read recent log lines from the Godot editor console.

        Returns the most recent log lines captured by the MCP plugin,
        including MCP command traffic when logging is enabled.

        Args:
            count: Number of recent lines to return. Default 50.
        """
        app = ctx.lifespan_context
        return await app.client.send("get_logs", {"count": count})
