extends RigidBody

signal stopped

var roll: int
var faces: Dictionary = {1: "miss",
						 2: "attack",
						 3: "attack",
						 4: "defend",
						 5: "miss",
						 6: "heal"}

func _ready() -> void:
	connect("stopped", self, "_on_Stopped")
	
func _physics_process(delta: float) -> void:
	if linear_velocity.length() < 2:
		emit_signal("stopped")

func _on_Stopped():
	if $'6'.is_colliding():
		roll = 6
	elif $'5'.is_colliding():
		roll = 5
	elif $'1'.is_colliding():
		roll = 1
	elif $'3'.is_colliding():
		roll = 3
	elif $'4'.is_colliding():
		roll = 4
	elif $'2'.is_colliding():
		roll = 2


func _on_CharacterDie_input_event(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		print(faces[roll])
