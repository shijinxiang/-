extends CharacterBody2D
class_name Fighter

## 金 / 东 共用角色控制器：移动、跳跃、二段跳、冲刺、普攻、技能、大招、资源。

enum MoveState { GROUNDED, AIRBORNE, DASHING }
enum ActionState { FREE, ATTACK, SKILL, ULT, HURT, DOWNED, DEAD }

const GRAVITY := 1000.0
const MAX_SPEED := 150.0
const ACCEL_GROUND := 1200.0
const DECEL_GROUND := 1600.0
const ACCEL_AIR := 800.0
const JUMP_VEL := -340.0
const DOUBLE_JUMP_VEL := -300.0
const MAX_FALL := 600.0
const COYOTE_TICKS := 6
const JUMP_BUFFER_TICKS := 6
const DASH_SPEED := 420.0
const DASH_DURATION := 9
const DASH_COOLDOWN := 36

const MAX_HP := 100
const RAGE_MAX := 300
const RAGE_START := 100
const HURT_TICKS := 10
const DIRECT_PROTECT := 12

const LAYER_WORLD := 1
const LAYER_FIGHTER := 2
const LAYER_ENEMY := 4

var player_id := 1
var character := "jin"
var team := 0
var facing := 1

var move_state := MoveState.GROUNDED
var action_state := ActionState.FREE
var alive := true
var downed := false
var input_enabled := true
var combat_active := true

var hp := MAX_HP
var max_hp := MAX_HP
var velocity_override := Vector2.ZERO

var jump_count := 0
var coyote_left := COYOTE_TICKS
var jump_buffer_left := 0
var _was_on_floor := true

var dash_ticks := 0
var dash_cooldown := 0
var air_dash_used := false
var dash_saved_vy := 0.0

var current_action := ""
var action_elapsed := 0
var action_total := 0
var hit_targets := {}

var protect_ticks := 0
var hurt_ticks := 0

# 金：拖鞋
var inventory := 0
var slippers := []
var skill_cd := 0
var ult_cd := 0

# 东：怒气
var rage := RAGE_START
var rage_lock := false
var rage_accum := 0

var teammate: Fighter = null
var active_flame: Node = null

signal hp_changed
signal rage_changed
signal slipper_changed
signal died
signal revived

var body_color := Color(0.3, 0.7, 0.4)

func _ready() -> void:
	add_to_group("fighters")
	_build_body()
	body_color = Color(0.3, 0.75, 0.35) if character == "jin" else Color(0.85, 0.25, 0.25)
	if character == "jin":
		_setup_slippers()
	hp_changed.emit()
	rage_changed.emit()
	slipper_changed.emit()

func _build_body() -> void:
	collision_layer = LAYER_FIGHTER
	collision_mask = LAYER_WORLD
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 58)
	cs.shape = rect
	cs.position = Vector2(0, -29)
	add_child(cs)

# ---------------- 每帧主逻辑 ----------------
func _physics_process(_delta: float) -> void:
	queue_redraw()
	if action_state == ActionState.DEAD:
		return
	if action_state == ActionState.DOWNED:
		_tick_downed()
		return
	_update_ground_air_state()
	_process_current_action()
	_process_hurt()
	if not alive:
		return
	_tick_cooldowns()
	if character == "dong":
		_tick_natural_rage()
	_handle_inputs()
	_apply_movement()
	move_and_slide()

# ---------------- 地面/空中状态 ----------------
func _update_ground_air_state() -> void:
	var on_floor := is_on_floor()
	if on_floor:
		jump_count = 0
		air_dash_used = false
		coyote_left = COYOTE_TICKS
		if move_state == MoveState.AIRBORNE:
			move_state = MoveState.GROUNDED
		_was_on_floor = true
	else:
		if _was_on_floor and jump_count == 0 and move_state != MoveState.DASHING:
			jump_count = 1  # 走下平台：消耗一次跳跃机会
		coyote_left = max(0, coyote_left - 1)
		if move_state == MoveState.GROUNDED and move_state != MoveState.DASHING:
			move_state = MoveState.AIRBORNE
		_was_on_floor = false

# ---------------- 输入 ----------------
func is_held(base: String) -> bool:
	return Input.is_action_pressed(Game.player_action(player_id, base))

func is_pressed(base: String) -> bool:
	return Input.is_action_just_pressed(Game.player_action(player_id, base))

func interact_held() -> bool:
	return is_held("interact")

