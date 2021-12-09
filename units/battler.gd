extends Control
class_name Battler
# connected to: units.gd - during _setup_player and _setup_enemy

# triggered when A) a die is clicked on during the roll phase (player)
#				    also in main.gd during _on_targetPhase_begin() IF the player
#					characters action choice is a "Miss"
# 				 B) when _on_RollSet() is triggered in enemy_units.gd
signal action_selected(who) # player = true | enemy = false



# stats that are set by die_data in initialize()
var health: int
var defense: int
# current actions on the die
var die_faces := {}
# the choice that was set by clicking on the die in the roll phase
var action_choice: Action
var target_selected: bool = false
# node ref to the target of the action
var target = null
# set when a player is choose a target. if applicable
var targetable: bool = false
# used to set the die color
var color: Color
# unused variable that was used for death of a character but remains if I
# implement status effects and need a disable toggle (sleep)
var disabled: bool = false
# ref to a die instance
onready var die = preload("res://dice/CharacterDie.tscn").instance()

# the combat - slide forward and back animation
onready var action_tween = get_node("Action")
onready var tween = get_node("Tween")
# animation node ref for the character sprites animations
onready var sprite = get_node("BattlerContainer/Human/AnimationPlayer")
# the main container under the root control node
onready var battler_container = $BattlerContainer
# the container tht holds the name and stats
#onready var character_container = get_node("CharacterDisplay/CharacterContainer")
# holds stat ui and info
onready var stat_container = $BattlerContainer/StatContainer
# the square the slides out from behind battler_container when an action is chosen
onready var action_container = get_node("BattlerContainer/ActionContainer")
# red recticle that grows and shrinks when targeted
onready var target_indicator = get_node("BattlerContainer/ActionContainer/Targeted")
# ui animation player
onready var ui_animation_player = get_node("AnimationPlayer")

onready var health_icon_label = $BattlerContainer/StatContainer/HealthContainer/HealthIcon/HeathLabel
onready var action_choice_texture = $BattlerContainer/ActionContainer/ActionChoice

func initialize(data: Character, die_color: Color, ui_color: String) -> void:
#	TODO: i think i can move the color dictionaries, the one with the codes
#	into this script so i dont have to pass a separate variable.
#	this is the one to move into something else
	color = die_color
#	this is here so they can load dynamically. 
	battler_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
#	character_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
#	action_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
#	 trying to implement setters and getters for things so they are more clean
	set_health(data.health)
	set_defense(data.defense)
	
#	base die is a level 0 die and actions to represent that. just a dict of actions
#	the 'base die' comes with. Also has a possible pool array for unlocking in the
# 	future. Haven't gotten there yet so its not apparent here atm.
	die_faces = data.base_die


func set_health(health_mod: int) -> void:
	var new_health = self.health + health_mod
	if new_health < 0:
		new_health = 0
	self.health = new_health
	update_health_ui()
	if self.health < 1:
		_die()


func get_health() -> int:
	return self.health


func update_health_ui():
	health_icon_label.set_text(str(get_health()))


func set_defense(defense_mod: int) -> void:
	var new_defense = defense + defense_mod
	if new_defense < 0:
		new_defense = 0
	defense = new_defense
	update_defense_ui()


func get_defense() -> int:
	return self.defense


func update_defense_ui():
	var defense_label = stat_container.get_node("DefenseContainer/DefenseIcon/DefenseLabel")
	defense_label.set_text(str(get_defense()))


func set_target_selected(value: bool):
	target_selected = value


func set_target(new_target):
#	setter function for battler target.
#	set target selected plays some animations and disconnects mouse over signals
	if new_target:
		target = new_target
		set_target_selected(true)
	else:
		target = null
		set_target_selected(false)


func take_damage(damage: int) -> void:
	var actual_damage = get_defense() - damage
	if actual_damage <= 0:
		set_defense(-get_defense())
		set_health(actual_damage)
	else:
		set_defense(-(damage))
	sprite.play("Hurt")
	yield(sprite, "animation_finished")
	sprite.play("Idle")



func _die() -> void:
	sprite.play("Die")
	yield(sprite, "animation_finished")
#	TODO: probably add some sort of ui animation in here
	queue_free()


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


func set_targetable(value: bool) -> void:
#	a player is picking a target and the character is targetable
	targetable = value


func set_current_attacker(new_value: bool):
	# Sets node to be current attacker
	if new_value:
#		slides the character display forward a bit
		tween.interpolate_property(battler_container, "rect_position",
		null, Vector2(battler_container.rect_position.x+10, battler_container.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		get_possible_targets()
	
	else:
#		slides it back
		tween.interpolate_property(battler_container, "rect_position",
		null, Vector2(battler_container.rect_position.x-10, battler_container.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func action():
#	this function will get bigger and more detailed in the future. the perform
#	action logic. the mothods it calls are the recieving action logic
	if action_choice.sound:
		SFX.play(action_choice.sound) # Play action sound when triggered
	if action_choice.hostile:
		sprite.play("Attack")
		yield(sprite, "animation_finished")
		sprite.play("Idle")
		target.take_damage(action_choice.base_amount)
	elif action_choice.heal:
		target.set_health(action_choice.base_amount)
	elif action_choice.block:
		target.set_defense(action_choice.base_amount)


func reset():
#	called during the combatPhase_end()
	target = null
	action_choice = null
	set_target(false)
#	 removes texture from action_container
	action_choice_texture.set_texture(null)


func action_tween_start() -> void:
#	sliding forward combat animation
	action_tween.interpolate_property(battler_container, 'rect_position', null,
	Vector2(battler_container.rect_position.x + 30, battler_container.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end() -> void:
#	sliding back combat animation
	action_tween.interpolate_property(battler_container, 'rect_position', null,
	Vector2(battler_container.rect_position.x - 30, battler_container.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func _on_ActionContainer_mouse_entered() -> void:
	# on mouse over of action container, display characters targets
	pass


func _on_ActionContainer_mouse_exited() -> void:
	#	 stop the target recticle
	pass
