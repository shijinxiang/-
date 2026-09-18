extends Control
## 主菜单：练习 / 对战 / 合作 / 退出。

func _ready() -> void:
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.2, 0.3)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "东金决战"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 40
	add_child(title)

	var sub := Label.new()
	sub.text = "金（拖鞋） vs 东（怒气） · 本地双人"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 112
	add_child(sub)

	var y := 160
	_add_button("练习模式", y, _start_practice)
	_add_button("双人对战", y + 60, _start_versus)
	_add_button("双人合作", y + 120, _start_coop)
	_add_button("退出", y + 180, func(): get_tree().quit())

	var help := Label.new()
	help.text = "P1: 移动A/D  跳Space  冲刺Shift  攻击J  技能K  大招L  拾取F\nP2: 方向键移动  跳Up  冲刺Tab  攻击1  技能2  大招3  拾取4\n对战先赢两回合；合作清完三波敌人"
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	help.anchor_left = 0.0
	help.anchor_right = 1.0
	help.offset_top = 330
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(help)

func _add_button(text: String, y: int, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 52)
	b.position = Vector2(320 - 120, y)
	b.pressed.connect(cb)
	add_child(b)

func _start_practice() -> void:
	Game.mode = "practice"
	Game.practice = true
	Game.goto_scene("res://scenes/arena.tscn")

func _start_versus() -> void:
	Game.mode = "versus"
	Game.practice = false
	Game.goto_scene("res://scenes/arena.tscn")

func _start_coop() -> void:
	Game.mode = "coop"
	Game.practice = false
	Game.goto_scene("res://scenes/coop.tscn")
