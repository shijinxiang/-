extends Area2D
class_name ThrownItem

## 直线投掷物：由角色攻击动画的最后一帧生成。

var owner_fighter: Node
var direction := 1.0
var speed := 400.0
var damage := 16.0
var lifetime := 2.0
var hit_ids: Dictionary = {}

func configure(source: Node, travel_direction: int, travel_speed: float, hit_damage: float) -> void:
	owner_fighter = source
	direction = 1.0 if travel_direction >= 0 else -1.0
	speed = travel_speed
	damage = hit_damage

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.position = Vector2.ZERO
		sprite.flip_h = direction < 0.0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if name.to_lower().contains("tuoxie"):
			sprite.scale = Vector2(0.9, 0.9)
		else:
			sprite.scale = Vector2(0.75, 0.75)
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	lifetime -= delta
	rotation += direction * delta * 6.0
	if lifetime <= 0.0 or global_position.x < -80.0 or global_position.x > 720.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_apply_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_apply_hit(area.get_parent())

func _apply_hit(target: Node) -> void:
	if target == null or target == owner_fighter:
		return
	if not target.has_method("receive_hit"):
		return
	var id := target.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	target.receive_hit(damage, owner_fighter, Vector2(direction * 170.0, -70.0))
	queue_free()
