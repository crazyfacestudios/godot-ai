@tool
class_name SceneHandler
extends RefCounted

## Handles scene tree reading and node search.


func get_scene_tree(params: Dictionary) -> Dictionary:
	var max_depth: int = params.get("depth", 10)
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return {"data": {"nodes": [], "message": "No scene open"}}

	var nodes: Array[Dictionary] = []
	_walk_tree(scene_root, nodes, 0, max_depth, scene_root)
	return {"data": {"nodes": nodes, "total_count": nodes.size()}}


func _walk_tree(node: Node, out: Array[Dictionary], depth: int, max_depth: int, scene_root: Node) -> void:
	if depth > max_depth:
		return
	out.append({
		"name": node.name,
		"type": node.get_class(),
		"path": ScenePath.from_node(node, scene_root),
		"children_count": node.get_child_count(),
	})
	for child in node.get_children():
		_walk_tree(child, out, depth + 1, max_depth, scene_root)
