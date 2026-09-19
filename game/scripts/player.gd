extends CharacterBody2D
class_name Fighter

## Two-player fighter controller with movement, animation, projectile attacks
## and close-range attacks.

const GRAVITY := 1050.0
const MAX_SPEED := 185.0
const ACCELERATION := 1500.0
const DECELERATION := 1900.0
const JUMP_VELOCITY := -380.0
const MAX_FALL_SPEED := 650.0
const WORLD_LEFT := 34.0
const WORLD_RIGHT := 606.0
const ATTACK_LOCK_SPEED := 80.0
const HIT_STUN_TIME := 0.18
const INVULNERABLE_TIME := 0.24

var player_id := 1
var character := "jin"
var facing := 1
var input_enabled := true
var health := 100.0
var state := "idle"

var run_sprite: AnimatedSprite2D
var body_collision: CollisionShape2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var visual_state := ""
var attack_animation := ""
var attack_projectile_scene := ""
var attack_projectile_speed := 400.0
var attack_projectile_damage := 16.0
var attack_melee_damage := 8.0
var attack_hitbox_size := Vector2(54.0, 42.0)
var attack_hitbox_offset := Vector2(32.0, -51.0)
var attack_spawn_offset := Vector2(42.0, -58.0)
var attack_active_start := 1
var attack_active_end := -1
var hit_stun := 0.0
var invulnerable := 0.0
var hit_flash := 0.0
var attack_triggered := false
var attack_hit_ids: Dictionary = {}

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	if player_id == 2:
		facing = -1
	_configure_attack()
	_build_body()
	_build_character_sprite()
	_build_attack_area()
	_play_visual("standby")
	queue_redraw()

func _configure_attack() -> void:
	if character == "dong":
		_set_attack_profile("dong_attack_2")
	else:
		_set_attack_profile("jin_attack_2")

func _set_attack_profile(animation_name: String) -> void:
	attack_animation = animation_name
	attack_projectile_scene = ""
	attack_projectile_speed = 0.0
	attack_projectile_damage = 0.0
	attack_hitbox_size = Vector2(54.0, 42.0)
	attack_hitbox_offset = Vector2(32.0, -51.0)
	attack_spawn_offset = Vector2(42.0, -58.0)
	attack_active_start = 1
	attack_active_end = -1

	match animation_name:
		"jin_attack_1":
			attack_melee_damage = 14.0
			attack_hitbox_size = Vector2(76.0, 50.0)
			attack_hitbox_offset = Vector2(40.0, -52.0)
			attack_active_start = 3
			attack_active_end = 8
		"dong_attack_1":
			attack_melee_damage = 13.0
			attack_hitbox_size = Vector2(72.0, 52.0)
			attack_hitbox_offset = Vector2(36.0, -52.0)
			attack_active_start = 2
			attack_active_end = 6
		"dong_attack_3":
			attack_melee_damage = 18.0
			attack_hitbox_size = Vector2(92.0, 56.0)
			attack_hitbox_offset = Vector2(48.0, -52.0)
			attack_active_start = 2
			attack_active_end = 5
		"dong_attack_2":
			attack_projectile_scene = "res://scenes/projectiles/shoulei.tscn"
			attack_projectile_speed = 360.0
			attack_projectile_damage = 20.0
			attack_melee_damage = 10.0
			attack_hitbox_offset = Vector2(32.0, -51.0)
			attack_spawn_offset = Vector2(40.0, -58.0)
		"jin_attack_2":
			attack_projectile_scene = "res://scenes/projectiles/tuoxie.tscn"
			attack_projectile_speed = 430.0
			attack_projectile_damage = 18.0
			attack_melee_damage = 9.0
			attack_hitbox_offset = Vector2(32.0, -51.0)
			attack_spawn_offset = Vector2(44.0, -58.0)

func _build_body() -> void:
	body_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22.0, 58.0)
	body_collision.shape = shape
	body_collision.position = Vector2(0.0, -29.0)
	add_child(body_collision)

