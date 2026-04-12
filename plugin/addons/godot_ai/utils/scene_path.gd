@tool
class_name ScenePath
extends RefCounted

## Utility for converting between Godot internal node paths and clean
## scene-relative paths like /Main/Camera3D.


## Return a clean path relative to the scene root (e.g. /Main/Camera3D).
static func from_node(node: Node, scene_root: Node) -> String:
	if scene_root == null or node == null:
		return ""
	if node == scene_root:
		return "/" + scene_root.name
	var relative := scene_root.get_path_to(node)
	return "/" + scene_root.name + "/" + str(relative)


## Resolve a clean scene path like "/Main/Camera3D" to the actual node.
static func resolve(scene_path: String, scene_root: Node) -> Node:
	if scene_root == null:
		return null

	var root_prefix := "/" + scene_root.name
	if scene_path == root_prefix:
		return scene_root
	if scene_path.begins_with(root_prefix + "/"):
		var relative := scene_path.substr(root_prefix.length() + 1)
		return scene_root.get_node_or_null(relative)

	# Try as-is (relative path)
	return scene_root.get_node_or_null(scene_path)
