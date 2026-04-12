@tool
extends McpTestSuite

## Tests for EditorHandler — editor state, selection, and logs.

var _handler: EditorHandler


func suite_name() -> String:
	return "editor"


func suite_setup(ctx: Dictionary) -> void:
	var log_buffer: McpLogBuffer = ctx.get("log_buffer")
	if log_buffer == null:
		log_buffer = McpLogBuffer.new()
	_handler = EditorHandler.new(log_buffer)


# ----- get_editor_state -----

func test_editor_state_has_version() -> void:
	var result := _handler.get_editor_state({})
	assert_has_key(result, "data")
	assert_has_key(result.data, "godot_version")
	assert_ne(result.data.godot_version, "", "Version should not be empty")


func test_editor_state_has_project_name() -> void:
	var result := _handler.get_editor_state({})
	assert_has_key(result.data, "project_name")


func test_editor_state_has_scene() -> void:
	var result := _handler.get_editor_state({})
	assert_has_key(result.data, "current_scene")
	assert_contains(result.data.current_scene, "main.tscn", "Should have main.tscn open")


func test_editor_state_has_play_status() -> void:
	var result := _handler.get_editor_state({})
	assert_has_key(result.data, "is_playing")


# ----- get_selection -----

func test_selection_returns_data() -> void:
	var result := _handler.get_selection({})
	assert_has_key(result, "data")
	assert_has_key(result.data, "selected_paths")
	assert_has_key(result.data, "count")
	assert_true(result.data.selected_paths is Array, "selected_paths should be Array")


# ----- get_logs -----

func test_logs_returns_lines() -> void:
	var result := _handler.get_logs({"count": 10})
	assert_has_key(result, "data")
	assert_has_key(result.data, "lines")
	assert_has_key(result.data, "total_count")
	assert_has_key(result.data, "returned_count")


func test_logs_respects_count() -> void:
	var result := _handler.get_logs({"count": 1})
	assert_true(result.data.returned_count <= 1, "Should return at most 1 line")