func _build_character_sprite() -> void:
	var scene_path := "res://tests/jin.tscn" if character == "jin" else "res://tests/dong.tscn"
	var source_scene := load(scene_path) as PackedScene
	if source_scene != null:
		var source_root := source_scene.instantiate()
		var source_sprite := source_root.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if source_sprite != null:
			run_sprite = source_sprite.duplicate() as AnimatedSprite2D
		source_root.free()

	if run_sprite == null:
		run_sprite = _build_fallback_sprite()

	run_sprite.name = "AnimatedSprite2D"
	run_sprite.position = Vector2(0.0, -46.0)
	run_sprite.scale = Vector2(0.48, 0.48)
	run_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	run_sprite.z_index = 2
	add_child(run_sprite)
	# The source scenes were authored as looping previews. Runtime attacks
	# need a single pass so animation_finished can return to idle.
	for animation_name in _attack_animation_names():
		if run_sprite.sprite_frames.has_animation(animation_name):
			run_sprite.sprite_frames.set_animation_loop(animation_name, false)
	if not run_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		run_sprite.frame_changed.connect(_on_sprite_frame_changed)
	if not run_sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		run_sprite.animation_finished.connect(_on_sprite_animation_finished)

func _attack_animation_names() -> Array[String]:
	if character == "dong":
		return ["dong_attack_1", "dong_attack_2", "dong_attack_3"]
	return ["jin_attack_1", "jin_attack_2"]

func _build_fallback_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var sheet_path := "res://assets/characters/zhen/jin_chroma.png" if character == "jin" else "res://assets/characters/zhen/dong_chroma.png"
	var sheet := load(sheet_path) as Texture2D
	if sheet != null:
		_add_sheet_animation(frames, "run", sheet, 0, 12.0, 8, Vector2(128.0, 170.0))
		_add_sheet_animation(frames, "jump", sheet, 2, 10.0, 8, Vector2(128.0, 170.0))
		_add_sheet_animation(frames, "standby", sheet, 0, 6.0, 1, Vector2(128.0, 170.0))
	sprite.sprite_frames = frames
	return sprite

func _add_sheet_animation(frames: SpriteFrames, animation_name: String, sheet: Texture2D, row: int, speed: float, frame_count: int, frame_size: Vector2) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, true)
	for index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(index * frame_size.x, row * frame_size.y), frame_size)
		frames.add_frame(animation_name, frame)

func _build_attack_area() -> void:
	attack_area = Area2D.new()
	attack_area.name = "AttackHitbox"
	attack_area.collision_layer = 4
	attack_area.collision_mask = 2
	attack_area.monitoring = true
	attack_area.monitorable = false
	attack_area.body_entered.connect(_on_attack_body_entered)
	add_child(attack_area)

	attack_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54.0, 42.0)
	attack_shape.shape = shape
	attack_shape.disabled = true
	attack_area.add_child(attack_shape)

