"""MCP tools for running GDScript tests inside the Godot editor."""

from __future__ import annotations

from fastmcp import Context, FastMCP


def register_testing_tools(mcp: FastMCP) -> None:
    @mcp.tool()
    async def run_tests(
        ctx: Context,
        suite: str = "",
        test_name: str = "",
    ) -> dict:
        """Run GDScript test suites inside the connected Godot editor.

        Discovers test_*.gd scripts in the project's res://tests/ directory,
        instantiates them, and runs all test_* methods. Returns structured
        pass/fail results.

        Args:
            suite: Run only the named suite (e.g. "scene", "node", "editor").
                   Empty runs all suites.
            test_name: Run only tests whose name contains this substring.
                       Empty runs all tests in the selected suite(s).
        """
        app = ctx.lifespan_context
        params = {}
        if suite:
            params["suite"] = suite
        if test_name:
            params["test_name"] = test_name
        return await app.client.send("run_tests", params)

    @mcp.tool()
    async def get_test_results(ctx: Context) -> dict:
        """Get results from the most recent test run.

        Returns the same structured results as run_tests, without
        re-executing. Useful for reviewing results after a run.
        """
        app = ctx.lifespan_context
        return await app.client.send("get_test_results")
