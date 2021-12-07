extends Control

signal action_selected(who)
signal target_selected

var health: int
var defense: int

var die_faces := {}
var face_choice: Action
var die_selected: bool = false
var target_selected: bool = false
var target = null
var targetable: bool = false
var color: Color

var disabled: bool = false

onready var die = preload("res://dice/CharacterDie.tscn").instance()

onready var target_grow_tween = get_node("CharacterDisplay/TargetGrow")
onready var target_shrink_tween = get_node("CharacterDisplay/TargetShrink")

onready var action_tween = get_node("CharacterDisplay/Action")
onready var tween = get_node("CharacterDisplay/Tween")
onready var sprite = get_node("CharacterDisplay/CharacterContainer/Human/AnimationPlayer")
onready var health_icon = preload("res://scenes/HealthIcon.tscn")
onready var character_display = get_node("CharacterDisplay")
onready var character_container = get_node("CharacterDisplay/CharacterContainer")
onready var stat_container = get_node("CharacterDisplay/VBoxContainer/StatContainer")
onready var action_container = get_node("CharacterDisplay/TextureRect")
onready var target_indicator = get_node("CharacterDisplay/TextureRect/Targeted")


func _ready() -> void:
	connect("target_selected", self, "_on_TargetSelected")
	connect("action_selected", self, "_on_ActionSelected")
	sprite.play("Idle")


func initialize(data: Character, die_color: Color, ui_color: String) -> void:
	color = die_color
	character_display.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	character_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	action_container.texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	set_health(data.health)
	die_faces = data.base_die


func set_health(new_health: int) -> void:
	self.health = new_health
	update_health_ui()


