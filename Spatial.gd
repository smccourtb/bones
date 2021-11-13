extends Spatial

signal stopped

var rolling: bool = false


#onready var walls = [$"CSGBox2", $"CSGBox3", $"CSGBox4", $"CSGBox5"]
#onready var raycasts = [$"RigidBody/6", $"RigidBody/5"]
var roll: int
func _ready() -> void:
	connect("stopped", self, "_on_Stopped")
#	for i in walls:
#		for j in raycasts:
#			j.add_exception(i)

func _on_Stopped():
	if $'CharacterDie/6'.is_colliding():
		roll = 6
	elif $'CharacterDie/5'.is_colliding():
		roll = 5
	elif $'CharacterDie/1'.is_colliding():
		roll = 1
	elif $'CharacterDie/3'.is_colliding():
		roll = 3
	elif $'CharacterDie/4'.is_colliding():
		roll = 4
	elif $'CharacterDie/2'.is_colliding():
		roll = 2
	
		
func _physics_process(delta: float) -> void:
	if $CharacterDie.linear_velocity.length() < 2:
		emit_signal("stopped")
		


func _on_RigidBody_input_event(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		print("clicked")


func _on_RigidBody_mouse_entered() -> void:
	print(true)


func _on_Button_pressed() -> void:
	rolling = true
	var die = get_node("CharacterDie")
	die.apply_impulse(die.translation, Vector3(0,0,3))
	
