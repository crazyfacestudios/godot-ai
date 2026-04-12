@tool
class_name Connection
extends Node

## WebSocket transport to the Godot MCP Studio Python server.
## Only handles connect, reconnect, send, and receive.
## Command dispatch is owned by McpDispatcher.

const DEFAULT_URL := "ws://127.0.0.1:%d" % McpClientConfigurator.SERVER_WS_PORT
const RECONNECT_DELAYS: Array[float] = [1.0, 2.0, 4.0, 8.0, 10.0]

var _peer := WebSocketPeer.new()
var _url := DEFAULT_URL
var _connected := false
var _reconnect_attempt := 0
var _reconnect_timer := 0.0
var _session_id := ""

var dispatcher: McpDispatcher
var log_buffer: McpLogBuffer


func _ready() -> void:
	_session_id = _generate_session_id()
	_connect_to_server()


func _process(delta: float) -> void:
	_peer.poll()

	match _peer.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				_connected = true
				_reconnect_attempt = 0
				log_buffer.log("connected to server")
				_send_handshake()

			while _peer.get_available_packet_count() > 0:
				var raw := _peer.get_packet().get_string_from_utf8()
				_handle_message(raw)

			# Let dispatcher process queued commands, send responses
			if dispatcher:
				for response in dispatcher.tick():
					_send_json(response)

		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				var code := _peer.get_close_code()
				log_buffer.log("disconnected (code %d)" % code)
			_reconnect_timer -= delta
			if _reconnect_timer <= 0.0:
				_attempt_reconnect()

		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CONNECTING:
			pass


var is_connected: bool:
	get: return _connected


func disconnect_from_server() -> void:
	if _connected:
		_peer.close(1000, "Plugin unloading")
		_connected = false


func _connect_to_server() -> void:
	var err := _peer.connect_to_url(_url)
	if err != OK:
		log_buffer.log("failed to initiate connection (error %d)" % err)


func _attempt_reconnect() -> void:
	var delay_idx := mini(_reconnect_attempt, RECONNECT_DELAYS.size() - 1)
	var delay := RECONNECT_DELAYS[delay_idx]
	_reconnect_attempt += 1
	_reconnect_timer = delay
	log_buffer.log("reconnecting in %.0fs (attempt %d)" % [delay, _reconnect_attempt])
	_peer = WebSocketPeer.new()
	_connect_to_server()


func _send_handshake() -> void:
	_send_json({
		"type": "handshake",
		"session_id": _session_id,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"project_path": ProjectSettings.globalize_path("res://"),
		"plugin_version": "0.0.1",
		"protocol_version": 1,
	})


func _handle_message(raw: String) -> void:
	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_warning("MCP: failed to parse message: %s" % raw)
		return
	if parsed is Dictionary and parsed.has("request_id") and parsed.has("command"):
		if dispatcher:
			dispatcher.enqueue(parsed)


func _send_json(data: Dictionary) -> void:
	if _connected:
		_peer.send_text(JSON.stringify(data))


func _generate_session_id() -> String:
	var bytes := PackedByteArray()
	for i in 16:
		bytes.append(randi() % 256)
	return bytes.hex_encode()
