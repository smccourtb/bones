extends RigidBody


signal stopped() # internal signal
signal die_selected(action)
signal roll_set(action) # enemy_unit.gd listens for this signal

onready var mesh = $Cube
onready var disappear_tween = $Disappear
onready var grow_tween = $Grow


# raycast nodes
onready var one = $"1"
onready var two = $"2"
onready var three = $"3"
onready var four = $"4"
onready var five = $"5"
onready var six = $"6"


var roll: int  # the side the die landed on
var actions: Dictionary # die actions: 6 in total. keys correspond to face number
var stopped: bool = false
 
func _ready() -> void:
	set_physics_process(true)
	connect("stopped", self, "_on_Stopped")


func _physics_process(_delta: float) -> void:
	if linear_velocity.is_equal_approx(Vector3.ZERO):
		emit_signal("stopped")
	else:
		if is_connected("input_event", self, "_on_CharacterDie_input_event"):
			disconnect("input_event", self, "_on_CharacterDie_input_event")
			disconnect("mouse_entered", self, "_on_CharacterDie_mouse_entered")
			disconnect("mouse_exited", self, "_on_CharacterDie_mouse_exited")
	if six.is_colliding():
		roll = 2
	elif five.is_colliding():
		roll = 1
	elif one.is_colliding():
		roll = 6
	elif three.is_colliding():
		roll = 4
	elif four.is_colliding():
		roll = 5
	elif two.is_colliding():
		roll = 3

func _on_Stopped():
	set_physics_process(false)
	if not is_connected("input_event", self, "_on_CharacterDie_input_event"):
		connect("input_event", self, "_on_CharacterDie_input_event")
		connect("mouse_entered", self, "_on_CharacterDie_mouse_entered")
		connect("mouse_exited", self, "_on_CharacterDie_mouse_exited")
	stopped = true
	emit_signal("roll_set", actions[roll])


func _on_CharacterDie_input_event(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		emit_signal("die_selected", actions[roll])


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
	stopped = false
	roll = 0


func _on_CharacterDie_mouse_entered() -> void:
	grow_tween.interpolate_property(self, "scale", null, Vector3(1.3, 1.3, 1.3), .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	grow_tween.start()


func _on_CharacterDie_mouse_exited() -> void:
	grow_tween.interpolate_property(self, "scale", null, Vector3(1, 1, 1), .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	grow_tween.start()

func disappear():
	#	die dissapear after being clicked
	disappear_tween.interpolate_property(self, "scale",
		null, Vector3(0,0,0), .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	disappear_tween.start()


func _on_Disappear_tween_completed(_object: Object, _key: NodePath) -> void:
	queue_free()
