extends CharacterBody2D
class_name Slipper

## 金的拖鞋：飞行 / 落地可拾取物。生命周期 inventory -> flying -> falling -> grounded -> inventory。

const GRAVITY := 400.0
const ATTACK_LIFE := 45
const HIT_DMG := 14.0
const FLY_SPEED := 320.0
const LAYER_WORLD := 1
const LAYER_FIGHTER := 2
const LAYER_ENEMY := 4

var owner_fighter: Fighter = null
var slipper_id := 0
var state := "inventory"
var life := 0

func setup(owner: Fighter, sid: int) -> void:
	owner_fighter = owner
	slipper_id = sid
	collision_layer = 0
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 8)
	cs.shape = rect
	add_child(cs)

func launch(dir: int) -> void:
	state = "flying"
	life = 0
	visible = true
	collision_layer = 8
	collision_mask = LAYER_WORLD
	velocity = Vector2(FLY_SPEED * dir, -100)

func reset_to_inventory() -> void:
	state = "inventory"
	visible = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO

func pick_up() -> void:
	state = "inventory"
	visible = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	match state:
		"flying":
			life += 1
			velocity.y = min(velocity.y + GRAVITY * get_physics_process_delta_time(), 300.0)
			_check_hit()
			move_and_slide()
			if is_on_wall() or is_on_floor():
				state = "falling"
				velocity = Vector2(velocity.x * 0.3, 40)
			elif life >= ATTACK_LIFE:
				state = "falling"
				velocity = Vector2(0, 40)
		"falling":
			velocity.y = min(velocity.y + GRAVITY * get_physics_process_delta_time(), 200.0)
			move_and_slide()
			if is_on_floor():
				state = "grounded"
				velocity = Vector2.ZERO
		"grounded":
			pass

func _check_hit() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 18)
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = Transform2D(0, global_position)
	params.collision_mask = LAYER_FIGHTER | LAYER_ENEMY
	params.exclude = [owner_fighter, self]
	for hit in space.intersect_shape(params, 8):
		var c: Node = hit.collider
		if c == null or c == owner_fighter:
			continue
		if c is Fighter and c.team == owner_fighter.team:
			continue
		if not c.has_method("take_damage"):
			continue
		var dir: float = -1.0 if c.global_position.x > global_position.x else 1.0
		if c.take_damage(HIT_DMG, owner_fighter, true, Vector2(120 * dir, -80)):
			state = "falling"
			velocity = Vector2(0, 40)
			return

func _draw() -> void:
	draw_rect(Rect2(-6, -3, 12, 6), Color(0.85, 0.8, 0.4))
	draw_circle(Vector2(0, 0), 4, Color(0.6, 0.9, 0.6))
