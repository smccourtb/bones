extends Control

signal action_selected(who)
signal target_selected

var health: int
var defense: int
var die_faces := {}
var face_choice: Action
var selected: bool = false
var color: Color
var die_data: Dictionary
var target = null
var die_ref
var disabled: bool = false

var line
onready var die = preload("res://CharacterDie.tscn").instance()

onready var tween = get_node("CharacterDisplay/Tween")
onready var sprite = get_node("CharacterDisplay/CharacterContainer/Human/AnimationPlayer")
onready var health_icon = preload("res://HealthIcon.tscn")


func _ready() -> void:
	connect("target_selected", self, "_on_TargetSelected")
	connect("action_selected", self, "_on_ActionSelected")
	
	
	sprite.play("Idle")
	

func initialize(data: Character, die_color: Color, ui_color: String) -> void:
	color = die_color
	get_node("CharacterDisplay").texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	get_node("CharacterDisplay/CharacterContainer").texture.atlas = load("res://assets/ui/panels_" + ui_color + ".png")
	
	set_health(data.health)
	die_data = data.base_die

func set_health(new_health: int) -> void:
	self.health = new_health
	update_health_ui()
	

func update_health_ui():
	var node = get_node("CharacterDisplay/StatContainer")
	for n in node.get_children():
		n.queue_free()
	if health == 0:
		return
	for i in range(health):
		var health_ui = health_icon.instance()
		node.add_child(health_ui)

func get_health() -> int:
	return self.health


func take_damage(damage: int) -> void:
	sprite.play("Hurt")
	yield(sprite, "animation_finished")
	sprite.play("Idle")
	var new_health: int = health - damage
	if new_health > 0:
		set_health(new_health)
	else:
		die()

func set_defense(new_defense):
	defense = new_defense

func die() -> void:
	sprite.play("Die")
	yield(sprite, "animation_finished")
	set_modulate(Color(1,1,1,.5))
	disabled = true


func _on_Selected(action: Action):
	selected = true
#	tween.interpolate_property(die, "translation",
#		die.translation, die.starting_position, 1,
#		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(die, "scale",
		die.scale, Vector3(0,0,0), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property($CharacterDisplay, "rect_size",
		$CharacterDisplay.rect_size, Vector2(125, $CharacterDisplay.rect_size.y), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	face_choice = action
	emit_signal("action_selected", true)


func _on_Tween_tween_all_completed() -> void:
	die_ref = die
	die.sleeping = true
	die.reset()
	
	if face_choice: 
		remove_child(die)
		get_node("CharacterDisplay/ActionChoice").texture = face_choice.texture.duplicate()

func _physics_process(delta: float) -> void:
	if is_instance_valid(line):
		line.points[1] = get_local_mouse_position()

func enter_roll_phase():
	if die_ref:
		add_child(die_ref)
		die_ref.reset()
		die_ref.sleeping = false
	else:
		add_child(die)
		die.connect("selected", self, "_on_Selected")
		die.build_die(die_data, color)
		die.sleeping = false
		randomize()
		die.apply_impulse(die.translation, Vector3(randf(),randf(),randf()))

func choose_target():
	print("hi")
	set_selected(true)
#	get_possible_targets()
	line = Line2D.new()
	add_child(line)
	line.points = [$Position2D.position, get_global_mouse_position()]
	line.width=2
	
	
func get_possible_targets():
	if face_choice.hostile:
		var targets = get_tree().get_nodes_in_group("enemy")
		for i in targets:
			i.set_selected(true)
			


func _on_CharacterDisplay_gui_input(event: InputEvent) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
#		set_selected(false)
		emit_signal("target_selected", self)
		
		

func _on_TargetSelected(who):
	pass

func _on_ActionSelected(who):
	pass
	
func set_selected(new_value: bool):
	if new_value:
		tween.interpolate_property($CharacterDisplay, "rect_position",
		$CharacterDisplay.rect_position, Vector2($CharacterDisplay.rect_position.x+25, $CharacterDisplay.rect_position.y), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	else:
		tween.interpolate_property($CharacterDisplay, "rect_position",
		$CharacterDisplay.rect_position, Vector2($CharacterDisplay.rect_position.x-25, $CharacterDisplay.rect_position.y), .3,
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
	selected = false
	target = null
	face_choice = null
	get_node("CharacterDisplay/ActionChoice").set_texture(null)
	tween.interpolate_property($CharacterDisplay, "rect_size",
		$CharacterDisplay.rect_size, Vector2(110, $CharacterDisplay.rect_size.y), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
