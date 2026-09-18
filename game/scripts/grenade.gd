extends CharacterBody2D
class_name Grenade

## 东的技能：卡皮手雷。弧线飞行、低反弹、72 帧后爆炸。

const GRAVITY := 700.0
const BOUNCE := 0.25
const FUSE := 72
const RADIUS := 40.0
const DMG := 20.0
const LAYER_WORLD := 1
const LAYER_FIGHTER := 2
const LAYER_ENEMY := 4

var owner_fighter: Fighter = null
var age := 0
var exploded := false

func setup(owner: Fighter) -> void:
	owner_fighter = owner
	collision_layer = 8
	collision_mask = LAYER_WORLD
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	cs.shape = circle
	add_child(cs)

func launch(dir: int) -> void:
	velocity = Vector2(220 * dir, -220)

func _physics_process(_delta: float) -> void:
	if exploded:
		return
	age += 1
	velocity.y = min(velocity.y + GRAVITY * get_physics_process_delta_time(), 600.0)
	move_and_slide()
	if is_on_wall() or is_on_floor():
		velocity.x *= BOUNCE
		if is_on_floor():
			velocity.y = -abs(velocity.y) * BOUNCE
		else:
			velocity.y *= BOUNCE
		if abs(velocity.x) < 30 and is_on_floor():
			velocity = Vector2.ZERO
	if age >= FUSE:
		explode()

func explode() -> void:
	if exploded:
		return
	exploded = true
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	params.shape = circle
	params.transform = Transform2D(0, global_position)
	params.collision_mask = LAYER_FIGHTER | LAYER_ENEMY
	params.exclude = [owner_fighter, self]
	for hit in space.intersect_shape(params, 16):
		var c: Node = hit.collider
		if c == null or c == owner_fighter:
			continue
		if c is Fighter and c.team == owner_fighter.team:
			continue
		if not c.has_method("take_damage"):
			continue
		if _has_los(c):
			var dir: float = -1.0 if c.global_position.x > global_position.x else 1.0
			c.take_damage(DMG, owner_fighter, true, Vector2(150 * dir, -150))
	queue_free()

func _has_los(c: Node) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		global_position, c.global_position + Vector2(0, -10), LAYER_WORLD)
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5, Color(0.95, 0.8, 0.3))
	draw_circle(Vector2.ZERO, 5, Color(0.95, 0.8, 0.3))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 12, Color(0.9, 0.4, 0.2), 2.0)
