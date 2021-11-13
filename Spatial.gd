extends Spatial

var rerolls: int = 2


func _on_Button_pressed() -> void:
	set_reroll(1)
	var dice = get_tree().get_nodes_in_group("die")
	for die in dice:
		die.apply_impulse(die.translation, Vector3(0,0,5))


func set_reroll(amount) -> void:
	rerolls -= amount
	if rerolls <= 0:
		$Button.set_disabled(true)
		rerolls = 0
