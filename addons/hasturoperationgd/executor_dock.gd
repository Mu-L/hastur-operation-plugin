@tool
extends Control


var _code_edit: CodeEdit
var _result_label: RichTextLabel
var _executor: GDScriptExecutor


func _ready() -> void:
	_executor = GDScriptExecutor.new()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	_code_edit = CodeEdit.new()
	_code_edit.custom_minimum_size = Vector2(0, 200)
	_code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_code_edit)

	var button = Button.new()
	button.text = "Execute"
	button.pressed.connect(_on_execute_pressed)
	vbox.add_child(button)

	_result_label = RichTextLabel.new()
	_result_label.custom_minimum_size = Vector2(0, 100)
	_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_label.bbcode_enabled = true
	vbox.add_child(_result_label)


func _on_execute_pressed() -> void:
	var code = _code_edit.text
	var result = _executor.execute_code(code)
	_display_result(result)


func _display_result(result: Dictionary) -> void:
	var text = ""

	if result.compile_success:
		text += "Compile: SUCCESS\n"
	else:
		text += "Compile: FAILED\n"
		text += result.compile_error + "\n"

	if not result.compile_success:
		text += "Run: (skipped)\n"
	elif result.run_success:
		text += "Run: SUCCESS\n"
	else:
		text += "Run: FAILED\n"
		text += result.run_error + "\n"

	if result.outputs.size() > 0:
		text += "---\n"
		text += "Output:\n"
		for entry in result.outputs:
			text += str(entry[0]) + ": " + str(entry[1]) + "\n"

	_result_label.text = text
