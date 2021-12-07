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
var roll_phase_begin_timeout: float = 1.0

# node references
onready var units = $Units
onready var players = $Units/PlayerUnits
onready var enemies = $Units/EnemyUnits
onready var button = $Button
onready var label = $Label


func _ready() -> void:
	setup_signals()
	randomize()
	emit_signal("roll_phase_begin")


func _physics_process(_delta: float) -> void:
	units.turn_label.text = "Player Turn" if turn_owner else "Enemy Turn"
	units.phase_label.text = "Phase: " + Global.turn_phase.capitalize()
	button.visible = Global.turn_phase == "roll" and turn_owner


func _on_Button_pressed() -> void:
	set_reroll(1)
	var dice = get_tree().get_nodes_in_group("die")
	for die in dice:
		die.set_gravity_scale(4)
		die.apply_impulse(die.translation, Vector3(randi() % 5 + .5, randi() % 5 + .5, randi() % 5 + .5))


func set_reroll(amount) -> void:
	rerolls -= amount
	if rerolls <= 0:
		button.set_disabled(true)
		rerolls = 0


func _on_Roll_Phase_Begin() -> void:
	print("Entering ROLL PHASE")
	roll_phase = true
	Global.turn_phase = "roll"
	if turn_owner:
		for player in players.get_children():
			player.enter_roll_phase()
	else:
		for enemy in enemies.get_children():
			enemy.enter_roll_phase()
		yield(get_tree().create_timer(roll_phase_begin_timeout), "timeout")
		emit_signal("roll_phase_end")


func _on_Roll_Phase_End() -> void:
	print("EXITING ROLL PHASE")
	if turn_owner:
		for player in players.get_children():
			if not player.die_selected:
				player._on_Selected(player.get_child(2).actions[player.get_child(2).roll])
		rerolls = 0
	else:
		for enemy in enemies.get_children():
			enemy._on_Selected(enemy.get_child(2).actions[enemy.get_child(2).roll])
		rerolls = 3
	roll_phase = false
	emit_signal("target_phase_begin")


func _on_targetPhase_begin() -> void:
	print("ENTERING TARGET PHASE")
	target_phase = true
	Global.turn_phase = "target"
	if turn_owner:
		for player in players.get_children():
			if player.face_choice.name == "Miss":
				player.emit_signal("target_selected", null)
				player.set_target_selected(true)
		yield(units, "targets_selected")
		emit_signal("target_phase_end")
	
	if not turn_owner:
		for enemy in enemies.get_children():
			if not enemy.face_choice.name == "Miss":
				enemy.choose_target()
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
		turn_owner = not turn_owner
		emit_signal("roll_phase_begin")


func _on_combatPhase_begin() -> void:
	print("ENTERING COMBAT PHASE")
	combat_phase = true
	Global.turn_phase = "combat"
	if turn_owner:
		var characters = []
		for player in players.get_children():
			if player.target:
				characters.append(player)
		for character in characters:
			if not character.disabled:
				character.action_tween_start()
				character.target.action_tween_start()
				yield(get_tree().create_timer(.5), "timeout")
				character.action()
				yield(get_tree().create_timer(1.0), "timeout")
				character.action_tween_end()
				character.target.action_tween_end()
				yield(get_tree().create_timer(1.5), "timeout")
		turn_owner = not turn_owner
		emit_signal("combat_phase_begin")
	else:
		for enemy in enemies.get_children():
			if enemy.target and not enemy.disabled:
				enemy.action()
				yield(get_tree().create_timer(2.0), "timeout")
		emit_signal("combat_phase_end")


func _on_combatPhase_end() -> void:
	print("EXITING COMBAT PHASE")
	# reset actions
	# increase round num <- no functionality to that yet
	round_num +=1
	rerolls = 2
	turn_owner = false
	units.enemy_actions_selected = 0
	units.player_actions_selected = 0
	units.player_targets_selected = 0
	
	button.set_disabled(false)
	
	for i in units.unit_refs:
		if is_instance_valid(i):
			i.reset()
	
	if check_for_win():
		label.show()
		set_pause_mode(true)
	else:
		combat_phase = false
		emit_signal("roll_phase_begin")


func _on_ActionsSelected() -> void:
	if not turn_owner:
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
#	we could use get_nodes_in_group("enemies") but we already have the 
#	reference
	if enemies.get_children().size() > 0:
		return false
	return true
