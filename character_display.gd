extends Node

# TODO: 
# set 
var health: int
var die_faces := {}
var face_choice: String

func initialize(data: Character) -> void:
	self.set_name(data.name)
	# build_die

func set_health(new_health: int) -> void:
	self.health = new_health

func get_health() -> int:
	return self.health

func set_die_face(side: int, action: String) -> void:
	if side > 0 and side < 7:
		die_faces[side] = action

func take_damage(damage: int) -> void:
	var new_health: int = health - damage
	if new_health > 0:
		set_health(new_health)
	else:
		die()

func die() -> void:
	set_health(0)

func set_face_choice(choice: int):
	if die_faces.has(choice):
		self.face_choice = die_faces[choice]
	
