extends Control

# connected to: units.gd - during _setup_player and _setup_enemy

# triggered when A) a die is clicked on during the roll phase (player)
#				    also in main.gd during _on_targetPhase_begin() IF the player
#					characters action choice is a "Miss"
# 				 B) when _on_RollSet() is triggered in enemy_units.gd
signal action_selected(who) # player = true | enemy = false

# connected to: units.gd - during _setup_player and _setup_enemy
# triggered when A) a player character is a current_attacker(units.gd) and player
#					clicks on a valid target
signal target_selected # only pertains to players

# stats that are set by die_data in initialize()
var health: int
var defense: int
# current actions on the die
var die_faces := {}
# the choice that was set by clicking on the die in the roll phase
var face_choice: Action
# useless bool i think
var die_selected: bool = false
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
# animations when the ability to be targeted is true. used in tandem while 
# targetable is true
onready var target_grow_tween = get_node("CharacterDisplay/TargetGrow")
onready var target_shrink_tween = get_node("CharacterDisplay/TargetShrink")
# the combat - slide forward and back animation
onready var action_tween = get_node("CharacterDisplay/Action")
onready var tween = get_node("CharacterDisplay/Tween")
# animation node ref for the character sprites animations
onready var sprite = get_node("CharacterDisplay/CharacterContainer/Human/AnimationPlayer")
# used to represent character health
onready var health_icon = preload("res://scenes/HealthIcon.tscn")
# the main container under the root control node
onready var character_display = get_node("CharacterDisplay")
# the container tht holds the name and stats
onready var character_container = get_node("CharacterDisplay/CharacterContainer")
# holds stat ui and info
onready var stat_container = get_node("CharacterDisplay/VBoxContainer/StatContainer")
# the square the slides out from behind character_display when an action is chosen
onready var action_container = get_node("CharacterDisplay/TextureRect")
# red recticle that grows and shrinks when targeted
onready var target_indicator = get_node("CharacterDisplay/TextureRect/Targeted")


func _ready() -> void:
#	i need to connect to these to be ble to trigger them in the first place.
#	they are empty functions. units.gd is listening on them.
	connect("target_selected", self, "_on_TargetSelected")
	connect("action_selected", self, "_on_ActionSelected")
#	sets the sprite to play the animation on load
	sprite.play("Idle")

# TODO: ready could probably be dumped and things moved over to initialize()

func initialize(data: Character, die_color: Color, ui_color: String) -> void:
#	TODO: i think i can move the color dictionaries, the one with the codes
#	into this script so i dont have to pass a separate variable.
#	this is the one to move into something else
	color = die_color
#	this is here so they can load dynamically. 
	character_display.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	character_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	action_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
#	 trying to implement setters and getters for things so they are more clean
	set_health(data.health)
#	base die is a level 0 die and actions to represent that. just a dict of actions
#	the 'base die' comes with. Also has a possible pool array for unlocking in the
# 	future. Haven't gotten there yet so its not apparent here atm.
	die_faces = data.base_die


func set_health(new_health: int) -> void:
	self.health = new_health
	update_health_ui()


func set_target_selected(value: bool):
	if value:
