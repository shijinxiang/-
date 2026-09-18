extends Node2D
## 合作模式：简化敌人波次 + 救援 + 检查点 + 失败重试。

const TOTAL_WAVES := 3
const RESCUE_TIME := 3.0
const FAIL_WAIT := 180

var p1: Fighter  # 金
var p2: Fighter  # 东
var hud: HUD
var enemies: Array = []
var boss: Enemy = null

var phase := "playing"   # playing / result / paused
var wave := 0
var wave_done := false
var result_text := ""
var result_timer := 0
var rescue_progress := {}

var pause_menu: Control

func _ready() -> void:
	_setup_world()
	_setup_fighters()
	_setup_hud()
	_setup_pause_menu()
	_start_wave(1)

func _setup_world() -> void:
	_add_static_rect(Rect2(32, 300, 576, 60), Color(0.35, 0.5, 0.6))
	_add_static_rect(Rect2(32, 0, 12, 300), Color(0.3, 0.4, 0.5))
	_add_static_rect(Rect2(596, 0, 12, 300), Color(0.3, 0.4, 0.5))
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
	p1 = _make_fighter(1, "jin", 0, Vector2(120, 300))
	p2 = _make_fighter(2, "dong", 0, Vector2(200, 300))
	p1.teammate = p2
	p2.teammate = p1

func _make_fighter(pid: int, ch: String, team: int, pos: Vector2) -> Fighter:
	var f := Fighter.new()
	f.player_id = pid
	f.character = ch
	f.team = team
	f.global_position = pos
	add_child(f)
	return f

func _setup_hud() -> void:
	hud = HUD.new()
	hud.setup(p1, p2, self)
	add_child(hud)

func _setup_pause_menu() -> void:
	pause_menu = Control.new()
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
	var b := Button.new()
	b.text = "返回主菜单"
	b.custom_minimum_size = Vector2(200, 44)
	b.position = Vector2(220, 170)
	b.pressed.connect(func(): pause_menu.visible = false; get_tree().paused = false; Game.to_menu())
	pause_menu.add_child(b)
	add_child(pause_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Game.player_action(1, "menu")):
		pause_menu.visible = not pause_menu.visible
		get_tree().paused = pause_menu.visible

func _start_wave(n: int) -> void:
	wave = n
	wave_done = false
	_clear_enemies()
	_place_players()
	match n:
		1:
			_spawn_enemy(Enemy.EType.CHASER, Vector2(400, 300))
			_spawn_enemy(Enemy.EType.CHASER, Vector2(470, 300))
		2:
			_spawn_enemy(Enemy.EType.CHASER, Vector2(360, 300))
			_spawn_enemy(Enemy.EType.CHASER, Vector2(440, 300))
			_spawn_enemy(Enemy.EType.THROWER, Vector2(510, 300))
		3:
			boss = _spawn_enemy(Enemy.EType.BOSS, Vector2(500, 300))
	rescue_progress.clear()

func _spawn_enemy(t: int, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(t)
	e.global_position = pos
	e.died.connect(_on_enemy_died)
	add_child(e)
	enemies.append(e)
	return e

func _clear_enemies() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	boss = null

func _on_enemy_died() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and e.hp > 0)

func _place_players() -> void:
	p1.full_revive()
	p2.full_revive()
	p1.global_position = Vector2(120, 300)
	p2.global_position = Vector2(200, 300)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if pause_menu.visible:
		return
	if phase == "result":
		result_timer -= 1
		if result_timer <= 0:
			if result_text.contains("失败"):
				_start_wave(wave)
			else:
				Game.to_menu()
		return
	_check_wave_done()
	_check_fail()
	_tick_rescue()

func _check_wave_done() -> void:
	if wave_done:
		return
	var any := false
	for e in enemies:
		if is_instance_valid(e) and e.hp > 0:
			any = true
			break
	if not any and wave > 0:
		wave_done = true
		if wave >= TOTAL_WAVES:
			phase = "result"
			result_timer = 240
			result_text = "合作通关！"
		else:
			_checkpoint_revive()
			_start_wave(wave + 1)

func _checkpoint_revive() -> void:
	for f in [p1, p2]:
		if not f.alive or f.downed or f.action_state == Fighter.ActionState.DEAD:
			f.full_revive()

func _check_fail() -> void:
	if (p1.action_state == Fighter.ActionState.DEAD and p2.downed) or (p2.action_state == Fighter.ActionState.DEAD and p1.downed):
		phase = "result"
		result_timer = FAIL_WAIT
		result_text = "任务失败"
		return
	if p1.action_state == Fighter.ActionState.DEAD or p2.action_state == Fighter.ActionState.DEAD:
		if p1.action_state == Fighter.ActionState.DEAD and p2.action_state == Fighter.ActionState.DEAD:
			phase = "result"
			result_timer = FAIL_WAIT
			result_text = "任务失败"
	if p1.downed and p2.downed:
		phase = "result"
		result_timer = FAIL_WAIT
		result_text = "任务失败"

func _tick_rescue() -> void:
	for f in [p1, p2]:
		if not f.downed:
			rescue_progress[f.get_instance_id()] = 0.0
			continue
		var rescuer: Fighter = p2 if f == p1 else p1
		var key: int = f.get_instance_id()
		if rescuer.alive and not rescuer.downed and rescuer.interact_held() \
				and rescuer.global_position.distance_to(f.global_position) <= 32:
			rescue_progress[key] = rescue_progress.get(key, 0.0) \
					+ get_physics_process_delta_time() / RESCUE_TIME
			if rescue_progress[key] >= 1.0:
				rescue_progress[key] = 0.0
				f.rescue_fighter()
		else:
			rescue_progress[key] = 0.0

# ---------------- HUD 接口 ----------------
func hud_banner_text() -> String:
	if phase == "result":
		return result_text
	var txt := "波次 %d/%d" % [wave, TOTAL_WAVES]
	if boss != null and is_instance_valid(boss) and boss.hp > 0:
		txt += "  首领"
	return txt

func hud_bottom_text() -> String:
	var parts := []
	for f in [p1, p2]:
		if f.downed:
			var prog: float = rescue_progress.get(f.get_instance_id(), 0.0)
			parts.append("队友倒地，按F救援 %d%%" % int(prog * 100))
	if boss != null and is_instance_valid(boss) and boss.hp > 0:
		parts.append("首领 %d/%d" % [int(boss.hp), int(boss.max_hp)])
	return "    ".join(parts)
