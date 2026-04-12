"""Godot MCP Studio — production-grade Godot MCP server."""

import argparse

__version__ = "0.0.1"


def main():
    parser = argparse.ArgumentParser(description="Godot MCP Studio server")
    parser.add_argument(
        "--transport",
        choices=["stdio", "sse", "streamable-http"],
        default="stdio",
        help="MCP transport (default: stdio)",
    )
    parser.add_argument(
        "--port", type=int, default=8000, help="HTTP port for sse/streamable-http (default: 8000)"
    )
    parser.add_argument(
        "--ws-port", type=int, default=9500, help="WebSocket port for Godot plugin (default: 9500)"
    )
    args = parser.parse_args()

    from godot_mcp_studio.server import create_server

    server = create_server(ws_port=args.ws_port)

    transport_kwargs = {}
    if args.transport in ("sse", "streamable-http"):
        transport_kwargs["port"] = args.port

    server.run(transport=args.transport, **transport_kwargs)
