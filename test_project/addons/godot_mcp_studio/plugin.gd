@tool
extends EditorPlugin

const CONNECTION = preload("res://addons/godot_mcp_studio/connection.gd")

var _connection: Connection


func _enter_tree() -> void:
	_connection = CONNECTION.new()
	add_child(_connection)
	print("Godot MCP Studio: plugin loaded")


func _exit_tree() -> void:
	if _connection:
		_connection.disconnect_from_server()
		_connection.queue_free()
		_connection = null
	print("Godot MCP Studio: plugin unloaded")
