extends Node2D
## 战斗冒烟测试：直接触发金/东的普攻、技能、大招，验证无运行时错误并检查资源变化。

var frames := 0
var a: Fighter
var b: Fighter

func _ready() -> void:
	var g := StaticBody2D.new()
	g.position = Vector2(320, 330)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(1200, 60)
	cs.shape = r
	g.add_child(cs)
	add_child(g)
	a = _mk("jin", 0, Vector2(200, 300))
	b = _mk("dong", 1, Vector2(220, 300))
	b.rage = 300

func _mk(ch: String, team: int, pos: Vector2) -> Fighter:
	var f := Fighter.new()
	f.character = ch
	f.team = team
	f.global_position = pos
	add_child(f)
	return f

func _physics_process(_d: float) -> void:
	frames += 1
	if frames == 5:
		print("SMOKE ready, a.hp=", a.hp, " b.hp=", b.hp)
	match frames:
		30:
			a._try_start_attack()   # 金普攻（应命中 b）
		60:
			a._try_start_skill()    # 金投拖鞋
		90:
			a._try_start_ultimate() # 金臭气
		120:
			b._try_start_skill()    # 东手雷
		145:
			b.rage = 300
		150:
			b._try_start_ultimate() # 东喷火
		220:
			a._try_interact()       # 尝试拾取
		270:
			var result_ok := b.hp < 100 and a.inventory <= 2 and b.rage < 300
			print("SMOKE_RESULT hp_a=%d hp_b=%d rage_b=%d inv_a=%d a_state=%d b_state=%d ok=%s" % [
				a.hp, b.hp, b.rage, a.inventory, a.action_state, b.action_state, result_ok])
			get_tree().quit(0 if result_ok else 1)
