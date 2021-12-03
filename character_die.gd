extends RigidBody

signal stopped()
signal selected(action)

onready var mesh = get_node("Cube")
var starting_position: Vector3
var roll: int
var actions: Dictionary



func _ready() -> void:
	connect("stopped", self, "_on_Stopped")
	
func _physics_process(delta: float) -> void:
	if linear_velocity.length() < 2:
		emit_signal("stopped")

func _on_Stopped():
	if $'6'.is_colliding():
		roll = 2
	elif $'5'.is_colliding():
		roll = 1
	elif $'1'.is_colliding():
		roll = 6
	elif $'3'.is_colliding():
		roll = 4
	elif $'4'.is_colliding():
		roll = 5
	elif $'2'.is_colliding():
		roll = 3


func _on_CharacterDie_input_event(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		emit_signal("selected", actions[roll])

func build_die(faces: Dictionary, color: Color):
	for i in range(mesh.get_surface_material_count()):
		var x = mesh.get_active_material(i).duplicate()
		x.albedo_color = color
		x.detail_enabled = true
		x.detail_albedo = faces[i+1].texture
		mesh.set_surface_material(i, x)
	actions = faces

func reset():
	linear_velocity = Vector3(1,1,1)
	angular_velocity = Vector3(0,0,3)
	translation = Vector3(0, 24, 0)
	scale = Vector3.ONE
