extends Area2D
class_name Flame

## 东的大招：怒火喷射。附着口部的火焰，周期伤害，墙挡。

const DMG := 5.0
const TICK_EVERY := 15
const LIFE := 90
const LAYER_WORLD := 1
const LAYER_FIGHTER := 2
const LAYER_ENEMY := 4

var owner_fighter: Fighter = null
var age := 0
var tick_next := 15
var hit_log := {}

func setup(owner: Fighter) -> void:
	owner_fighter = owner
	collision_layer = 0
	collision_mask = LAYER_FIGHTER | LAYER_ENEMY
	monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(110, 36)
	cs.shape = rect
	add_child(cs)

func _physics_process(_delta: float) -> void:
	_reposition()
	age += 1
	if age >= tick_next:
		tick_next += TICK_EVERY
		_tick()
	if age >= LIFE:
		queue_free()

func _reposition() -> void:
	if owner_fighter == null or not is_instance_valid(owner_fighter):
		queue_free()
		return
	global_position = owner_fighter.global_position + Vector2(owner_fighter.facing * 55, -30)

func _tick() -> void:
	for b in get_overlapping_bodies():
		if b == null or b == owner_fighter:
			continue
		if not b.has_method("take_damage"):
			continue
		if b is Fighter and b.team == owner_fighter.team:
			continue
		if _has_los(b):
			b.take_damage(DMG, owner_fighter, false)

func _has_los(c: Node) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position
	var to: Vector2 = c.global_position + Vector2(0, -10)
	var q := PhysicsRayQueryParameters2D.create(from, to, LAYER_WORLD)
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()

func _draw() -> void:
	draw_rect(Rect2(-55, -18, 110, 36), Color(1.0, 0.5, 0.1, 0.6))
	draw_rect(Rect2(-55, -18, 110, 36), Color(1.0, 0.85, 0.3, 0.9), false, 2.0)
