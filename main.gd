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


# node references
onready var units = $Units
onready var players = $Units/PlayerUnits
onready var enemies = $Units/EnemyUnits
onready var reroll_button = $Reroll
onready var win_message = $WinMessage

#	although this is the main script right now, much of this will be moved to 
#	"battle" script in the future

func _ready() -> void:
	setup_signals()
	randomize()
#	TODO: add an "{ begin / end } { current_phase } Phase" button to call this
#		  and the other phases. One button for all logic.
	emit_signal("roll_phase_begin")


func _physics_process(_delta: float) -> void:
#	debugging purposes. Updates the phase and whose turn it is
	units.turn_label.text = "Player Turn" if turn_owner else "Enemy Turn"
	units.phase_label.text = "Phase: " + Global.turn_phase.capitalize()
	
#	hides button unless its players roll phase
	reroll_button.visible = Global.turn_phase == "roll" and turn_owner


func set_reroll(amount) -> void:
#	subtracts the amount provided from reroll.
	rerolls -= amount
	if rerolls <= 0:
		reroll_button.set_disabled(true)
		rerolls = 0


func _on_Roll_Phase_Begin() -> void:
	print("ENTERING ROLL PHASE")
	Global.turn_phase = "roll"
#	begins game as enemy turn
#	loops through all units for whosever turn it is and rolls their die
	if turn_owner:
		for player in players.get_children():
			player.roll_die()
	else:
		for enemy in enemies.get_children():
			enemy.roll_die()


func _on_Roll_Phase_End() -> void:
	print("EXITING ROLL PHASE")
#	this was used to auto select an un selected die when the player ran out
#	of rerolls. Doesn't get called anymore. Haven't really looked into it and
#	may deprecate it.
	if turn_owner:
		for player in players.get_children():
			if not player.die_selected:
				player._on_Selected(player.get_child(2).actions[player.get_child(2).roll])
#	officially ends the roll phase and beings the target phase
	emit_signal("target_phase_begin")


func _on_targetPhase_begin() -> void:
	print("ENTERING TARGET PHASE")
#	updates the debug "phase" label
	Global.turn_phase = "target"
#	loops through all player units, checks if there are any misses and sets the 
#	target to null but still triggers the target selected signal so it can increase
#	the count for the signal actions_selected
	if turn_owner:
		for player in players.get_children():
			if player.face_choice.name == "Miss":
				player.emit_signal("target_selected", null)
				# activates the targeted tween and sets target_selected variable
				player.set_target_selected(true)
#		waits until all players have selected targets before moving on
		yield(units, "targets_selected")
		emit_signal("target_phase_end")
	
	if not turn_owner:
#		for enemies, loop through all of them and for the ones that have not
#		missed choose a random target

#		the variable target_selected in enemy doesn't seem to matter because of
#		as of right now, 12/6/21, an enemy can roll a miss and all is well with
#		the world. Hm.
		for enemy in enemies.get_children():
			if not enemy.face_choice.name == "Miss":
				enemy.choose_target()
#		triggers the end of target phase
		emit_signal("target_phase_end")


func _on_targetPhase_end() -> void:
#	so these are different because the enemy first rolls, chooses their actions,
#	and chooses their targets before the player does anything. So it sets the 
#	turn owner to the player, then triggers the beginning of the roll phase to
#	let the player do the saem thing. When it gets back here as the players turn,
#	its time to begin combat. As of right now. The player goes first.
	print("EXITING TARGET PHASE")
	if turn_owner:
		emit_signal("combat_phase_begin")
	else:
		turn_owner = not turn_owner
		emit_signal("roll_phase_begin")


func _on_combatPhase_begin() -> void:
	print("ENTERING COMBAT PHASE")
	Global.turn_phase = "combat"
	
	if turn_owner:
#		loops through all player units and checks if they have a target, then
#		puts them in this characters array.
		var characters = []
		for player in players.get_children():
			if player.target:
				characters.append(player)
#		then it loops through that characters array and checks if its disabled
#		variable is set to true. This isnt used right now. I was using it for
#		when somebody died but now i just free the node. I am leaving it because
#		I may have status effects in the future and disabled will be handy
		for character in characters:
			if not character.disabled:
				# slides the the whole character control node forward
				character.action_tween_start()
				# slides the the characters target node forward
				character.target.action_tween_start()
				yield(get_tree().create_timer(.5), "timeout")
				# performs its action that it chose in the roll phase
				# also plays its appropriate animation
				character.action()
				yield(get_tree().create_timer(1.0), "timeout")
				# slides both characters back to their original spots
				# THAT FIRST BUG YOU FOUND COULD BE IN HERE
				character.action_tween_end()
				character.target.action_tween_end()
				yield(get_tree().create_timer(1.5), "timeout")
		
		# swaps over to the enemy and starts combat phase over
		turn_owner = not turn_owner
		emit_signal("combat_phase_begin")
	else:
		for enemy in enemies.get_children():
#			does the same thing as above but in one line and doesnt create a
#			new array
			if enemy.target and not enemy.disabled:
				enemy.action()
#				# gives it a little room to breathe between combats
#				TODO: add the same thing as above here possibly put it into
#				a function
				yield(get_tree().create_timer(2.0), "timeout")
		emit_signal("combat_phase_end")


func _on_combatPhase_end() -> void:
	print("EXITING COMBAT PHASE")
#	Just a clean up function that performs the resets for everything to prepare
#	for the next round, if there is no winner
	round_num +=1 # <- no functionality to that yet
#	resets rerolls
	rerolls = 2
#	sets turn_owner to enemy
	turn_owner = false
	
#	TODO: make a reset function for units and just call that here instead
	units.enemy_actions_selected = 0
	units.player_actions_selected = 0
	units.player_targets_selected = 0
	
#	reset each unit (character) on both sides so they get set back to the
#	beginning of combat state.
#	TODO: move this to $Units it makes more sense to have this there than main.
	for unit in units.unit_refs:
#		should update unit_refs to remove the references but this works
		if is_instance_valid(unit):
			unit.reset()
	
#	this is just thrown in to signify combat is over. All placeholder stuff
	if check_for_win():
		win_message.show()
		set_pause_mode(true)
	else:
		emit_signal("roll_phase_begin")


func _on_ActionsSelected() -> void:
#	called when all actions(die) on either side are selected
	if not turn_owner: # if enemy turn
		yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("roll_phase_end")


func setup_signals() -> void:
#	these signals control the flow of the phases of battle
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


func _on_Reroll_pressed() -> void:
#	subtract 1 reroll action from total rerolls
	set_reroll(1)
	
#	roll all available player dice
	var dice = get_tree().get_nodes_in_group("die")
	for die in dice:
#		this is just me guessing at values
#		would be nice make it feel a bit more 'realistic'
		die.set_gravity_scale(4)
		die.apply_impulse(die.translation, Vector3(randi() % 5 + .5, randi() % 5 + .5, randi() % 5 + .5))
