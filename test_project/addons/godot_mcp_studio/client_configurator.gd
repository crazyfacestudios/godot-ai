@tool
class_name McpClientConfigurator
extends RefCounted

## Configures MCP clients (Claude Code, Antigravity, etc.) to connect to
## the Godot MCP Studio server.

enum ClientType { CLAUDE_CODE, ANTIGRAVITY }
enum ConfigStatus { NOT_CONFIGURED, CONFIGURED, ERROR }

const SERVER_NAME := "godot-mcp-studio"


## Configure a specific client. Returns a result dict with status and message.
static func configure(client: ClientType) -> Dictionary:
	match client:
		ClientType.CLAUDE_CODE:
			return _configure_claude_code()
		ClientType.ANTIGRAVITY:
			return _configure_antigravity()
	return {"status": "error", "message": "Unknown client type"}


## Check if a client is already configured.
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


## Get the Python command that launches the server.
## Checks: installed command → venv python → system python.
static func _get_server_command() -> Array[String]:
	var output: Array = []

	# 1. Check if godot-mcp-studio is available as a system command
	var exit_code := OS.execute("which", ["godot-mcp-studio"], output, true)
	if exit_code == 0 and output.size() > 0:
		var cmd_path: String = output[0].strip_edges()
		if not cmd_path.is_empty():
			return [cmd_path]

	# 2. Look for a .venv relative to the Godot project or repo root
	var venv_python := _find_venv_python()
	if not venv_python.is_empty():
		return [venv_python, "-m", "godot_mcp_studio"]

	# 3. Fall back to system python
	return ["python3", "-m", "godot_mcp_studio"]


## Walk up from the Godot project directory looking for .venv/bin/python.
static func _find_venv_python() -> String:
	var project_dir := ProjectSettings.globalize_path("res://")
	var dir := project_dir
	for i in 5:  # Walk up at most 5 levels
		var venv_path := dir.path_join(".venv/bin/python")
		if FileAccess.file_exists(venv_path):
			return venv_path
		var parent := dir.get_base_dir()
		if parent == dir:
			break
		dir = parent
	return ""


# --- Claude Code ---

static func _configure_claude_code() -> Dictionary:
	var cmd_parts := _get_server_command()

	# Use `claude mcp add` CLI to register
	var args: Array[String] = ["mcp", "add", "--scope", "user", "--transport", "stdio", SERVER_NAME, "--"]
	args.append_array(cmd_parts)

	var output: Array = []
	var exit_code := OS.execute("claude", args, output, true)

	if exit_code == 0:
		return {"status": "ok", "message": "Claude Code configured successfully"}
	else:
		var err_msg: String = output[0].strip_edges() if output.size() > 0 else "Unknown error"
		return {"status": "error", "message": "Failed to configure Claude Code: %s" % err_msg}


static func _check_claude_code() -> ConfigStatus:
	# Check if claude CLI is available and server is registered
	var output: Array = []
	var exit_code := OS.execute("claude", ["mcp", "list"], output, true)
	if exit_code != 0:
		return ConfigStatus.NOT_CONFIGURED

	var output_text: String = output[0] if output.size() > 0 else ""
	if output_text.find(SERVER_NAME) >= 0:
		return ConfigStatus.CONFIGURED
	return ConfigStatus.NOT_CONFIGURED


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
	var cmd_parts := _get_server_command()

	# Build the server entry
	var server_entry := {}
	if cmd_parts.size() == 1:
		server_entry = {"command": cmd_parts[0], "args": [], "type": "stdio"}
	else:
		server_entry = {"command": cmd_parts[0], "args": cmd_parts.slice(1), "type": "stdio"}

	# Read existing config or start fresh
	var config := {"mcpServers": {}}
	if FileAccess.file_exists(config_path):
		var file := FileAccess.open(config_path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				config = parsed
				if not config.has("mcpServers"):
					config["mcpServers"] = {}

	config["mcpServers"][SERVER_NAME] = server_entry

	# Ensure directory exists
	var dir_path := config_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Write config
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		return {"status": "error", "message": "Cannot write to %s" % config_path}
	file.store_string(JSON.stringify(config, "\t"))
	file.close()

	return {"status": "ok", "message": "Antigravity configured at %s" % config_path}


static func _check_antigravity() -> ConfigStatus:
	var config_path := _get_antigravity_config_path()
	if not FileAccess.file_exists(config_path):
		return ConfigStatus.NOT_CONFIGURED

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return ConfigStatus.NOT_CONFIGURED

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		var servers: Dictionary = parsed.get("mcpServers", {})
		if servers.has(SERVER_NAME):
			return ConfigStatus.CONFIGURED
	return ConfigStatus.NOT_CONFIGURED


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