func _handle_inputs() -> void:
	if not input_enabled or not combat_active:
		return
	var left := is_held("move_left")
	var right := is_held("move_right")
	var h := 0.0
	if left != right:
		h = -1.0 if left else 1.0
		facing = int(h)

	if is_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER_TICKS

	if is_pressed("ultimate") and _try_start_ultimate():
		return
	if is_pressed("skill") and _try_start_skill():
		return
	if is_pressed("attack") and _try_start_attack():
		return

	if action_state != ActionState.FREE:
		return

	if is_pressed("dash") and _try_start_dash():
		return
	if is_pressed("interact"):
		_try_interact()
	_apply_horizontal(h)
	_handle_jump()

func _apply_horizontal(h: float) -> void:
	if move_state == MoveState.DASHING:
		velocity.x = facing * DASH_SPEED
		return
	var dt := get_physics_process_delta_time()
	if is_on_floor():
		var acc := ACCEL_GROUND if h != 0.0 else DECEL_GROUND
		velocity.x = move_toward(velocity.x, h * MAX_SPEED, acc * dt)
	else:
		velocity.x = move_toward(velocity.x, h * MAX_SPEED, ACCEL_AIR * dt)

func _handle_jump() -> void:
	if jump_buffer_left <= 0:
		return
	var did := false
	if move_state == MoveState.DASHING:
		move_state = MoveState.AIRBORNE
		velocity.y = 0.0
	if is_on_floor() or coyote_left > 0:
		velocity.y = JUMP_VEL
		jump_count = 1
		did = true
	elif jump_count < 2:
		velocity.y = DOUBLE_JUMP_VEL
		jump_count += 1
		did = true
	if did:
		jump_buffer_left = 0

func _try_start_dash() -> bool:
	if move_state == MoveState.DASHING:
		return false
	if dash_cooldown > 0:
		return false
	if not is_on_floor():
		if air_dash_used:
			return false
		air_dash_used = true
	move_state = MoveState.DASHING
	dash_ticks = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	dash_saved_vy = velocity.y
	velocity.x = facing * DASH_SPEED
	velocity.y = 0.0
	return true

func _apply_movement() -> void:
	if action_state == ActionState.HURT:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * get_physics_process_delta_time())
	if move_state == MoveState.DASHING:
		dash_ticks -= 1
		velocity.x = facing * DASH_SPEED
		velocity.y = 0.0
		if dash_ticks <= 0:
			move_state = MoveState.AIRBORNE if not is_on_floor() else MoveState.GROUNDED
			velocity.y = dash_saved_vy
		return
	velocity.y = min(velocity.y + GRAVITY * get_physics_process_delta_time(), MAX_FALL)

# ---------------- 动作系统 ----------------
func _try_start_attack() -> bool:
	if action_state != ActionState.FREE:
		return false
	if character == "jin" and inventory <= 0:
		return false
	current_action = "attack"
	action_state = ActionState.ATTACK
	action_elapsed = 0
	action_total = 24
	hit_targets.clear()
	velocity.x = 0
	return true

func _try_start_skill() -> bool:
	if action_state != ActionState.FREE:
		return false
	if character == "jin":
		if inventory <= 0 or skill_cd > 0:
			return false
	else:
		if rage < 100 or skill_cd > 0:
			return false
	current_action = "skill"
	action_state = ActionState.SKILL
	action_elapsed = 0
	action_total = 24
	return true

func _try_start_ultimate() -> bool:
	if action_state != ActionState.FREE:
		return false
	if not is_on_floor():
		return false
	if character == "jin":
		if ult_cd > 0:
			return false
		current_action = "ultimate"
		action_total = 30
	else:
		if rage < RAGE_MAX:
			return false
		rage = 0
		rage_lock = true
		rage_changed.emit()
		current_action = "ultimate"
		action_total = 132
	action_state = ActionState.ULT
	action_elapsed = 0
	return true

func _process_current_action() -> void:
	match action_state:
		ActionState.ATTACK:
			action_elapsed += 1
			if action_elapsed >= 6 and action_elapsed <= 8:
				_melee_check()
			if action_elapsed >= action_total:
				_end_action()
		ActionState.SKILL:
			action_elapsed += 1
			if character == "jin" and action_elapsed == 9:
				_throw_slipper()
			elif character == "dong" and action_elapsed == 10:
				_throw_grenade()
			if action_elapsed >= action_total:
				_end_action()
		ActionState.ULT:
			_process_ultimate()

func _process_ultimate() -> void:
	action_elapsed += 1
	if character == "jin":
		if action_elapsed == 18:
			_spawn_gas()
		if action_elapsed >= action_total:
			ult_cd = 720
			_end_action()
	else:  # dong
		if action_elapsed == 18:
			_start_flame()
		elif action_elapsed == 109:
			_stop_flame()
		if action_elapsed >= action_total:
			rage_lock = false
			_end_action()

func _end_action() -> void:
	action_state = ActionState.FREE
	current_action = ""

