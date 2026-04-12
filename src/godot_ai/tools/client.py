"""MCP tools for configuring AI clients to use Godot MCP Studio."""

from __future__ import annotations

from fastmcp import Context, FastMCP


def register_client_tools(mcp: FastMCP) -> None:
    @mcp.tool()
    async def client_configure(ctx: Context, client: str) -> dict:
        """Configure an AI client to connect to the Godot MCP Studio server.

        Writes the necessary MCP server configuration so the client knows
        how to launch and connect to this server.

        Args:
            client: The client to configure. Options: "claude_code", "antigravity".
        """
        app = ctx.lifespan_context
        return await app.client.send("configure_client", {"client": client})

    @mcp.tool()
    async def client_status(ctx: Context) -> dict:
        """Check which AI clients are configured to use Godot MCP Studio.

        Returns the configuration status of each supported client:
        "configured", "not_configured", or "error".
        """
        app = ctx.lifespan_context
        return await app.client.send("check_client_status")
