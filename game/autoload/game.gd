extends Node
## Global game state shared by the menu, arena and both fighters.

var mode := "menu"
var practice := false
var selected_map := "library"

const MAPS := {
	"library": {
		"name": "图书馆",
		"background": "res://assets/background/图书馆.jpg",
		"ground_y": 264.0,
		"spawn_left": Vector2(170, 264),
		"spawn_right": Vector2(470, 264)
	},
	"neon": {
		"name": "霓虹街道",
		"background": "res://assets/background/Gemini_Generated_Image_uy0pyluy0pyluy0p.jpg",
		"ground_y": 218.0,
		"spawn_left": Vector2(155, 218),
		"spawn_right": Vector2(485, 218)
	}
}

func _ready() -> void:
	_setup_input_map()

func player_action(player: int, base: String) -> String:
	return "p%d_%s" % [player, base]

func goto_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func to_menu() -> void:
	mode = "menu"
	practice = false
	goto_scene("res://scenes/menu.tscn")

func map_data() -> Dictionary:
	return MAPS.get(selected_map, MAPS["library"])

func _setup_input_map() -> void:
	for action in ["menu", "p1_move_left", "p1_move_right", "p1_jump", "p1_attack", "p1_melee", "p2_move_left", "p2_move_right", "p2_jump", "p2_attack", "p2_melee_1", "p2_melee_3"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	_add_key("menu", KEY_ESCAPE)
	_add_key(player_action(1, "move_left"), KEY_A)
	_add_key(player_action(1, "move_right"), KEY_D)
	_add_key(player_action(1, "jump"), KEY_SPACE)
	_add_key(player_action(1, "attack"), KEY_J)
	_add_key(player_action(1, "melee"), KEY_K)
	_add_key(player_action(2, "move_left"), KEY_LEFT)
	_add_key(player_action(2, "move_right"), KEY_RIGHT)
	_add_key(player_action(2, "jump"), KEY_UP)
	_add_key(player_action(2, "attack"), KEY_1)
	_add_key(player_action(2, "melee_1"), KEY_2)
	_add_key(player_action(2, "melee_3"), KEY_3)

func _add_key(action_name: String, keycode: Key) -> void:
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
