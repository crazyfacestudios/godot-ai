@tool
class_name McpClientConfigurator
extends RefCounted

## Configures MCP clients (Claude Code, Antigravity, etc.) to connect to
## the Godot MCP Studio server.

enum ClientType { CLAUDE_CODE, ANTIGRAVITY }
enum ConfigStatus { NOT_CONFIGURED, CONFIGURED, ERROR }

const SERVER_NAME := "godot-mcp-studio"
const SERVER_HTTP_URL := "http://127.0.0.1:8000/mcp"


## Configure a specific client. Always writes the current correct command,
## even if already configured (self-heals bad configs).
static func configure(client: ClientType) -> Dictionary:
	match client:
		ClientType.CLAUDE_CODE:
			return _configure_claude_code()
		ClientType.ANTIGRAVITY:
			return _configure_antigravity()
	return {"status": "error", "message": "Unknown client type"}


## Check if a client is configured with the correct server command.
static func check_status(client: ClientType) -> ConfigStatus:
	match client:
		ClientType.CLAUDE_CODE:
			return _check_claude_code()
		ClientType.ANTIGRAVITY:
			return _check_antigravity()
	return ConfigStatus.NOT_CONFIGURED


## Remove configuration for a specific client.
static func remove(client: ClientType) -> Dictionary:
	match client:
		ClientType.CLAUDE_CODE:
			return _remove_claude_code()
		ClientType.ANTIGRAVITY:
			return _remove_antigravity()
	return {"status": "error", "message": "Unknown client type"}


# --- Server command discovery ---

## Get the absolute path to the server command.
## Checks: well-known install locations → which → venv python → system python.
static func _get_server_command() -> Array[String]:
	# 1. Check well-known install paths directly (works even in sandboxed apps)
	var home := OS.get_environment("HOME")
	for bin_path in [
		home.path_join(".local/bin/godot-mcp-studio"),
		"/usr/local/bin/godot-mcp-studio",
		"/opt/homebrew/bin/godot-mcp-studio",
	]:
		if FileAccess.file_exists(bin_path):
			return [bin_path]

	# 2. Try which (may not work in sandboxed environments)
	var output: Array = []
	var exit_code := OS.execute("which", ["godot-mcp-studio"], output, true)
	if exit_code == 0 and output.size() > 0:
		var cmd_path: String = output[0].strip_edges()
		if not cmd_path.is_empty():
			return [cmd_path]

	# 3. Look for a .venv relative to the Godot project or repo root
	var venv_python := _find_venv_python()
	if not venv_python.is_empty():
		return [venv_python, "-m", "godot_mcp_studio"]

	# 4. Fall back to system python (least likely to work)
	return ["python3", "-m", "godot_mcp_studio"]


## Walk up from the Godot project directory looking for .venv/bin/python.
static func _find_venv_python() -> String:
	var project_dir := ProjectSettings.globalize_path("res://")
	var dir := project_dir
	for i in 5:
		var venv_path := dir.path_join(".venv/bin/python")
		if FileAccess.file_exists(venv_path):
			return venv_path
		var parent := dir.get_base_dir()
		if parent == dir:
			break
		dir = parent
	return ""


## Get the expected command string for comparison.
static func _get_expected_command_str() -> String:
	var parts := _get_server_command()
	return " ".join(parts)


# --- Claude Code ---

static func _configure_claude_code() -> Dictionary:
	# Remove existing first to ensure clean state
	OS.execute("claude", ["mcp", "remove", SERVER_NAME], [], true)

	# Register with HTTP transport pointing at the shared server
	var args: Array[String] = ["mcp", "add", "--scope", "user", "--transport", "http", SERVER_NAME, SERVER_HTTP_URL]

	var output: Array = []
	var exit_code := OS.execute("claude", args, output, true)

	if exit_code == 0:
		return {"status": "ok", "message": "Claude Code configured (HTTP: %s)" % SERVER_HTTP_URL}
	var err_msg: String = output[0].strip_edges() if output.size() > 0 else "Unknown error"
	return {"status": "error", "message": "Failed to configure Claude Code: %s" % err_msg}


