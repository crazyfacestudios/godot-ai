"""MCP tools for reading and writing text files in the Godot project."""

from __future__ import annotations

from fastmcp import Context, FastMCP

from godot_ai.handlers import filesystem as filesystem_handlers
from godot_ai.runtime.direct import DirectRuntime


def register_filesystem_tools(mcp: FastMCP) -> None:
    @mcp.tool()
    async def filesystem_read_text(ctx: Context, path: str) -> dict:
        """Read a text file from the Godot project.

        Returns the full file content, size, and line count.
        Works with any text file (scripts, configs, shaders, etc.).

        Args:
            path: File path starting with res:// (e.g. "res://project.godot").
        """
        runtime = DirectRuntime.from_context(ctx)
        return await filesystem_handlers.filesystem_read_text(runtime, path=path)

    @mcp.tool()
    async def filesystem_write_text(
        ctx: Context,
        path: str,
        content: str = "",
    ) -> dict:
        """Write a text file to the Godot project.

        Creates or overwrites the file at the given path and triggers
        a filesystem scan so the editor picks up changes. Parent
        directories are created automatically if needed.

        Args:
            path: File path starting with res:// (e.g. "res://data/config.json").
            content: Text content to write. Empty creates a blank file.
        """
        runtime = DirectRuntime.from_context(ctx)
        return await filesystem_handlers.filesystem_write_text(
            runtime,
            path=path,
            content=content,
        )

    @mcp.tool()
    async def import_reimport(ctx: Context, paths: list[str]) -> dict:
        """Force reimport of specific files in the Godot project.

        Triggers EditorFileSystem.update_file() for each path, which
        forces the editor to re-scan and reimport the files. Useful
        after modifying files outside the editor.

        Args:
            paths: List of file paths to reimport (e.g. ["res://textures/icon.png"]).
        """
        runtime = DirectRuntime.from_context(ctx)
        return await filesystem_handlers.import_reimport(runtime, paths=paths)
