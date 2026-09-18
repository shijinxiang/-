extends Node2D
## 对战（及练习）场景：回合结算、倒计时、比分。

const ROUND_LENGTH := 5400   # 90 秒
const COUNTDOWN := 180       # 3 秒
const ROUND_END_WAIT := 120  # 2 秒

var practice := false
var p1: Fighter
var p2: Fighter
var hud: HUD

var phase := "countdown"  # countdown / fight / round_end / match_end / paused
var countdown := 0
var round_timer := 0
var round_end_timer := 0
var score := [0, 0]
var round_num := 1
var result_text := ""
var pending_death: Fighter = null
var dead_ticks := [0, 0]

var pause_menu: Control
var dummies: Array = []

func _ready() -> void:
	practice = Game.practice
	_setup_world()
	_setup_fighters()
	_setup_hud()
	_setup_pause_menu()
	_start_round()

func _setup_world() -> void:
	# 地面
	_add_static_rect(Rect2(32, 300, 576, 60), Color(0.4, 0.5, 0.6))
	# 左右墙
	_add_static_rect(Rect2(32, 0, 12, 300), Color(0.3, 0.4, 0.5))
	_add_static_rect(Rect2(596, 0, 12, 300), Color(0.3, 0.4, 0.5))
	# 两个小平台（高差 48）
	_add_static_rect(Rect2(190, 252, 100, 8), Color(0.6, 0.5, 0.35))
	_add_static_rect(Rect2(350, 252, 100, 8), Color(0.6, 0.5, 0.35))
	var cam := Camera2D.new()
	cam.position = Vector2(320, 180)
	add_child(cam)

func _add_static_rect(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	body.add_child(cs)
	var vis := ColorRect.new()
	vis.size = rect.size
	vis.position = -rect.size * 0.5
	vis.color = color
	body.add_child(vis)
	add_child(body)

func _setup_fighters() -> void:
	p1 = _make_fighter(1, "jin", 0, Vector2(160, 300))
	p2 = _make_fighter(2, "dong", 1, Vector2(480, 300))
	p1.died.connect(_on_fighter_died.bind(p1))
	p2.died.connect(_on_fighter_died.bind(p2))
	if practice:
		_spawn_dummy(Vector2(300, 300))
		_spawn_dummy(Vector2(420, 300))

func _make_fighter(pid: int, ch: String, team: int, pos: Vector2) -> Fighter:
	var f := Fighter.new()
	f.player_id = pid
	f.character = ch
	f.team = team
	f.global_position = pos
	add_child(f)
	return f

func _spawn_dummy(pos: Vector2) -> void:
	var e := Enemy.new()
	e.setup(Enemy.EType.CHASER)
	e.set_dummy(true)
	e.hp = 99999
	e.max_hp = 99999
	e.global_position = pos
	add_child(e)
	dummies.append(e)

func _setup_hud() -> void:
	hud = HUD.new()
	hud.setup(p1, p2, self)
	add_child(hud)

func _setup_pause_menu() -> void:
	pause_menu = Control.new()
	# 暂停菜单必须在暂停树上继续处理输入和按钮事件。
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_menu.visible = false
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(dim)
	var title := Label.new()
	title.text = "暂停"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 120
	pause_menu.add_child(title)
	_add_pause_button("返回主菜单", 170, func(): _close_pause(); Game.to_menu())
	add_child(pause_menu)

func _add_pause_button(text: String, y: int, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 44)
	b.position = Vector2(320 - 100, y)
	b.pressed.connect(cb)
	pause_menu.add_child(b)

func _toggle_pause() -> void:
	pause_menu.visible = not pause_menu.visible
	get_tree().paused = pause_menu.visible

func _close_pause() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Game.player_action(1, "menu")):
		_toggle_pause()

func _start_round() -> void:
	phase = "countdown"
	countdown = COUNTDOWN
	round_timer = ROUND_LENGTH
	result_text = ""
	pending_death = null
	_clear_temp()
	p1.input_enabled = false
	p2.input_enabled = false
	p1.reset_for_round()
	p2.reset_for_round()
	p1.global_position = Vector2(160, 300)
	p2.global_position = Vector2(480, 300)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO

func _clear_temp() -> void:
	for child in get_children():
		if child is Grenade or child is GasCloud or child is Flame:
			child.queue_free()

func _physics_process(_delta: float) -> void:
	if pause_menu.visible:
		return
	match phase:
		"countdown":
			countdown -= 1
			if countdown <= 0:
				phase = "fight"
				p1.input_enabled = true
				p2.input_enabled = true
		"fight":
			round_timer -= 1
			if pending_death != null:
				var loser: Fighter = pending_death
				pending_death = null
				if not p1.alive and not p2.alive:
					_finish_round(0)
				elif loser == p1:
					_finish_round(2)
				else:
					_finish_round(1)
			elif round_timer <= 0:
				_time_up()
		"round_end":
			round_end_timer -= 1
			if round_end_timer <= 0:
				_advance_round()
		"match_end":
			round_end_timer -= 1
			if round_end_timer <= 0:
				Game.to_menu()
	if practice:
		_tick_practice_respawn()

func _tick_practice_respawn() -> void:
	var arr := [p1, p2]
	for i in 2:
		var f: Fighter = arr[i]
		if not f.alive or f.action_state == Fighter.ActionState.DEAD:
			dead_ticks[i] += 1
			if dead_ticks[i] >= 120:
				dead_ticks[i] = 0
				f.reset_for_round()
				f.global_position = Vector2(160 if i == 0 else 480, 300)
				f.velocity = Vector2.ZERO
		else:
			dead_ticks[i] = 0

func _on_fighter_died(f: Fighter) -> void:
	if practice:
		return
	if phase == "fight":
		pending_death = f

func _time_up() -> void:
	if phase != "fight":
		return
	if p1.hp > p2.hp:
		_finish_round(1)
	elif p2.hp > p1.hp:
		_finish_round(2)
	else:
		_finish_round(0)

func _finish_round(winner: int) -> void:
	if phase != "fight":
		return
	phase = "round_end"
	round_end_timer = ROUND_END_WAIT
	p1.input_enabled = false
	p2.input_enabled = false
	if winner == 0:
		result_text = "平局"
	elif winner == 1:
		score[0] += 1
		result_text = "金获胜"
	else:
		score[1] += 1
		result_text = "东获胜"

func _advance_round() -> void:
	if score[0] >= 2 or score[1] >= 2:
		phase = "match_end"
		round_end_timer = 180
		result_text = "金获得比赛胜利" if score[0] > score[1] else "东获得比赛胜利"
	else:
		round_num += 1
		_start_round()

# ---------------- HUD 接口 ----------------
func hud_banner_text() -> String:
	match phase:
		"countdown":
			return "第 %d 回合  开始: %d" % [round_num, ceili(countdown / 60.0)]
		"fight":
			return "第 %d 回合  %d:%02d  金 %d : %d 东" % [
				round_num, round_timer / 60, round_timer % 60, score[0], score[1]]
		"round_end":
			return result_text + "   金 %d : %d 东" % [score[0], score[1]]
		"match_end":
			return result_text
	return ""

func hud_bottom_text() -> String:
	if phase == "match_end":
		return "即将返回主菜单…"
	return ""
