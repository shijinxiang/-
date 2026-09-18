extends Area2D
class_name GasCloud

## 金的大招：臭气冲天。固定气团，周期伤害 + 首次接触额外怒气。

const TOTAL := 240
const TICK_INTERVAL := 30
const DMG := 2.0
const STIM := 60
const LAYER_FIGHTER := 2
const LAYER_ENEMY := 4

var owner_fighter: Fighter = null
var age := 0
var tick_next := 30
var stimmed := {}

func setup(owner: Fighter) -> void:
	owner_fighter = owner
	collision_layer = 0
	collision_mask = LAYER_FIGHTER | LAYER_ENEMY
	monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 56)
	cs.shape = rect
	add_child(cs)

func _physics_process(_delta: float) -> void:
	age += 1
	if age >= tick_next:
		tick_next += TICK_INTERVAL
		_tick()
	if age >= TOTAL:
		queue_free()

func _tick() -> void:
	for b in get_overlapping_bodies():
		if b == null or b == owner_fighter:
			continue
		if not b.has_method("take_damage"):
			continue
		if b is Fighter:
			if b.team == owner_fighter.team:
				continue
			if b.action_state == Fighter.ActionState.DOWNED:
				continue
		b.take_damage(DMG, owner_fighter, false)
		if b is Fighter and b.character == "dong" and not stimmed.has(b.get_instance_id()):
			stimmed[b.get_instance_id()] = true
			b.add_rage(STIM, "gas_stim")

func _draw() -> void:
	draw_rect(Rect2(-50, -28, 100, 56), Color(0.5, 0.8, 0.3, 0.35))
	draw_rect(Rect2(-50, -28, 100, 56), Color(0.3, 0.7, 0.2, 0.7), false, 2.0)
