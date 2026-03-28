class_name PluginSettings


static func register_settings() -> void:
	if not ProjectSettings.has_setting("hastur_operation/output_max_char_length"):
		ProjectSettings.set_setting("hastur_operation/output_max_char_length", 800)
	ProjectSettings.set_initial_value("hastur_operation/output_max_char_length", 800)
	ProjectSettings.add_property_info({
		"name": "hastur_operation/output_max_char_length",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "100,10000,1"
	})


static func get_output_max_char_length() -> int:
	return ProjectSettings.get_setting("hastur_operation/output_max_char_length", 800)
