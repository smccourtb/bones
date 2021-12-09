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
#	if theres still a die kicking around for whatever reason, use that.
	if is_instance_valid(die):
		add_child(die)
	else:
#		if not, spin up a new instance
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
#	This makes the die shrink into nothingness on selection. same thing as
#	_on_Selected under character_die.gd
	tween.interpolate_property(die, "scale",
		die.scale, Vector3(0,0,0), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#	this slides that box out from behind the CharacterUnit control node
#	TODO: move to own function with a parameter for the first position in the 
#	vector2 (-19). That way it can be used on either side. 
	action_container.set_scale(Vector2(0,0))
	action_container.set_visible(true)
	tween.interpolate_property(action_container, "rect_scale",
		null, Vector2(1,1), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
#	sets the action. action_choice is a stupid variable name and will be replaced soon
	action_choice = action
#	trigger the signal so actionsSelected add it to the count so it can trigger
#	the signal actions_selected for main.gd. Yes the signal names are too similar
#	and cause me confusion maybe the other one should be called all_actions_selected.
#	I usually run a signal bus and i may just do that here. this is a way more
#	signal based game than i've done before
	emit_signal("action_selected", false)


func reset():
#	resets all variables to what they started with
	target = null
	action_choice = null
	target_selected = false
	
	# removes texture from action choice
	get_node("CharacterDisplay/TextureRect/ActionChoice").set_texture(null)
	# sets action container behind character display
	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(4, action_container.rect_position.y), .3,
		Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()


func action_tween_start():
#	the combat tween the slides the whole characterunit control node forward
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x - 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end():
#	the combat tween the slides the whole characterunit control node backward
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x + 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()