func _physics_process(delta: float) -> void:
	if hit_stun > 0.0:
		hit_stun = maxf(hit_stun - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
	else:
		_process_input(delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	move_and_slide()
	global_position.x = clampf(global_position.x, WORLD_LEFT, WORLD_RIGHT)
	invulnerable = maxf(invulnerable - delta, 0.0)
	hit_flash = maxf(hit_flash - delta, 0.0)

	if state == "attack":
		velocity.x = move_toward(velocity.x, 0.0, ATTACK_LOCK_SPEED * delta)
		_update_attack_hitbox()
	else:
		_update_movement_visual()
	_update_sprite_flip()
	queue_redraw()

func _process_input(delta: float) -> void:
	var horizontal := 0.0
	if input_enabled:
		if Input.is_action_pressed(Game.player_action(player_id, "move_left")):
			horizontal -= 1.0
		if Input.is_action_pressed(Game.player_action(player_id, "move_right")):
			horizontal += 1.0
		if Input.is_action_just_pressed(Game.player_action(player_id, "jump")) and is_on_floor() and state != "attack":
			velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed(Game.player_action(player_id, "attack")) and state != "attack":
			_start_attack(attack_animation)
		if character == "jin" and Input.is_action_just_pressed(Game.player_action(player_id, "melee")) and state != "attack":
			_start_attack("jin_attack_1")
		if character == "dong" and Input.is_action_just_pressed(Game.player_action(player_id, "melee_1")) and state != "attack":
			_start_attack("dong_attack_1")
		if character == "dong" and Input.is_action_just_pressed(Game.player_action(player_id, "melee_3")) and state != "attack":
			_start_attack("dong_attack_3")

	if state == "attack":
		return
	if horizontal != 0.0:
		facing = 1 if horizontal > 0.0 else -1
		velocity.x = move_toward(velocity.x, horizontal * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)

func _start_attack(animation_name: String) -> void:
	if run_sprite == null or not run_sprite.sprite_frames.has_animation(animation_name):
		return
	_set_attack_profile(animation_name)
	state = "attack"
	attack_triggered = false
	attack_hit_ids.clear()
	velocity.x = 0.0
	run_sprite.animation = animation_name
	run_sprite.frame = 0
	run_sprite.play(animation_name)
	_update_attack_hitbox()

func _on_sprite_frame_changed() -> void:
	if run_sprite == null or state != "attack" or run_sprite.animation != attack_animation:
		return
	var last_frame := run_sprite.sprite_frames.get_frame_count(attack_animation) - 1
	if not attack_projectile_scene.is_empty() and run_sprite.frame >= last_frame and not attack_triggered:
		attack_triggered = true
		_spawn_projectile()
	_update_attack_hitbox()

func _on_sprite_animation_finished() -> void:
	if run_sprite == null or run_sprite.animation != attack_animation:
		return
	state = "idle"
	attack_shape.disabled = true
	attack_hit_ids.clear()
	_update_movement_visual()

func _spawn_projectile() -> void:
	var projectile_scene := load(attack_projectile_scene) as PackedScene
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate() as ThrownItem
	if projectile == null:
		return
	projectile.configure(self, facing, attack_projectile_speed, attack_projectile_damage)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(attack_spawn_offset.x * facing, attack_spawn_offset.y)

func _update_movement_visual() -> void:
	if run_sprite == null or state == "attack":
		return
	var action := "jump" if not is_on_floor() else ("run" if absf(velocity.x) > 12.0 else "standby")
	var target_animation := _resolve_animation_name(action)
	_play_visual(target_animation)

func _resolve_animation_name(action: String) -> String:
	if action == "standby":
		return "standby"
	var character_animation := "%s_%s" % [character, action]
	if run_sprite != null and run_sprite.sprite_frames != null and run_sprite.sprite_frames.has_animation(character_animation):
		return character_animation
	return action

func _play_visual(animation_name: String) -> void:
	if run_sprite == null or run_sprite.sprite_frames == null or not run_sprite.sprite_frames.has_animation(animation_name):
		return
	if visual_state != animation_name:
		visual_state = animation_name
		run_sprite.animation = animation_name
		run_sprite.frame = 0
		run_sprite.play(animation_name)
	elif not run_sprite.is_playing():
		run_sprite.play(animation_name)
	_update_sprite_flip()

func _update_sprite_flip() -> void:
	if run_sprite != null:
		run_sprite.flip_h = facing < 0
		run_sprite.modulate = Color(1.0, 0.55, 0.55) if hit_flash > 0.0 else Color.WHITE

func _update_attack_hitbox() -> void:
	if attack_shape == null:
		return
	attack_shape.position = Vector2(attack_hitbox_offset.x * facing, attack_hitbox_offset.y)
	var rectangle := attack_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle.size = attack_hitbox_size
	if state != "attack" or run_sprite == null:
		attack_shape.disabled = true
		return
	var frame_count := run_sprite.sprite_frames.get_frame_count(attack_animation)
	var active_end := attack_active_end if attack_active_end >= 0 else frame_count - 2
	var active := run_sprite.frame >= attack_active_start and run_sprite.frame <= active_end
	attack_shape.disabled = not active

func _on_attack_body_entered(body: Node) -> void:
	if state != "attack" or body == self or not body.has_method("receive_hit"):
		return
	var id := body.get_instance_id()
	if attack_hit_ids.has(id):
		return
	attack_hit_ids[id] = true
	body.receive_hit(attack_melee_damage, self, Vector2(170.0 * facing, -70.0))

func receive_hit(amount: float, _source: Node = null, knockback := Vector2.ZERO) -> void:
	if invulnerable > 0.0:
		return
	health = maxf(health - amount, 0.0)
	invulnerable = INVULNERABLE_TIME
	hit_stun = HIT_STUN_TIME
	velocity = knockback
	hit_flash = INVULNERABLE_TIME
	if state == "attack":
		state = "idle"
		if attack_shape != null:
			attack_shape.disabled = true
		if run_sprite != null:
			run_sprite.stop()
	if health <= 0.0:
		# Keep the short prototype round alive; the next hit starts from full
		# health instead of introducing an unfinished defeat screen.
		health = 100.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 22.0, Color(0.02, 0.05, 0.08, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if run_sprite == null or run_sprite.sprite_frames == null:
		draw_rect(Rect2(-11.0, -58.0, 22.0, 58.0), Color(0.3, 0.75, 0.35), true)
		draw_circle(Vector2(0.0, -68.0), 11.0, Color(0.38, 0.83, 0.42))
