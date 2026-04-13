@tool
extends McpTestSuite

## Tests for ResourceHandler — resource search, load, and assign.

var _handler: ResourceHandler
var _undo_redo: EditorUndoRedoManager


func suite_name() -> String:
	return "resource"


func suite_setup(ctx: Dictionary) -> void:
	_undo_redo = ctx.get("undo_redo")
	_handler = ResourceHandler.new(_undo_redo)


# ----- search_resources -----

func test_search_resources_missing_filters() -> void:
	var result := _handler.search_resources({})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_search_resources_by_path() -> void:
	var result := _handler.search_resources({"path": "main"})
	assert_has_key(result, "data")
	assert_has_key(result.data, "resources")
	assert_has_key(result.data, "count")
	## Should find at least main.tscn
	assert_gt(result.data.count, 0, "Should find at least one resource matching 'main'")


func test_search_resources_by_type() -> void:
	var result := _handler.search_resources({"type": "PackedScene"})
	assert_has_key(result, "data")
	assert_gt(result.data.count, 0, "Should find at least one PackedScene")
	for res: Dictionary in result.data.resources:
		assert_eq(res.type, "PackedScene")


# ----- load_resource -----

func test_load_resource_missing_path() -> void:
	var result := _handler.load_resource({})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_load_resource_invalid_prefix() -> void:
	var result := _handler.load_resource({"path": "/tmp/bad.tres"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_load_resource_not_found() -> void:
	var result := _handler.load_resource({"path": "res://nonexistent.tres"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_load_resource_scene() -> void:
	var result := _handler.load_resource({"path": "res://main.tscn"})
	assert_has_key(result, "data")
	assert_eq(result.data.type, "PackedScene")
	assert_has_key(result.data, "properties")
	assert_has_key(result.data, "property_count")


# ----- assign_resource -----

func test_assign_resource_missing_path() -> void:
	var result := _handler.assign_resource({"property": "mesh", "resource_path": "res://foo.tres"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_assign_resource_missing_property() -> void:
	var result := _handler.assign_resource({"path": "/Main/Camera3D", "resource_path": "res://foo.tres"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_assign_resource_missing_resource_path() -> void:
	var result := _handler.assign_resource({"path": "/Main/Camera3D", "property": "mesh"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_assign_resource_node_not_found() -> void:
	var result := _handler.assign_resource({
		"path": "/Main/DoesNotExist",
		"property": "mesh",
		"resource_path": "res://main.tscn",
	})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_assign_resource_property_not_found() -> void:
	var result := _handler.assign_resource({
		"path": "/Main/Camera3D",
		"property": "nonexistent_property_xyz",
		"resource_path": "res://main.tscn",
	})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_assign_resource_resource_not_found() -> void:
	var result := _handler.assign_resource({
		"path": "/Main/Camera3D",
		"property": "environment",
		"resource_path": "res://nonexistent.tres",
	})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)
