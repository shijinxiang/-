extends CharacterBody2D
class_name Enemy

## 简化敌人：近战追兵 / 投掷兵 / 首领。

const LAYER_WORLD := 1
const LAYER_FIGHTER := 2

enum EType { CHASER, THROWER, BOSS }

var etype := EType.CHASER
var dummy := false
var hp := 35.0
var max_hp := 35.0
var speed := 80.0
var atk_dmg := 8.0
var atk_range := 26.0
var throw_range := 170.0
var state := "chase"
var cooldown := 0
var windup_left := 0
var attack_left := 0
var recover_left := 0
var hurt_left := 0
var target: Node = null
var face := -1

signal died

func setup(t: int) -> void:
	etype = t as EType
	collision_layer = 4
	collision_mask = LAYER_WORLD
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	match etype:
		EType.CHASER:
			hp = 35; max_hp = 35; speed = 80; atk_dmg = 8; atk_range = 26
			rect.size = Vector2(20, 52)
		EType.THROWER:
			hp = 25; max_hp = 25; speed = 60; atk_dmg = 6
			rect.size = Vector2(18, 46)
		EType.BOSS:
			hp = 600; max_hp = 600; speed = 42; atk_dmg = 12; atk_range = 70
			rect.size = Vector2(44, 110)
	cs.shape = rect
	cs.position = Vector2(0, -rect.size.y * 0.5)
	add_child(cs)

func set_dummy(d: bool) -> void:
	dummy = d

func _physics_process(_delta: float) -> void:
	if hp <= 0:
		return
	if dummy:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * get_physics_process_delta_time())
		move_and_slide()
		return
	_find_target()
	_apply_gravity()
	match state:
		"chase": _act_chase()
		"windup": _act_windup()
		"attack": _act_attack()
		"recover": _act_recover()
		"hurt": _act_hurt()
	move_and_slide()

func _apply_gravity() -> void:
	velocity.y = min(velocity.y + 1000.0 * get_physics_process_delta_time(), 600.0)

func _find_target() -> void:
	var best: Node = null
	var bd := INF
	for f in get_tree().get_nodes_in_group("fighters"):
		if not f.alive or f.downed:
			continue
		var d := global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	target = best
	if target != null:
		face = -1 if target.global_position.x < global_position.x else 1

func _act_chase() -> void:
	if cooldown > 0:
		cooldown -= 1
	if target == null:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * get_physics_process_delta_time())
		return
	var dx: float = target.global_position.x - global_position.x
	var dist := absf(dx)
	var dir := signf(dx)
	if etype == EType.THROWER:
		if dist > throw_range + 30:
			velocity.x = move_toward(velocity.x, dir * speed, 300.0 * get_physics_process_delta_time())
		elif dist < throw_range - 70:
			velocity.x = move_toward(velocity.x, -dir * speed, 300.0 * get_physics_process_delta_time())
		else:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * get_physics_process_delta_time())
		if cooldown <= 0 and dist >= 70 and dist <= throw_range + 30:
			state = "windup"
			windup_left = 30
	else:
		velocity.x = move_toward(velocity.x, dir * speed, 300.0 * get_physics_process_delta_time())
		if dist <= atk_range + 20 and cooldown <= 0:
			state = "windup"
			windup_left = 24 if etype == EType.CHASER else 36

func _act_windup() -> void:
	windup_left -= 1
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * get_physics_process_delta_time())
	if windup_left <= 0:
		state = "attack"
		attack_left = 3
		cooldown = 30 if etype == EType.CHASER else 150

func _act_attack() -> void:
	attack_left -= 1
	if etype == EType.THROWER:
		if attack_left == 2 and target != null:
			var dist := global_position.distance_to(target.global_position)
			if dist <= throw_range + 20 and _has_los(target):
				var dir: float = -1.0 if target.global_position.x > global_position.x else 1.0
				target.take_damage(atk_dmg, self, true, Vector2(60 * dir, -60))
	else:
		if attack_left == 2:
			_melee_check()
	if attack_left <= 0:
		state = "recover"
		recover_left = 33 if etype == EType.CHASER else 60

func _act_recover() -> void:
	recover_left -= 1
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * get_physics_process_delta_time())
	if recover_left <= 0:
		state = "chase"

func _act_hurt() -> void:
	hurt_left -= 1
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * get_physics_process_delta_time())
	if hurt_left <= 0:
		state = "chase"

func _melee_check() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(atk_range, 40)
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = Transform2D(0, global_position + Vector2(face * (atk_range * 0.5 + 6), -10))
	params.collision_mask = LAYER_FIGHTER
	params.exclude = [self]
	for hit in space.intersect_shape(params, 4):
		var c: Node = hit.collider
		if c == null or c == self:
			continue
		if c.has_method("take_damage") and c.alive:
			var dir: float = -1.0 if c.global_position.x > global_position.x else 1.0
			c.take_damage(atk_dmg, self, true, Vector2(100 * dir, -100))
			return

func _has_los(t: Node) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -20), t.global_position + Vector2(0, -20), LAYER_WORLD)
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()

func take_damage(dmg: float, _source: Node = null, direct: bool = true,
		knockback: Vector2 = Vector2.ZERO) -> bool:
	if hp <= 0:
		return false
	hp -= dmg
	if hp <= 0:
		hp = 0
		state = "dead"
		velocity = Vector2.ZERO
		died.emit()
		return true
	if direct:
		state = "hurt"
		hurt_left = 10
		velocity = knockback
	return true

func _draw() -> void:
	if hp <= 0:
		return
	match etype:
		EType.CHASER:
			_draw_body(Color(0.6, 0.3, 0.7), Color(0.4, 0.2, 0.5), 26, 52)
		EType.THROWER:
			_draw_body(Color(0.95, 0.8, 0.2), Color(0.7, 0.55, 0.1), 23, 46)
		EType.BOSS:
			_draw_body(Color(0.75, 0.2, 0.2), Color(0.5, 0.1, 0.1), 55, 110)

func _draw_body(col: Color, dark: Color, w: float, h: float) -> void:
	var top := -h
	draw_rect(Rect2(-w * 0.5, top, w, h * 0.6), col)
	draw_circle(Vector2(face * w * 0.2, top - 8), w * 0.22, col.lightened(0.15))
	draw_rect(Rect2(-w * 0.4, top + h * 0.55, w * 0.35, h * 0.45), dark)
	draw_rect(Rect2(w * 0.05, top + h * 0.55, w * 0.35, h * 0.45), dark)
