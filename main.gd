extends Spatial

signal roll_phase_begin
signal roll_phase_end
signal target_phase_begin
signal target_phase_end
signal combat_phase_begin
signal combat_phase_end

var rerolls: int = 2
var round_num: int = 1
var turn_owner: bool = false # if true player turn, false: enemy
var roll_phase: bool = false
var target_phase: bool = false
var combat_phase: bool = false

# node references
onready var units = $Units
onready var players = get_node("Units/PlayerUnits")
onready var enemies = get_node("Units/EnemyUnits")


func _ready() -> void:
	setup_signals()
	randomize()
	emit_signal("roll_phase_begin")


func _physics_process(_delta: float) -> void:
	units.turn_label.text = "Player Turn" if turn_owner else "Enemy Turn"
	units.phase_label.text = "Phase: " + Global.turn_phase.capitalize()
	$Button.visible = true if Global.turn_phase == "roll" && turn_owner else false


func _on_Button_pressed() -> void:
	set_reroll(1)
	var dice = get_tree().get_nodes_in_group("die")
	for die in dice:
		die.set_gravity_scale(4)
		die.apply_impulse(die.translation, Vector3(randi() % 5 + .5,randi() % 5 + .5,randi() % 5 + .5))


func set_reroll(amount) -> void:
	rerolls -= amount
	if rerolls <= 0:
		$Button.set_disabled(true)
		rerolls = 0


func _on_Roll_Phase_Begin() -> void:
	print("Entering ROLL PHASE")
	roll_phase = true
	Global.turn_phase = "roll"
	if turn_owner:
		for i in players.get_children():
			i.enter_roll_phase()
	else:
		for i in enemies.get_children():
			i.enter_roll_phase()
		yield(get_tree().create_timer(4.0), "timeout")
		emit_signal("roll_phase_end")


func _on_Roll_Phase_End() -> void:
	print("EXITING ROLL PHASE")
	if turn_owner:
		for i in players.get_children():
			if !i.die_selected:
				i._on_Selected(i.get_child(2).actions[i.get_child(2).roll])
		rerolls = 0
	else:
		for i in enemies.get_children():
			i._on_Selected(i.get_child(2).actions[i.get_child(2).roll])
		rerolls = 3
	roll_phase = false
	emit_signal("target_phase_begin")


func _on_targetPhase_begin() -> void:
	print("ENTERING TARGET PHASE")
	target_phase = true
	Global.turn_phase = "target"
	if turn_owner:
		for i in players.get_children():
			if i.face_choice.name == "Miss":
				i.emit_signal("target_selected", null)
				i.set_target_selected(true)
		yield(units, "targets_selected")
		emit_signal("target_phase_end")
	
	if !turn_owner:
		for i in enemies.get_children():
			if i.face_choice.name != "Miss":
				i.choose_target()
#			else:
#				i.emit_signal("target_selected", false)
#		turn_owner = !turn_owner
		emit_signal("target_phase_end")


func _on_targetPhase_end() -> void:
	print("EXITING TARGET PHASE")
	target_phase = false
	if turn_owner:
		emit_signal("combat_phase_begin")
	else:
		turn_owner = !turn_owner
		emit_signal("roll_phase_begin")


func _on_combatPhase_begin() -> void:
	print("ENTERING COMBAT PHASE")
	combat_phase = true
	Global.turn_phase = "combat"
	if turn_owner:
		var characters = []
		for i in players.get_children():
			if i.target:
				characters.append(i)
		for j in characters:
			if !j.disabled:
				j.action_tween_start()
				j.target.action_tween_start()
				yield(get_tree().create_timer(.5), "timeout")
				j.action()
				yield(get_tree().create_timer(1.0), "timeout")
				j.action_tween_end()
				j.target.action_tween_end()
				yield(get_tree().create_timer(1.5), "timeout")
		turn_owner = !turn_owner
		emit_signal("combat_phase_begin")
	else:
		for j in enemies.get_children():
			if j.target && !j.disabled:
				j.action()
				yield(get_tree().create_timer(2.0), "timeout")
		emit_signal("combat_phase_end")


func _on_combatPhase_end() -> void:
	print("EXITING COMBAT PHASE")
	round_num +=1
	rerolls = 2
	turn_owner = false
	units.enemy_actions_selected = 0
	units.player_actions_selected = 0
	units.player_targets_selected = 0
	
	$Button.set_disabled(false)
	# reset actions
	# increase round num
	for i in units.unit_refs:
		if is_instance_valid(i):
			i.reset()
			
	
	if check_for_win():
		$Label.visible = true
		set_pause_mode(true)
	else:
		combat_phase = false
		emit_signal("roll_phase_begin")


func _on_ActionsSelected() -> void:
	if !turn_owner:
		yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("roll_phase_end")


func setup_signals() -> void:
	connect("roll_phase_begin", self, "_on_Roll_Phase_Begin")
	connect("roll_phase_end", self, "_on_Roll_Phase_End")	
	connect("target_phase_end", self, "_on_targetPhase_end")
	connect("target_phase_begin", self, "_on_targetPhase_begin")
	connect("combat_phase_begin", self, "_on_combatPhase_begin")
	connect("combat_phase_end", self, "_on_combatPhase_end")
	units.connect("actions_selected", self, "_on_ActionsSelected")


func check_for_win() -> bool:
	for i in enemies.get_children():
		if !i.disabled:
			return false
	return true
		
