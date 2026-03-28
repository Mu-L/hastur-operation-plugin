@tool
extends EditorPlugin


var _dock: EditorDock


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	PluginSettings.register_settings()
	_dock = EditorDock.new()
	_dock.title = "Hastur Executor"
	_dock.default_slot = EditorDock.DOCK_SLOT_LEFT_UL
	_dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	var dock_content = preload("executor_dock.gd").new()
	_dock.add_child(dock_content)
	add_dock(_dock)


func _exit_tree() -> void:
	remove_dock(_dock)
	_dock.queue_free()
	_dock = null
