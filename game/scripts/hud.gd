extends Control
class_name HUD

## 战斗 HUD：生命、怒气/拖鞋、倒计时、比分/波次、救援进度、结算。

var p1: Fighter = null
var p2: Fighter = null
var manager: Node = null

var p1_hp_bar: ColorRect
var p2_hp_bar: ColorRect
var p1_res_label: Label
var p2_res_label: Label
var banner_label: Label
var bottom_label: Label
var helper_label: Label

func setup(a: Fighter, b: Fighter, mgr: Node) -> void:
	p1 = a
	p2 = b
	manager = mgr
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 顶部中央横幅
	banner_label = _make_label(Color(1, 1, 1), 28)
	banner_label.anchor_left = 0.0
	banner_label.anchor_right = 1.0
	banner_label.offset_top = 6
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(banner_label)
	# 底部提示
	helper_label = _make_label(Color(0.9, 0.9, 0.9), 14)
	helper_label.anchor_left = 0.0
	helper_label.anchor_right = 1.0
	helper_label.offset_top = 334
	helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper_label.text = "P1 移动A/D 跳Space 冲刺Shift 攻击J 技能K 大招L 拾取F    P2 方向键 跳Up 冲刺Tab 攻击1 技能2 大招3 拾取4"
	add_child(helper_label)
	# 两侧面板
	_make_panel(0)
	_make_panel(1)

func _make_panel(idx: int) -> void:
	var is_left := idx == 0
	var f: Fighter = p1 if is_left else p2
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.35)
	if is_left:
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.offset_left = 6
		panel.offset_right = 220
		panel.offset_top = 6
		panel.offset_bottom = 74
	else:
		panel.anchor_left = 1.0
		panel.anchor_top = 0.0
		panel.offset_left = -220
		panel.offset_right = -6
		panel.offset_top = 6
		panel.offset_bottom = 74
	add_child(panel)
	var name_label := _make_label(Color(1, 1, 1), 16)
	name_label.position = Vector2(10, 10)
	name_label.text = ("金" if f.character == "jin" else "东") + ("  P%d" % f.player_id)
	panel.add_child(name_label)
	# 血条
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0.2, 0.2, 0.2)
	hp_bg.position = Vector2(10, 30)
	hp_bg.size = Vector2(130, 10)
	panel.add_child(hp_bg)
	var hp_bar := ColorRect.new()
	hp_bar.position = Vector2(10, 30)
	hp_bar.size = Vector2(130, 10)
	hp_bar.color = Color(0.9, 0.2, 0.2) if not is_left else Color(0.2, 0.8, 0.3)
	panel.add_child(hp_bar)
	# 资源文字
	var res := _make_label(Color(1, 1, 1), 14)
	res.position = Vector2(10, 46)
	panel.add_child(res)
	if is_left:
		p1_hp_bar = hp_bar
		p1_res_label = res
	else:
		p2_hp_bar = hp_bar
		p2_res_label = res
	# 底部小信息
	bottom_label = _make_label(Color(1, 1, 1), 14)
	bottom_label.anchor_left = 0.0
	bottom_label.anchor_right = 1.0
	bottom_label.offset_top = 318
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(bottom_label)

func _make_label(col: Color, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _process(_delta: float) -> void:
	if p1 == null or p2 == null:
		return
	_update_bar(p1, p1_hp_bar, p1_res_label)
	_update_bar(p2, p2_hp_bar, p2_res_label)
	if manager != null:
		banner_label.text = manager.hud_banner_text()
		bottom_label.text = manager.hud_bottom_text()

func _update_bar(f: Fighter, bar: ColorRect, res: Label) -> void:
	if bar != null:
		bar.size.x = 130.0 * clampf(f.hp / float(f.max_hp), 0.0, 1.0)
	if res != null:
		if f.character == "jin":
			res.text = "拖鞋: %d/2" % f.inventory
		else:
			var bars := ""
			var filled := int(ceil(f.rage / 100.0))
			for i in 3:
				bars += "■" if i < filled else "□"
			res.text = "怒气: %d  %s" % [f.rage, bars]