func _process_hurt() -> void:
	if action_state == ActionState.HURT:
		hurt_ticks -= 1
		if hurt_ticks <= 0:
			action_state = ActionState.FREE
			current_action = ""

# ---------------- 近战判定 ----------------
func _melee_check() -> void:
	var rng := 34.0 if character == "jin" else 26.0
	var dmg := 10.0 if character == "jin" else 8.0
	var rect := RectangleShape2D.new()
	rect.size = Vector2(rng, 40)
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = Transform2D(0, global_position + Vector2(facing * (rng * 0.5 + 4), -10))
	params.collision_mask = LAYER_FIGHTER | LAYER_ENEMY
	params.exclude = [self]
	for hit in space.intersect_shape(params, 8):
		var c: Node = hit.collider
		if c == null or c == self:
			continue
		if hit_targets.has(c.get_instance_id()):
			continue
		hit_targets[c.get_instance_id()] = true
		if not c.has_method("take_damage"):
			continue
		if c is Fighter and c.team == team:
			continue
		var dir: float = -1.0 if c.global_position.x > global_position.x else 1.0
		var dealt: bool = c.take_damage(dmg, self, true, Vector2(100 * dir, -100))
		if character == "dong" and dealt:
			add_rage(10, "attack_hit")

# ---------------- 金的拖鞋 ----------------
func _setup_slippers() -> void:
	slippers.clear()
	for i in 2:
		var s := Slipper.new()
		s.setup(self, i)
		get_parent().add_child(s)
		s.global_position = global_position + Vector2(-60 - i * 20, -20)
		s.visible = false
		slippers.append(s)
	inventory = 2

func _get_available_slipper() -> Slipper:
	for s in slippers:
		if s.state == "inventory":
			return s
	return null

func _throw_slipper() -> void:
	if inventory <= 0:
		return
	var s := _get_available_slipper()
	if s == null:
		return
	inventory -= 1
	slipper_changed.emit()
	s.global_position = global_position + Vector2(facing * 14, -30)
	s.launch(facing)
	skill_cd = 24

func reset_slippers() -> void:
	inventory = 2
	for s in slippers:
		s.reset_to_inventory()
	slipper_changed.emit()

func _try_interact() -> void:
	if action_state != ActionState.FREE or not alive:
		return
	if character != "jin":
		return
	if teammate != null and is_instance_valid(teammate) and teammate.downed:
		if global_position.distance_to(teammate.global_position) <= 32:
			return  # 优先救援
	var best: Slipper = null
	var best_d := 28.0
	for s in slippers:
		if s.state != "grounded":
			continue
		var d := global_position.distance_to(s.global_position)
		if d <= best_d and _clear_path_to(s.global_position):
			if best == null or d < global_position.distance_to(best.global_position):
				best = s
				best_d = d
	if best != null:
		best.pick_up()
		inventory = min(2, inventory + 1)
		slipper_changed.emit()

func _clear_path_to(tp: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -20), tp + Vector2(0, -10), LAYER_WORLD)
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()

# ---------------- 东的技能 ----------------
func _throw_grenade() -> void:
	if rage < 100:
		return
	rage -= 100
	rage_changed.emit()
	var g := Grenade.new()
	g.setup(self)
	get_parent().add_child(g)
	g.global_position = global_position + Vector2(facing * 14, -30)
	g.launch(facing)
	skill_cd = 36  # 手雷冷却

func _start_flame() -> void:
	var f := Flame.new()
	f.setup(self)
	get_parent().add_child(f)
	active_flame = f

func _stop_flame() -> void:
	if active_flame != null and is_instance_valid(active_flame):
		active_flame.queue_free()
	active_flame = null

func _spawn_gas() -> void:
	var g := GasCloud.new()
	g.setup(self)
	get_parent().add_child(g)
	g.global_position = global_position + Vector2(facing * 36, -24)

# ---------------- 怒气 ----------------
func add_rage(amount: int, _reason: String) -> void:
	if character != "dong":
		return
	if rage_lock or not alive:
		return
	rage = clampi(rage + amount, 0, RAGE_MAX)
	rage_changed.emit()

func _tick_natural_rage() -> void:
	if not combat_active or not input_enabled or not alive:
		return
	if rage_lock:
		return
	rage_accum += 1
	if rage_accum >= 60:
		rage_accum = 0
		add_rage(8, "passive")

# ---------------- 伤害 / 状态 ----------------
func take_damage(dmg: float, source: Node = null, direct: bool = true,
		knockback: Vector2 = Vector2.ZERO) -> bool:
	if not alive:
		return false
	if action_state == ActionState.DEAD or action_state == ActionState.DOWNED:
		return false
	if protect_ticks > 0 and direct:
		return false
	if direct:
		protect_ticks = DIRECT_PROTECT
	var dealt := minf(dmg, hp)
	hp = clampi(int(hp - dmg), 0, MAX_HP)
	hp_changed.emit()
	if character == "dong" and not rage_lock:
		add_rage(2 * int(dealt), "hurt")
	if direct:
		_enter_hurt(knockback)
	if hp <= 0:
		_on_killed()
	return true

