@tool
extends EditorPlugin

var _connection: Connection
var _dispatcher: McpDispatcher
var _log_buffer: McpLogBuffer
var _dock: McpDock
var _server_pid := -1
var _handlers: Array = []  # prevent GC of RefCounted handlers


func _enter_tree() -> void:
	_start_server()

	_log_buffer = McpLogBuffer.new()
	_dispatcher = McpDispatcher.new(_log_buffer)

	var editor_handler := EditorHandler.new(_log_buffer)
	var scene_handler := SceneHandler.new()
	var node_handler := NodeHandler.new(get_undo_redo())
	var client_handler := ClientHandler.new()
	var test_handler := TestHandler.new(get_undo_redo(), _log_buffer)
	_handlers = [editor_handler, scene_handler, node_handler, client_handler, test_handler]

	_dispatcher.register("get_editor_state", editor_handler.get_editor_state)
	_dispatcher.register("get_scene_tree", scene_handler.get_scene_tree)
	_dispatcher.register("get_open_scenes", scene_handler.get_open_scenes)
	_dispatcher.register("find_nodes", scene_handler.find_nodes)
	_dispatcher.register("get_selection", editor_handler.get_selection)
	_dispatcher.register("create_node", node_handler.create_node)
	_dispatcher.register("get_node_properties", node_handler.get_node_properties)
	_dispatcher.register("get_children", node_handler.get_children)
	_dispatcher.register("get_groups", node_handler.get_groups)
	_dispatcher.register("get_logs", editor_handler.get_logs)
	_dispatcher.register("configure_client", client_handler.configure_client)
	_dispatcher.register("check_client_status", client_handler.check_client_status)
	_dispatcher.register("run_tests", test_handler.run_tests)
	_dispatcher.register("get_test_results", test_handler.get_test_results)

	_connection = Connection.new()
	_connection.log_buffer = _log_buffer
	_connection.dispatcher = _dispatcher
	add_child(_connection)

	# Dock panel
	_dock = McpDock.new()
	_dock.name = "Godot AI"
	_dock.setup(_connection, _log_buffer)
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)

	_log_buffer.log("plugin loaded")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if _connection:
		_connection.disconnect_from_server()
		_connection.queue_free()
		_connection = null
	_stop_server()
	print("MCP | plugin unloaded")


func _start_server() -> void:
	## Kill any stale listener on our HTTP port (leftover from crash,
	## old install, or a different server like godot-mcp-studio).
	_kill_listener_on_port(McpClientConfigurator.SERVER_HTTP_PORT)

	var server_cmd := McpClientConfigurator.get_server_command()
	if server_cmd.is_empty():
		push_warning("MCP | could not find server command")
		return

	var cmd: String = server_cmd[0]
	var args: Array[String] = []
	args.assign(server_cmd.slice(1))
	args.append_array(["--transport", "streamable-http", "--port", str(McpClientConfigurator.SERVER_HTTP_PORT)])

	_server_pid = OS.create_process(cmd, args)
	if _server_pid > 0:
		print("MCP | started server (PID %d): %s %s" % [_server_pid, cmd, " ".join(args)])
	else:
		push_warning("MCP | failed to start server")


func _kill_listener_on_port(port: int) -> void:
	var output: Array = []
	## -sTCP:LISTEN finds only the server process, not clients connected to it
	var exit_code := OS.execute("lsof", ["-ti:%d" % port, "-sTCP:LISTEN"], output, true)
	if exit_code != 0 or output.is_empty():
		return
	var pids_str: String = output[0].strip_edges()
	if pids_str.is_empty():
		return
	for pid_str in pids_str.split("\n"):
		var pid := pid_str.strip_edges().to_int()
		if pid > 0:
			OS.kill(pid)
			print("MCP | killed stale process on port %d (PID %d)" % [port, pid])


func _stop_server() -> void:
	if _server_pid > 0:
		OS.kill(_server_pid)
		print("MCP | stopped server (PID %d)" % _server_pid)
		_server_pid = -1