#		Shrinks the entire CharacterUnit to indicate a target has been selected
#		and it is out of active state
		tween.interpolate_property($CharacterDisplay, "rect_scale",
			null, Vector2(.9, .9), 1,
			Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
		tween.start()
	target_selected = value
#	disconnects the mouse over signals of the CharacterUnit so it wont appear 
#	active anymore
	if character_display.is_connected("mouse_entered", self, "_on_CharacterDisplay_mouse_entered"):
		character_display.disconnect("mouse_entered", self, "_on_CharacterDisplay_mouse_entered")
		character_display.disconnect("mouse_exited", self, "_on_CharacterDisplay_mouse_exited")


func update_health_ui():
#	TODO: change to either queue_free() some nodes or instance and add some nodes
#	its jarring right now, you can see a quick flash from the wipe and refill
	for n in stat_container.get_children():
#		deletes all heart icons in stat container
		n.queue_free()
	if health == 0:
		return
	for _i in range(health):
#		adds back as many as equal to health value
		var health_ui = health_icon.instance()
		stat_container.add_child(health_ui)


func get_health() -> int:
	return self.health


func set_target(new_target):
#	setter function for target variable.
#	set target selected plays some animations and disconnects mouse over signals
	if new_target:
		target = new_target
		set_target_selected(true)
	else:
		target = null
		set_target_selected(false)


func take_damage(damage: int) -> void:
#	TODO: take characters defense into account when setting health
#	use set defense function
	sprite.play("Hurt")
	yield(sprite, "animation_finished")
	sprite.play("Idle")
	var new_health: int = health + defense - damage
	if new_health > 0:
		set_health(new_health)
	else:
		_die()


func set_defense(new_defense: int) -> void:
	defense = new_defense

func get_defense() -> int:
	return defense

func _die() -> void:
	sprite.play("Die")
	yield(sprite, "animation_finished")
#	TODO: probably add some sort of ui animation in here
	queue_free()


func _on_Selected(action: Action):
#	see this should be the action_selected function that sits empty somehwere in here
#	called as a player only. Enemy units do not use this they use _on_RollSet()
#	called when a player clicks on their die on roll phase
	die_selected = true
#	action_container sits behind character_display when not active. setting
#	visibilty is not necessary but just seems right to do it anyways
	action_container.set_visible(true)
#	die dissapear after being clicked
	tween.interpolate_property(die, "scale",
		die.scale, Vector3(0,0,0), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#	slide out 'action' drawer
	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(99, action_container.rect_position.y), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
#	sets the current action that you selected
	face_choice = action
#	triggers _on_TargetsSelected() in units.gd
	emit_signal("action_selected", true)


func roll_die():
	if is_instance_valid(die):
		add_child(die)
	else:
		die = preload("res://dice/CharacterDie.tscn").instance()
		add_child(die)
#	triggered when clicking on the die during roll phase
	die.connect("die_selected", self, "_on_Selected")
#	map actions to die and set textures. set it up and add it to the tree
	die.build_die(die_faces, color)
#	apply a random push(?) so each die falls differently. Not positive this works
	die.apply_impulse(die.translation, Vector3(randf(),randf(),randf()))


func get_possible_targets():
	# this is barebones right now but only sets an animation the scaling character
	# container.
	var targets
	if face_choice.hostile:
		targets = get_tree().get_nodes_in_group("enemy")
	else:
		targets = get_tree().get_nodes_in_group("player")
	for target in targets:
		target.set_targetable(true)


func set_targetable(value: bool) -> void:
#	used an animation player for this instead of a tween like everything else ui
#   related. Not sure if im keeping it. Probably better for consistency to change
#	to a tween and leave animation player for characte sprites. OR switch
#	completely over to animation players for the signals and whatnot

#	grows and shrinks the character container (the one with the sprite) when
#	a player is picking a target and the character is targetable
	targetable = value
	if targetable:
		get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").play("targetable")
	else:
		if  get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").current_animation:
			 get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").seek(0, true)
			 get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").stop(true)


func _on_CharacterDisplay_gui_input(event: InputEvent) -> void:
	# this is used during the players turn phase for picking targets
	# its a bit awkard to account for deselecting unit by clicking outside the parent
	# so you can pick targets in any order you'd like
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.is_pressed():
			if Global.turn_phase == "target":
				if get_parent().get_parent().current_attacker == self  and (face_choice.name == 'Miss' or target):
					return
				if not get_parent().get_parent().current_attacker and (face_choice.name == 'Miss' or target):
					return
				if get_parent().get_parent().current_attacker and not get_parent().get_parent().current_attacker.face_choice.name == 'Miss':
					emit_signal("target_selected", self)
				elif not get_parent().get_parent().current_attacker and not face_choice.name == 'Miss':
					get_parent().get_parent().set_current_attacker(self)


func _on_TargetSelected(_who):
#	this is only here because I think i need to provide a method when connecting
#	to a signal. I connect through this node from units.gd.
	pass


func _on_ActionSelected(_who):
#	this is only here because I think i need to provide a method when connecting
#	to a signal. I connect through this node from units.gd.
	pass


func set_selected(new_value: bool):
	# Sets node to be current attacker
	if new_value:
#		slides the character display forward a bit
		tween.interpolate_property(character_display, "rect_position",
		null, Vector2(character_display.rect_position.x+10, character_display.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		get_possible_targets()
	
	else:
#		slides it back
		tween.interpolate_property(character_display, "rect_position",
		null, Vector2(character_display.rect_position.x-10, character_display.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func action():
#	this function will get bigger and more detailed in the future. the perform
#	action logic. the mothods it calls are the recieving action logic
	if face_choice.sound:
		SFX.play(face_choice.sound) # Play action sound when triggered
	if face_choice.hostile:
		sprite.play("Attack")
		yield(sprite, "animation_finished")
		sprite.play("Idle")
		target.take_damage(face_choice.base_amount)
	elif face_choice.heal:
		target.set_health(target.get_health() + face_choice.base_amount)
	elif face_choice.block:
		target.set_defense(face_choice.base_amount)


func reset():
#	called during the combatPhase_end()
	die_selected = false
	target = null
	face_choice = null
#	THAT BUG COULD BE IN HERE TOO IDK this lsides the character back 10 px
#	and the container is off by 10px
	set_target_selected(false)
	character_display.connect("mouse_entered", self, "_on_CharacterDisplay_mouse_entered")
	character_display.connect("mouse_exited", self, "_on_CharacterDisplay_mouse_exited")
#	 removes texture from action_container
	action_container.get_node("ActionChoice").set_texture(null)
#	i believe 75 is that starting position for players.
	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(75, action_container.rect_position.y), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#	make sure the scale is where its supposed to be (for character with a miss 
#	that were shrunk)
	tween.interpolate_property(character_display, "rect_scale",
		null, Vector2(1, 1), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_CharacterDisplay_mouse_entered() -> void:
#	TODO: check if target phase and only activate during that
#	and im not sure why im checking for target_selected
	if target_selected:
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(1, 1), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	else:
#		grow a bit to let you know it has an action it wants to spend during 
#	the target phase
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(1.1, 1.1), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_CharacterDisplay_mouse_exited() -> void:
#	same thing as mouse_entered
	if target_selected:
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(.9, .9), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	else:
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(1, 1), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_Tween_tween_completed(object: Object, _key: NodePath) -> void:
#	this is only here to signal when its okay to set the texture in the action
#	container. Could be hooked up differently. im tired atm so i dont have a todo.
	if object is RigidBody:
		if face_choice: 
			get_node("CharacterDisplay/TextureRect/ActionChoice").texture = face_choice.texture.duplicate()
		die.queue_free()


func _on_TextureRect_mouse_entered() -> void:
	# on mouse over of action container, display characters targets
	if target_selected && face_choice.name != "Miss":
		target.target_indicator.set_visible(true)
		target.targeted_grow()


func _on_TextureRect_mouse_exited() -> void:
#	 stop the target recticle
	if target_selected && face_choice.name != "Miss":
		target.target_indicator.set_visible(false)
		target.target_grow_tween.stop_all()
		target.target_shrink_tween.stop_all()
		

func action_tween_start() -> void:
#	sliding forward combat animation
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x + 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end() -> void:
#	sliding back combat animation
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x - 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func targeted_grow() -> void:
#	the target recticle animation.. grow
	target_grow_tween.interpolate_property(target_indicator, "rect_scale", null, Vector2(1.1, 1.1),
	.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	target_grow_tween.start()


func targeted_shrink() -> void:
#	the target recticle animation.. shrink
	target_shrink_tween.interpolate_property(target_indicator, "rect_scale", null, Vector2(1, 1),
	.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	target_shrink_tween.start()

# these 2 are used to bounce back and forth until told to stop in the
# mouse exited function
func _on_TargetGrow_tween_completed(_object: Object, _key: NodePath) -> void:
	targeted_shrink()


func _on_TargetShrink_tween_completed(_object: Object, _key: NodePath) -> void:
	targeted_grow()
