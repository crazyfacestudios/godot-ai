@tool
class_name NodeHandler
extends RefCounted

## Handles node creation and manipulation.


func create_node(params: Dictionary) -> Dictionary:
	var node_type: String = params.get("type", "")
	var node_name: String = params.get("name", "")
	var parent_path: String = params.get("parent_path", "")

	if node_type.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Missing required param: type")

	if not ClassDB.class_exists(node_type):
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Unknown node type: %s" % node_type)
	if not ClassDB.is_parent_class(node_type, "Node"):
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "%s is not a Node type" % node_type)

	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return McpErrorCodes.make(McpErrorCodes.EDITOR_NOT_READY, "No scene open")

	var parent: Node = scene_root
	if not parent_path.is_empty():
		parent = ScenePath.resolve(parent_path, scene_root)
		if parent == null:
			return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Parent not found: %s" % parent_path)

	var new_node: Node = ClassDB.instantiate(node_type)
	if new_node == null:
		return McpErrorCodes.make(McpErrorCodes.INTERNAL_ERROR, "Failed to instantiate %s" % node_type)

	if not node_name.is_empty():
		new_node.name = node_name

	parent.add_child(new_node, true)
	new_node.owner = scene_root

	return {
		"data": {
			"name": new_node.name,
			"type": new_node.get_class(),
			"path": ScenePath.from_node(new_node, scene_root),
			"parent_path": ScenePath.from_node(parent, scene_root),
		}
	}
