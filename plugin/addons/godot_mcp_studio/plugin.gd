@tool
extends EditorPlugin

const CONNECTION = preload("res://addons/godot_mcp_studio/connection.gd")
const CONFIGURATOR = preload("res://addons/godot_mcp_studio/client_configurator.gd")

var _connection: Connection


func _enter_tree() -> void:
	_connection = CONNECTION.new()
	add_child(_connection)
	print("MCP | plugin loaded")
	_auto_configure_clients.call_deferred()


func _exit_tree() -> void:
	if _connection:
		_connection.disconnect_from_server()
		_connection.queue_free()
		_connection = null
	print("MCP | plugin unloaded")


func _auto_configure_clients() -> void:
	for client_info in [
		["claude_code", McpClientConfigurator.ClientType.CLAUDE_CODE, "Claude Code"],
		["antigravity", McpClientConfigurator.ClientType.ANTIGRAVITY, "Antigravity"],
	]:
		var client_type: McpClientConfigurator.ClientType = client_info[1]
		var display_name: String = client_info[2]

		var status := McpClientConfigurator.check_status(client_type)
		if status == McpClientConfigurator.ConfigStatus.CONFIGURED:
			print("MCP | %s: already configured" % display_name)
			continue

		print("MCP | %s: not configured, setting up..." % display_name)
		var result := McpClientConfigurator.configure(client_type)
		if result.get("status") == "ok":
			print("MCP | %s: %s" % [display_name, result.get("message", "configured")])
		else:
			print("MCP | %s: setup failed - %s" % [display_name, result.get("message", "unknown error")])
