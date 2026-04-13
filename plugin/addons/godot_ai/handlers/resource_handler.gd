@tool
class_name ResourceHandler
extends RefCounted

## Handles resource search, inspection, and assignment to nodes.

var _undo_redo: EditorUndoRedoManager


func _init(undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = undo_redo


func search_resources(params: Dictionary) -> Dictionary:
	var type_filter: String = params.get("type", "")
	var path_filter: String = params.get("path", "")

	if type_filter.is_empty() and path_filter.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "At least one filter (type, path) is required")

	var efs := EditorInterface.get_resource_filesystem()
	if efs == null:
		return McpErrorCodes.make(McpErrorCodes.EDITOR_NOT_READY, "EditorFileSystem not available")

	var results: Array[Dictionary] = []
	_scan_resources(efs.get_filesystem(), type_filter, path_filter, results)
	return {"data": {"resources": results, "count": results.size()}}


func _scan_resources(dir: EditorFileSystemDirectory, type_filter: String, path_filter: String, out: Array[Dictionary]) -> void:
	for i in dir.get_file_count():
		var file_path := dir.get_file_path(i)
		var file_type := dir.get_file_type(i)

		var matches := true

		if not type_filter.is_empty():
			# Check if the file type matches or is a subclass of the requested type
			if file_type != type_filter and not ClassDB.is_parent_class(file_type, type_filter):
				matches = false

		if matches and not path_filter.is_empty():
			if file_path.to_lower().find(path_filter.to_lower()) == -1:
				matches = false

		if matches:
			out.append({
				"path": file_path,
				"type": file_type,
			})

	for i in dir.get_subdir_count():
		_scan_resources(dir.get_subdir(i), type_filter, path_filter, out)


func load_resource(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")

	if path.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Missing required param: path")

	if not path.begins_with("res://"):
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Path must start with res://")

	if not ResourceLoader.exists(path):
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Resource not found: %s" % path)

	var res: Resource = load(path)
	if res == null:
		return McpErrorCodes.make(McpErrorCodes.INTERNAL_ERROR, "Failed to load resource: %s" % path)

	var properties: Array[Dictionary] = []
	for prop in res.get_property_list():
		var usage: int = prop.get("usage", 0)
		if not (usage & PROPERTY_USAGE_EDITOR):
			continue
		var value = res.get(prop.name)
		if value == null and prop.type != TYPE_NIL:
			continue
		properties.append({
			"name": prop.name,
			"type": type_string(prop.type),
			"value": NodeHandler._serialize_value(value),
		})

	return {
		"data": {
			"path": path,
			"type": res.get_class(),
			"properties": properties,
			"property_count": properties.size(),
		}
	}


func assign_resource(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var resource_path: String = params.get("resource_path", "")

	if node_path.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Missing required param: path")

	if property.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Missing required param: property")

	if resource_path.is_empty():
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Missing required param: resource_path")

	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return McpErrorCodes.make(McpErrorCodes.EDITOR_NOT_READY, "No scene open")

	var node := ScenePath.resolve(node_path, scene_root)
	if node == null:
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Node not found: %s" % node_path)

	# Verify property exists
	var found := false
	for prop in node.get_property_list():
		if prop.name == property:
			found = true
			break
	if not found:
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Property '%s' not found on %s" % [property, node.get_class()])

	if not ResourceLoader.exists(resource_path):
		return McpErrorCodes.make(McpErrorCodes.INVALID_PARAMS, "Resource not found: %s" % resource_path)

	var res: Resource = load(resource_path)
	if res == null:
		return McpErrorCodes.make(McpErrorCodes.INTERNAL_ERROR, "Failed to load resource: %s" % resource_path)

	var old_value = node.get(property)

	_undo_redo.create_action("MCP: Assign %s to %s.%s" % [resource_path.get_file(), node.name, property])
	_undo_redo.add_do_property(node, property, res)
	_undo_redo.add_undo_property(node, property, old_value)
	_undo_redo.commit_action()

	return {
		"data": {
			"path": node_path,
			"property": property,
			"resource_path": resource_path,
			"resource_type": res.get_class(),
			"undoable": true,
		}
	}