func _enter_hurt(knockback: Vector2) -> void:
	if character == "jin" and action_state == ActionState.ULT:
		# 气团已经生成或大招已被接受时，打断也必须进入冷却。
		ult_cd = max(ult_cd, 720)
	if character == "dong" and action_state == ActionState.ULT:
		_stop_flame()
		rage_lock = false
	current_action = ""
	action_state = ActionState.HURT
	hurt_ticks = HURT_TICKS
	velocity.x = knockback.x
	velocity.y = knockback.y
	if move_state == MoveState.DASHING:
		move_state = MoveState.AIRBORNE

func _on_killed() -> void:
	if Game.mode == "coop":
		enter_downed()
	else:
		_die()

func _die() -> void:
	alive = false
	action_state = ActionState.DEAD
	current_action = ""
	velocity = Vector2.ZERO
	if character == "dong":
		_stop_flame()
	died.emit()

func enter_downed() -> void:
	alive = false
	downed = true
	action_state = ActionState.DOWNED
	current_action = ""
	downed_timer = 900
	velocity = Vector2.ZERO
	if character == "dong":
		_stop_flame()
	died.emit()

var downed_timer := 0

func _tick_downed() -> void:
	downed_timer -= 1
	if downed_timer <= 0:
		downed = false
		action_state = ActionState.DEAD

func rescue_fighter() -> void:
	downed = false
	alive = true
	action_state = ActionState.FREE
	current_action = ""
	hp = 30
	protect_ticks = 60
	hp_changed.emit()
	revived.emit()

func full_revive() -> void:
	downed = false
	alive = true
	action_state = ActionState.FREE
	current_action = ""
	velocity = Vector2.ZERO
	hp = MAX_HP
	protect_ticks = 60
	move_state = MoveState.GROUNDED
	jump_count = 0
	hp_changed.emit()
	rage_changed.emit()
	if character == "dong":
		rage = RAGE_START
		rage_lock = false
		_stop_flame()
	else:
		reset_slippers()

func reset_for_round() -> void:
	alive = true
	downed = false
	hp = MAX_HP
	action_state = ActionState.FREE
	current_action = ""
	move_state = MoveState.GROUNDED
	jump_count = 0
	coyote_left = COYOTE_TICKS
	jump_buffer_left = 0
	dash_ticks = 0
	dash_cooldown = 0
	air_dash_used = false
	protect_ticks = 0
	hurt_ticks = 0
	ult_cd = 0
	skill_cd = 0
	velocity = Vector2.ZERO
	hit_targets.clear()
	hp_changed.emit()
	if character == "dong":
		rage = RAGE_START
		rage_lock = false
		rage_accum = 0
		_stop_flame()
		rage_changed.emit()
	else:
		reset_slippers()

# ---------------- 冷却 ----------------
func _tick_cooldowns() -> void:
	if dash_cooldown > 0:
		dash_cooldown -= 1
	if skill_cd > 0:
		skill_cd -= 1
	if ult_cd > 0:
		ult_cd -= 1
	if protect_ticks > 0:
		protect_ticks -= 1

# ---------------- 绘制 ----------------
func _draw() -> void:
	var col := body_color
	if action_state == ActionState.DOWNED:
		draw_rect(Rect2(-16, -12, 32, 10), col.darkened(0.2))
		draw_circle(Vector2(14, -8), 7, col)
		draw_string(ThemeDB.fallback_font, Vector2(-20, 8), "倒地", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.85, 0.25))
		return
	if not alive:
		return
	if action_state == ActionState.HURT:
		col = Color(1, 1, 1)
	# 腿
	draw_rect(Rect2(-9, -22, 8, 22), col.darkened(0.2))
	draw_rect(Rect2(1, -22, 8, 22), col.darkened(0.2))
	# 身体
	draw_rect(Rect2(-11, -56, 22, 34), col)
	# 头
	draw_circle(Vector2(0, -62), 8, col.lightened(0.15))
	# 面向的眼睛
	draw_circle(Vector2(facing * 3.0, -63), 2.0, Color(1, 1, 1))
	# 东：红色小背包示意；金：拖鞋手持示意
	if character == "dong":
		draw_rect(Rect2(-facing * 8, -50, 6, 16), Color(0.55, 0.1, 0.1))
	elif inventory > 0:
		draw_rect(Rect2(facing * 6, -40, 8, 4), Color(0.85, 0.8, 0.4))
