@tool
extends McpTestSuite

## Tests for NodeHandler — node reads and creation.

var _handler: NodeHandler
var _undo_redo: EditorUndoRedoManager


func suite_name() -> String:
	return "node"


func suite_setup(ctx: Dictionary) -> void:
	_undo_redo = ctx.get("undo_redo")
	_handler = NodeHandler.new(_undo_redo)


# ----- get_children -----

func test_get_children_of_root() -> void:
	var result := _handler.get_children({"path": "/Main"})
	assert_has_key(result, "data")
	assert_has_key(result.data, "children")
	assert_gt(result.data.count, 0, "Main should have children")
	var names: Array[String] = []
	for child: Dictionary in result.data.children:
		names.append(child.name)
	assert_contains(names, "Camera3D")
	assert_contains(names, "World")


func test_get_children_of_world() -> void:
	var result := _handler.get_children({"path": "/Main/World"})
	assert_has_key(result, "data")
	assert_eq(result.data.count, 1, "World should have 1 child")
	assert_eq(result.data.children[0].name, "Ground")


func test_get_children_includes_metadata() -> void:
	var result := _handler.get_children({"path": "/Main"})
	var first: Dictionary = result.data.children[0]
	assert_has_key(first, "name")
	assert_has_key(first, "type")
	assert_has_key(first, "path")
	assert_has_key(first, "children_count")


func test_get_children_invalid_path() -> void:
	var result := _handler.get_children({"path": "/Main/DoesNotExist"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_get_children_missing_path() -> void:
	var result := _handler.get_children({})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


# ----- get_node_properties -----

func test_get_properties_camera() -> void:
	var result := _handler.get_node_properties({"path": "/Main/Camera3D"})
	assert_has_key(result, "data")
	assert_has_key(result.data, "properties")
	assert_eq(result.data.node_type, "Camera3D")
	## Camera3D should have "fov" among its properties
	var prop_names: Array[String] = []
	for prop: Dictionary in result.data.properties:
		prop_names.append(prop.name)
	assert_contains(prop_names, "fov", "Camera3D should have fov property")


func test_get_properties_has_value_and_type() -> void:
	var result := _handler.get_node_properties({"path": "/Main/Camera3D"})
	var fov_prop: Dictionary
	for prop: Dictionary in result.data.properties:
		if prop.name == "fov":
			fov_prop = prop
			break
	assert_has_key(fov_prop, "value")
	assert_has_key(fov_prop, "type")
	assert_eq(fov_prop.type, "float")
	assert_gt(fov_prop.value, 0, "FOV should be positive")


func test_get_properties_invalid_path() -> void:
	var result := _handler.get_node_properties({"path": "/Main/Nope"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_get_properties_missing_path() -> void:
	var result := _handler.get_node_properties({})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


# ----- get_groups -----

func test_get_groups_returns_array() -> void:
	var result := _handler.get_groups({"path": "/Main/Camera3D"})
	assert_has_key(result, "data")
	assert_has_key(result.data, "groups")
	assert_true(result.data.groups is Array, "groups should be an Array")


func test_get_groups_invalid_path() -> void:
	var result := _handler.get_groups({"path": "/Main/Missing"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


# ----- create_node -----

func test_create_node_basic() -> void:
	var result := _handler.create_node({
		"type": "Node3D",
		"name": "_McpTest",
		"parent_path": "/Main",
	})
	assert_has_key(result, "data")
	assert_true(str(result.data.name).begins_with("_McpTest"), "Name should start with _McpTest")
	assert_eq(result.data.type, "Node3D")
	assert_true(result.data.undoable, "Create should be undoable")
	## Clean up: remove the node directly (undo is unreliable across test runs)
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root:
		var node := scene_root.get_node_or_null(result.data.path.trim_prefix("/" + scene_root.name + "/"))
		if node:
			node.get_parent().remove_child(node)
			node.queue_free()


func test_create_node_invalid_type() -> void:
	var result := _handler.create_node({"type": "NotARealNodeType"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_create_node_missing_type() -> void:
	var result := _handler.create_node({})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)


func test_create_node_non_node_type() -> void:
	var result := _handler.create_node({"type": "Resource"})
	assert_is_error(result, McpErrorCodes.INVALID_PARAMS)
