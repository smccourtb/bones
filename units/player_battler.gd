extends Battler
class_name Player


var player_die


func roll_die():
	die = preload("res://dice/CharacterDie.tscn").instance()
	add_child(die)
	# triggered when clicking on the die during roll phase
	die.connect("die_selected", self, "_on_Selected")
	# map actions to die and set textures. set it up and add it to the tree
	die.build_die(die_faces, color)
	# apply a random push(?) so each die falls differently. Not positive this works
	randomize()
	die.apply_impulse(die.translation, Vector3(randf(),randf(),randf()))


func _on_Selected(action: Action):
	# called as a player only. Enemy units do not use this, they use _on_RollSet()
	# called when a player clicks on their die on roll phase
	die.disappear()
	player_die = remove_child(die)
	
	
	
	action_choice_texture.set_texture(action.texture)
	ui_animation_player.play("show_action_container")
	yield(ui_animation_player, "animation_finished")
	# sets the current action that you selected
	action_choice = action
	# triggers _on_TargetsSelected() in units.gd
	emit_signal("action_selected", self)


func get_possible_targets():
	# this is barebones right now but only sets an animation the scaling character
	# container.
	var targets
	if action_choice.hostile:
		targets = get_tree().get_nodes_in_group("enemy")
	else:
		targets = get_tree().get_nodes_in_group("player")
	for target in targets:
		target.set_targetable(true)






