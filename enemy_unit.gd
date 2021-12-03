extends "res://character_unit.gd"

func _on_Tween_tween_all_completed() -> void:
	die_ref = die
	die.sleeping = true
	die.reset()
	if face_choice: 
		remove_child(die)
		get_node("CharacterDisplay/ActionChoice").texture = face_choice.texture.duplicate()

func _on_Selected(action: Action):
	selected = true
	tween.interpolate_property(die, "scale",
		die.scale, Vector3(0,0,0), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property($CharacterDisplay, "margin_left",
		$CharacterDisplay.margin_left, -125, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	face_choice = action
#	emit_signal("action_selected", false)

func choose_target():
	var target_range: int
	var target_choice: int
	var target_party: bool = false
	if face_choice.hostile:
		target_party = true
		target_range = get_tree().get_nodes_in_group("player").size()
	else:
		target_range = get_parent().get_children().size()
	if face_choice.targets > 0:
		target_choice = randi() % target_range + 1
	else:
		target_choice = -1
	set_target(str(target_choice), target_party)
	emit_signal("target_selected", false)
	
	
	

func set_target(choice, side):
	if int( choice ) == -1:
		return
	if side:
		target = get_parent().get_node("../PlayerUnits/"+choice)
	else:
		target = get_parent().get_node(str(int(choice)+ 5))

func reset():
	selected = false
	target = null
	face_choice = null
	get_node("CharacterDisplay/ActionChoice").set_texture(null)
	tween.interpolate_property($CharacterDisplay, "margin_left",
		$CharacterDisplay.margin_left, -104, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
