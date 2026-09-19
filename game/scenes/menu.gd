extends Control

var settings_overlay: Control
var map_overlay: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.06, 0.1)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var side := ColorRect.new()
	side.position = Vector2(0, 0)
	side.size = Vector2(9, 360)
	side.color = Color(0.34, 0.78, 0.88)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(side)

	var panel := Panel.new()
	panel.position = Vector2(86, 24)
	panel.size = Vector2(468, 312)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.12, 0.18, 0.98), Color(0.28, 0.62, 0.75)))
	add_child(panel)

	_add_label(panel, "东金决战", Vector2(0, 26), Vector2(468, 52), 42, Color(0.98, 0.86, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "移动演示版", Vector2(0, 78), Vector2(468, 25), 15, Color(0.68, 0.86, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_make_button(panel, "开始游戏", Vector2(134, 122), Vector2(200, 38), _start_movement)
	_make_button(panel, "设置 / 人物招式", Vector2(134, 170), Vector2(200, 38), _show_settings)
	_make_button(panel, "退出", Vector2(134, 218), Vector2(200, 38), _quit_game)
	_add_label(panel, "移动、跳跃和投掷物演示", Vector2(0, 270), Vector2(468, 24), 13, Color(0.72, 0.8, 0.88), HORIZONTAL_ALIGNMENT_CENTER)

func _start_movement() -> void:
	_show_map_select()

func _quit_game() -> void:
	get_tree().quit()

func _show_settings() -> void:
	if settings_overlay != null or map_overlay != null:
		return
	settings_overlay = Control.new()
	settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.04, 0.84)
	settings_overlay.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(70, 14)
	panel.size = Vector2(500, 332)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.12, 0.18, 0.99), Color(0.92, 0.68, 0.3)))
	settings_overlay.add_child(panel)
	_add_label(panel, "设置 / 人物招式", Vector2(0, 18), Vector2(500, 34), 26, Color(0.98, 0.86, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "金", Vector2(70, 64), Vector2(180, 24), 18, Color(0.36, 0.9, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "东", Vector2(270, 64), Vector2(180, 24), 18, Color(1.0, 0.42, 0.36), HORIZONTAL_ALIGNMENT_CENTER)
	_add_key_cap(panel, "A", Color(0.28, 0.7, 0.95), Vector2(84, 98))
	_add_key_cap(panel, "D", Color(0.3, 0.82, 0.58), Vector2(120, 98))
	_add_label(panel, "移动", Vector2(156, 96), Vector2(72, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "SPACE", Color(0.95, 0.65, 0.25), Vector2(84, 134), Vector2(68, 24))
	_add_label(panel, "跳跃", Vector2(156, 132), Vector2(72, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "J", Color(0.94, 0.36, 0.48), Vector2(84, 170))
	_add_label(panel, "投掷拖鞋", Vector2(120, 168), Vector2(110, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "K", Color(0.84, 0.38, 0.82), Vector2(84, 204))
	_add_label(panel, "近战攻击", Vector2(120, 202), Vector2(110, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "←", Color(0.28, 0.7, 0.95), Vector2(284, 98))
	_add_key_cap(panel, "→", Color(0.3, 0.82, 0.58), Vector2(320, 98))
	_add_label(panel, "移动", Vector2(356, 96), Vector2(72, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "↑", Color(0.95, 0.65, 0.25), Vector2(284, 134))
	_add_label(panel, "跳跃", Vector2(320, 132), Vector2(72, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "1", Color(0.94, 0.36, 0.48), Vector2(284, 170))
	_add_label(panel, "投掷手雷", Vector2(320, 168), Vector2(110, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "2", Color(0.84, 0.38, 0.82), Vector2(284, 204))
	_add_label(panel, "近战一", Vector2(320, 202), Vector2(110, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_key_cap(panel, "3", Color(0.84, 0.38, 0.82), Vector2(284, 236))
	_add_label(panel, "近战三", Vector2(320, 234), Vector2(110, 28), 15, Color(0.9, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(panel, "ESC：打开暂停界面", Vector2(0, 266), Vector2(500, 22), 14, Color(0.72, 0.8, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	_make_button(panel, "返回菜单", Vector2(160, 294), Vector2(180, 34), _close_settings)

func _close_settings() -> void:
	if settings_overlay != null:
		settings_overlay.queue_free()
		settings_overlay = null

func _show_map_select() -> void:
	if map_overlay != null or settings_overlay != null:
		return
	map_overlay = Control.new()
	map_overlay.name = "MapSelectOverlay"
	map_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(map_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.04, 0.86)
	map_overlay.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(70, 48)
	panel.size = Vector2(500, 264)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.12, 0.18, 0.99), Color(0.3, 0.68, 0.82)))
	map_overlay.add_child(panel)
	_add_label(panel, "选择场景", Vector2(0, 18), Vector2(500, 34), 28, Color(0.98, 0.86, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "选择一个练习场地", Vector2(0, 54), Vector2(500, 24), 14, Color(0.75, 0.86, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_make_button(panel, "图书馆", Vector2(58, 96), Vector2(178, 48), func(): _select_map("library"))
	_make_button(panel, "霓虹街道", Vector2(264, 96), Vector2(178, 48), func(): _select_map("neon"))
	_add_label(panel, "两名角色可在场景中移动、跳跃和投掷", Vector2(0, 166), Vector2(500, 24), 13, Color(0.72, 0.8, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	_make_button(panel, "返回菜单", Vector2(160, 204), Vector2(180, 36), _close_map_select)

func _select_map(map_id: String) -> void:
	Game.selected_map = map_id
	Game.mode = "movement"
	Game.practice = false
	Game.goto_scene("res://scenes/arena.tscn")

func _close_map_select() -> void:
	if map_overlay != null:
		map_overlay.queue_free()
		map_overlay = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if settings_overlay != null:
			_close_settings()
		elif map_overlay != null:
			_close_map_select()

func _add_label(parent: Node, text_value: String, control_position: Vector2, control_size: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = control_position
	label.size = control_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func _add_key_cap(parent: Node, text_value: String, color: Color, control_position: Vector2, control_size := Vector2(28, 24)) -> void:
	var cap := ColorRect.new()
	cap.position = control_position
	cap.size = control_size
	cap.color = color
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cap)
	var label := _add_label(cap, text_value, Vector2.ZERO, control_size, 11, Color(0.02, 0.04, 0.07), HORIZONTAL_ALIGNMENT_CENTER)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _make_button(parent: Node, text_value: String, control_position: Vector2, control_size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = control_position
	button.size = control_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.1, 0.2, 0.3, 0.98), Color(0.25, 0.55, 0.72)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.34, 0.45, 1.0), Color(0.42, 0.82, 0.92)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.25, 0.48, 0.52, 1.0), Color(0.95, 0.78, 0.35)))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, border)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	return style
