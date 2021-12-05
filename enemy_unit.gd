extends "res://character_unit.gd"

func _on_Tween_tween_all_completed() -> void:
	die_ref = die
	die.sleeping = true
	die.reset()
	if face_choice: 
		remove_child(die)
		get_node("CharacterDisplay/TextureRect/ActionChoice").texture = face_choice.texture.duplicate()
	
func _on_Selected(action: Action):
	die_selected = true
	
	tween.interpolate_property(die, "scale",
		die.scale, Vector3(0,0,0), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(-19, action_container.rect_position.y), .3,
		Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	face_choice = action

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
	set_enemy_target(str(target_choice), target_party)

func set_enemy_target(choice, side):
	if int( choice ) == -1:
		return
	if side:
		target = get_parent().get_node("../PlayerUnits/"+choice)
	else:
		target = get_parent().get_node(str(int(choice)+ 5))
	target_selected = true

func reset():
	die_selected = false
	target = null
	face_choice = null
	target_selected = false
	get_node("CharacterDisplay/TextureRect/ActionChoice").set_texture(null)
	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(4, action_container.rect_position.y), .3,
		Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()

func action_tween_start():
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x - 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end():
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x + 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()
