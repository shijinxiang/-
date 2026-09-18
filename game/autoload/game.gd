extends Node
## 全局流程控制与输入配置（本地双人）

var mode := "menu"      # menu / practice / versus / coop
var practice := false

func _ready() -> void:
	_setup_input_map()

func player_action(player: int, base: String) -> String:
	return "p%d_%s" % [player, base]

func goto_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func to_menu() -> void:
	goto_scene("res://scenes/menu.tscn")

# ---------- 输入映射 ----------
func _setup_input_map() -> void:
	for p in [1, 2]:
		for base in ["move_left", "move_right", "jump", "dash", "attack",
				"skill", "ultimate", "interact", "menu"]:
			var n := player_action(p, base)
			if not InputMap.has_action(n):
				InputMap.add_action(n)

	# P1：A/D 移动，Space 跳，Shift 冲刺，J 普攻，K 技能，L 大招，F 拾取
	_add_key(1, "move_left", KEY_A)
	_add_key(1, "move_right", KEY_D)
	_add_key(1, "jump", KEY_SPACE)
	_add_key(1, "dash", KEY_SHIFT)
	_add_key(1, "attack", KEY_J)
	_add_key(1, "skill", KEY_K)
	_add_key(1, "ultimate", KEY_L)
	_add_key(1, "interact", KEY_F)
	# P2：方向键移动，上键跳，右Shift冲刺，1 普攻，2 技能，3 大招，4 拾取
	_add_key(2, "move_left", KEY_LEFT)
	_add_key(2, "move_right", KEY_RIGHT)
	_add_key(2, "jump", KEY_UP)
	_add_key(2, "dash", KEY_TAB)
	_add_key(2, "attack", KEY_1)
	_add_key(2, "skill", KEY_2)
	_add_key(2, "ultimate", KEY_3)
	_add_key(2, "interact", KEY_4)
	for p in [1, 2]:
		_add_key(p, "menu", KEY_ESCAPE)

func _add_key(player: int, base: String, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(player_action(player, base), ev)
