extends Node2D

var p1: Fighter
var p2: Fighter
var pause_overlay: Control
var pause_info: Label
var info_button: Button
var map_info: Dictionary

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	map_info = Game.map_data()
	_setup_world()
	_setup_fighters()
	_setup_interface()

func _setup_world() -> void:
	var background_texture := load(map_info.get("background", "res://assets/background/图书馆.jpg")) as Texture2D
	if background_texture == null:
		return
	var background := Sprite2D.new()
	background.texture = background_texture
	background.position = Vector2(320, 180)
	var scale_factor := maxf(640.0 / background_texture.get_width(), 360.0 / background_texture.get_height())
	background.scale = Vector2(scale_factor, scale_factor)
	background.modulate = Color(0.92, 0.95, 1.0, 1.0)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.z_index = -20
	add_child(background)
	var ground_y: float = map_info.get("ground_y", 320.0)
	_add_collision_rect(Rect2(0, ground_y, 640, 360.0 - ground_y))
	_add_collision_rect(Rect2(0, 0, 18, 360))
	_add_collision_rect(Rect2(622, 0, 18, 360))

func _add_collision_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _setup_fighters() -> void:
	p1 = _make_fighter(1, "jin", map_info.get("spawn_left", Vector2(190, 300)))
	p2 = _make_fighter(2, "dong", map_info.get("spawn_right", Vector2(450, 300)))

func _make_fighter(pid: int, kind: String, spawn_position: Vector2) -> Fighter:
	var fighter: Fighter = Fighter.new()
	fighter.player_id = pid
	fighter.character = kind
	fighter.global_position = spawn_position
	add_child(fighter)
	return fighter

func _setup_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	var top_bar := ColorRect.new()
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(640, 48)
	top_bar.color = Color(0.02, 0.06, 0.1, 0.72)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)
	_add_label(root, map_info.get("name", "移动场景"), Vector2(220, 8), Vector2(200, 30), 20, Color(0.96, 0.9, 0.63), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(root, "金", Vector2(24, 9), Vector2(40, 28), 19, Color(0.36, 0.9, 0.55), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(root, "东", Vector2(576, 9), Vector2(40, 28), 19, Color(1.0, 0.42, 0.36), HORIZONTAL_ALIGNMENT_RIGHT)

	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_overlay.visible = false
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(pause_overlay)
	_build_pause_menu()

func _build_pause_menu() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.04, 0.78)
	pause_overlay.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(115, 24)
	panel.size = Vector2(410, 314)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.1, 0.16, 0.97), Color(0.38, 0.75, 0.9)))
	pause_overlay.add_child(panel)
	_add_label(panel, "暂停", Vector2(0, 18), Vector2(410, 34), 30, Color(0.98, 0.9, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	pause_info = _add_label(panel, "金：A / D 移动，Space 跳跃\n金：J 投掷拖鞋，K 近战\n东：方向键移动，↑ 跳跃\n东：1 手雷，2 近战一，3 近战三", Vector2(30, 70), Vector2(350, 92), 14, Color(0.86, 0.91, 0.97), HORIZONTAL_ALIGNMENT_LEFT)
	pause_info.visible = false
	_make_button(panel, "继续游戏", Vector2(114, 174), Vector2(182, 38), _close_pause)
	info_button = _make_button(panel, "人物招式", Vector2(114, 222), Vector2(182, 38), _toggle_pause_info)
	_make_button(panel, "返回菜单", Vector2(114, 270), Vector2(182, 38), _return_to_menu)

func _toggle_pause_info() -> void:
	pause_info.visible = not pause_info.visible
	if pause_info.visible:
		info_button.text = "关闭说明"
	else:
		info_button.text = "人物招式"

func _return_to_menu() -> void:
	_close_pause()
	Game.to_menu()

func _toggle_pause() -> void:
	pause_overlay.visible = not pause_overlay.visible
	get_tree().paused = pause_overlay.visible

func _close_pause() -> void:
	pause_overlay.visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_toggle_pause()

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

func _make_button(parent: Node, text_value: String, control_position: Vector2, control_size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = control_position
	button.size = control_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.1, 0.2, 0.3, 0.96), Color(0.25, 0.55, 0.72)))
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