func set_target_selected(value: bool):
	if value:
		tween.interpolate_property($CharacterDisplay, "rect_scale",
			null, Vector2(.9, .9), 1,
			Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
		tween.start()
	target_selected = value
	if character_display.is_connected("mouse_entered", self, "_on_CharacterDisplay_mouse_entered"):
		character_display.disconnect("mouse_entered", self, "_on_CharacterDisplay_mouse_entered")
		character_display.disconnect("mouse_exited", self, "_on_CharacterDisplay_mouse_exited")


func update_health_ui():
	for n in stat_container.get_children():
		n.queue_free()
	if health == 0:
		return
	for _i in range(health):
		var health_ui = health_icon.instance()
		stat_container.add_child(health_ui)


func get_health() -> int:
	return self.health


func set_target(new_target):
	if new_target:
		target = new_target
		set_target_selected(true)
	else:
		target = null
		set_target_selected(false)


func take_damage(damage: int) -> void:
	sprite.play("Hurt")
	yield(sprite, "animation_finished")
	sprite.play("Idle")
	var new_health: int = health - damage
	if new_health > 0:
		set_health(new_health)
	else:
		_die()


func set_defense(new_defense: int) -> void:
	defense = new_defense


func _die() -> void:
	sprite.play("Die")
	yield(sprite, "animation_finished")
	set_modulate(Color(1,1,1,.5))
	queue_free()
	disabled = true


func _on_Selected(action: Action):
	die_selected = true
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
	
	face_choice = action
	emit_signal("action_selected", true)


func enter_roll_phase():
	if is_instance_valid(die):
		add_child(die)
	else:
		die = preload("res://dice/CharacterDie.tscn").instance()
		add_child(die)
	die.connect("die_selected", self, "_on_Selected")
	die.build_die(die_faces, color)
	die.apply_impulse(die.translation, Vector3(randf(),randf(),randf()))


func get_possible_targets():
	var targets
	if face_choice.hostile:
		targets = get_tree().get_nodes_in_group("enemy")
	else:
		targets = get_tree().get_nodes_in_group("player")
	for i in targets:
		i.set_targetable(true)


func set_targetable(value):
	targetable = value
	if targetable:
		get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").play("targetable")
	else:
		if  get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").current_animation:
			 get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").seek(0, true)
			 get_node("CharacterDisplay/CharacterContainer/AnimationPlayer").stop(true)


func _on_CharacterDisplay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			if Global.turn_phase == "target":
				if get_parent().get_parent().current_attacker == self  && (face_choice.name == 'Miss' || target):
					return
				if !get_parent().get_parent().current_attacker && (face_choice.name == 'Miss' || target):
					return
				if get_parent().get_parent().current_attacker && get_parent().get_parent().current_attacker.face_choice.name != 'Miss':
					emit_signal("target_selected", self)
				elif !get_parent().get_parent().current_attacker && face_choice.name != 'Miss':
	
					get_parent().get_parent().set_current_attacker(self)


func _on_TargetSelected(_who):
	pass


func _on_ActionSelected(_who):
	pass


func set_selected(new_value: bool):
	# Sets node to be current attacker
	if new_value:
		tween.interpolate_property(character_display, "rect_position",
		null, Vector2(character_display.rect_position.x+10, character_display.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		get_possible_targets()
	
	else:
		tween.interpolate_property(character_display, "rect_position",
		null, Vector2(character_display.rect_position.x-10, character_display.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func action():
	if face_choice.hostile:
		sprite.play("Attack")
		yield(sprite, "animation_finished")
		sprite.play("Idle")
		target.take_damage(face_choice.base_amount)
	if face_choice.heal:
		target.set_health(target.get_health() + face_choice.base_amount)
	if face_choice.block:
		target.set_defense(face_choice.base_amount)
	else:
		return


func reset():
	die_selected = false
	target = null
	face_choice = null
	set_target_selected(false)
	character_display.connect("mouse_entered", self, "_on_CharacterDisplay_mouse_entered")
	character_display.connect("mouse_exited", self, "_on_CharacterDisplay_mouse_exited")
	
	get_node("CharacterDisplay/TextureRect/ActionChoice").set_texture(null)
	tween.interpolate_property(action_container, "rect_position",
		null, Vector2(75, action_container.rect_position.y), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(character_display, "rect_scale",
		null, Vector2(1, 1), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_CharacterDisplay_mouse_entered() -> void:
	if target_selected:
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(1, 1), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	else:
		tween.interpolate_property(character_display, "rect_scale",
			null, Vector2(1.1, 1.1), .3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_CharacterDisplay_mouse_exited() -> void:
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
	if object is RigidBody:
		if face_choice: 
			get_node("CharacterDisplay/TextureRect/ActionChoice").texture = face_choice.texture.duplicate()
		die.queue_free()


func _on_TextureRect_mouse_entered() -> void:
	# on mouse over of action choice, display characters targets
	if target_selected && face_choice.name != "Miss":
		target.target_indicator.set_visible(true)
		target.targeted_grow()


func _on_TextureRect_mouse_exited() -> void:
	if target_selected && face_choice.name != "Miss":
		target.target_indicator.set_visible(false)
		target.target_grow_tween.stop_all()
		target.target_shrink_tween.stop_all()
		

func action_tween_start():
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x + 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func action_tween_end():
	action_tween.interpolate_property(character_display, 'rect_position', null,
	Vector2(character_display.rect_position.x - 30, character_display.rect_position.y), .3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	action_tween.start()


func targeted_grow():
	print('hello')
	target_grow_tween.interpolate_property(target_indicator, "rect_scale", null, Vector2(1.1, 1.1),
	.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	target_grow_tween.start()


func targeted_shrink():
	print('goodbye')
	target_shrink_tween.interpolate_property(target_indicator, "rect_scale", null, Vector2(1, 1),
	.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	target_shrink_tween.start()


func _on_TargetGrow_tween_completed(_object: Object, _key: NodePath) -> void:
	targeted_shrink()


func _on_TargetShrink_tween_completed(_object: Object, _key: NodePath) -> void:
	targeted_grow()
