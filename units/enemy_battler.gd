extends Battler
class_name Enemy


func choose_target():
#	total amount of possible targets
	var target_range: int
#	random number chosen from target_range
	var target_choice: int
#	true is player only changes if action is a hostile action
	var target_party: bool = false
	if action_choice.hostile:
#		true = player
		target_party = true
#		get the amount of players
		target_range = get_tree().get_nodes_in_group("player").size()
	else:
#		if not hostile, get the amount of enemy nodes. Could be called differently
		target_range = get_parent().get_children().size()
#	TODO : add logic for multiple targets. target_choice should probably be a list.
	if action_choice.targets > 0:
#		pick a random target based of amount of target nodes
#		this number will be used to match to the name of the target node. THIS
#		is what i was talking about
#		TODO: this was the flimsy part I was talking about. Need a more elegant way
		target_choice = randi() % target_range + 1
	else:
		target_choice = -1
#	sets the target. probably an overlap function with character_unit.gd
	set_enemy_target(str(target_choice), target_party)


func set_enemy_target(choice: String, side: bool):
#	AH this is what i was pondering about in main.gd about the whole target_selected
#	thing. choice is the action: "Miss" than ts a -1 and just returns. So target 
#	is null. Player gets set to null if a miss in main.gd
	if int(choice) == -1:
		return
	if side:
		target = get_parent().get_node("../PlayerBattlers/"+ choice)
	else:
		target = get_parent().get_node(str(int(choice) + 5))
#	like i said about target_selected above, and in main.gd as far as the enemy
#	goes i dont really name a trigger or anything. The target choice is essentially
#	instantaneous.
	target_selected = true


func roll_die():
	die = preload("res://dice/CharacterDie.tscn").instance()
	add_child(die)
#	this is where i fixed the bug. gets triggered when the die emits the signal stopped.
#	i moved the roll determination to physics process and stop the physics process
#	after the stopped signal is called. The die gets freed when selected and 
#	when it gets rolled again the physics_process gets set to true on ready()
	die.connect("roll_set", self, "_on_RollSet")
#	(re)builds the die. Could be built once the first time and stored in a reference
#	instead of rebuilding every round but due to reasons above, probably be to
#	leave it. Although we could remove_child() instead of queue_free(). Idk.
	die.build_die(die_faces, color)
#	apply a random push(?) so each die falls differently. Not positive this works
	die.apply_impulse(die.translation, Vector3(randf(),randf(),randf()))


func _on_RollSet(action: Action):
#	see this should be the action_selected function that sits empty somehwere in here
#	called as a player only. Enemy units do not use this, they use _on_RollSet()
#	called when a player clicks on their die on roll phase
	die.disappear()
	action_choice_texture.set_texture(action.texture)
	ui_animation_player.play("show_action_container")
#	sets the current action that you selected
	action_choice = action
#	triggers _on_TargetsSelected() in units.gd
	emit_signal("action_selected", false)


func action_tween_start():
#	the combat tween the slides the whole characterunit control node forward
	action_tween.interpolate_property(battler_container, 'rect_position', null,
	Vector2(battler_container.rect_position.x - 30, battler_container.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end():
#	the combat tween the slides the whole characterunit control node backward
	action_tween.interpolate_property(battler_container, 'rect_position', null,
	Vector2(battler_container.rect_position.x + 30, battler_container.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()