static func _check_claude_code() -> ConfigStatus:
	var output: Array = []
	var exit_code := OS.execute("claude", ["mcp", "list"], output, true)
	if exit_code != 0:
		return ConfigStatus.NOT_CONFIGURED

	var output_text: String = output[0] if output.size() > 0 else ""
	if output_text.find(SERVER_NAME) < 0:
		return ConfigStatus.NOT_CONFIGURED

	# Verify it's configured for HTTP, not stdio
	if output_text.find(SERVER_HTTP_URL) < 0 and output_text.find("http") < 0:
		return ConfigStatus.NOT_CONFIGURED

	return ConfigStatus.CONFIGURED


static func _remove_claude_code() -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute("claude", ["mcp", "remove", SERVER_NAME], output, true)
	if exit_code == 0:
		return {"status": "ok", "message": "Claude Code configuration removed"}
	var err_msg: String = output[0].strip_edges() if output.size() > 0 else "Unknown error"
	return {"status": "error", "message": "Failed to remove: %s" % err_msg}


# --- Antigravity ---

static func _get_antigravity_config_path() -> String:
	return OS.get_environment("HOME").path_join(".gemini/antigravity/mcp_config.json")


static func _configure_antigravity() -> Dictionary:
	var config_path := _get_antigravity_config_path()
	var server_entry := {"serverUrl": SERVER_HTTP_URL, "disabled": false}

	# Read existing config or start fresh
	var config := {"mcpServers": {}}
	if FileAccess.file_exists(config_path):
		var file := FileAccess.open(config_path, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			file.close()
			if not content.is_empty():
				var json := JSON.new()
				if json.parse(content) == OK and json.data is Dictionary:
					config = json.data
					if not config.has("mcpServers"):
						config["mcpServers"] = {}

	config["mcpServers"][SERVER_NAME] = server_entry

	var dir_path := config_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		return {"status": "error", "message": "Cannot write to %s" % config_path}
	file.store_string(JSON.stringify(config, "\t"))
	file.close()

	return {"status": "ok", "message": "Antigravity configured (HTTP: %s)" % SERVER_HTTP_URL}


static func _check_antigravity() -> ConfigStatus:
	var config_path := _get_antigravity_config_path()
	if not FileAccess.file_exists(config_path):
		return ConfigStatus.NOT_CONFIGURED

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return ConfigStatus.NOT_CONFIGURED
	var content := file.get_as_text()
	file.close()

	if content.is_empty():
		return ConfigStatus.NOT_CONFIGURED

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_warning("MCP | Antigravity config parse error: %s (at line %d)" % [json.get_error_message(), json.get_error_line()])
		return ConfigStatus.NOT_CONFIGURED
	var parsed = json.data

	if not (parsed is Dictionary):
		return ConfigStatus.NOT_CONFIGURED

	var servers: Dictionary = parsed.get("mcpServers", {})
	if not servers.has(SERVER_NAME):
		return ConfigStatus.NOT_CONFIGURED

	# Verify it's configured for HTTP
	var entry: Dictionary = servers[SERVER_NAME]
	var configured_url: String = entry.get("serverUrl", "")
	if configured_url != SERVER_HTTP_URL:
		return ConfigStatus.NOT_CONFIGURED

	return ConfigStatus.CONFIGURED


static func _remove_antigravity() -> Dictionary:
	var config_path := _get_antigravity_config_path()
	if not FileAccess.file_exists(config_path):
		return {"status": "ok", "message": "Not configured"}

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return {"status": "error", "message": "Cannot read config"}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary and parsed.has("mcpServers"):
		parsed["mcpServers"].erase(SERVER_NAME)
		file = FileAccess.open(config_path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(parsed, "\t"))
			file.close()
			return {"status": "ok", "message": "Antigravity configuration removed"}

	return {"status": "ok", "message": "Was not configured"}
