extends Battler
class_name Player


# connected to: units.gd - during _setup_player and _setup_enemy
# triggered when A) a player character is a current_attacker(units.gd) and player
#					clicks on a valid target
signal target_selected # only pertains to players


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
	action_choice_texture.set_texture(action.texture)
	ui_animation_player.play("show_action_container")
	# sets the current action that you selected
	action_choice = action
	# triggers _on_TargetsSelected() in units.gd
	emit_signal("action_selected", true)


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


func _on_BattlerContainer_mouse_entered() -> void:
	SFX.play(preload("res://assets/sounds/ui/button_hover.wav"))
	if not Global.turn_phase == "combat":
		ui_animation_player.play("grow_battler")


func _on_BattlerContainer_mouse_exited() -> void:
	if not Global.turn_phase == Global.TurnPhase.COMBAT:
		ui_animation_player.play_backwards("grow_battler")


func _on_BattlerContainer_gui_input(event: InputEvent) -> void:
	# this is used during the players turn phase for picking targets
	# its a bit awkard to account for deselecting unit by clicking outside the parent
	# so you can pick targets in any order you'd like
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.is_pressed():
			if Global.turn_phase == Global.TurnPhase.TARGET:
				if get_parent().get_parent().get_parent().current_attacker == self  and (action_choice.name == 'Miss' or target):
					return
				if not get_parent().get_parent().get_parent().current_attacker and (action_choice.name == 'Miss' or target):
					return
				if get_parent().get_parent().get_parent().current_attacker and not get_parent().get_parent().get_parent().current_attacker.action_choice.name == 'Miss':
					emit_signal("target_selected", self)
				elif not get_parent().get_parent().get_parent().current_attacker and not action_choice.name == 'Miss':
					get_parent().get_parent().get_parent().set_current_attacker(self)
