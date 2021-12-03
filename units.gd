extends Control

signal actions_selected
signal targets_selected
signal target_picked

export var player_loadout: Resource # the key is a string of the characters number. Starts at 1
export var enemy_loadout = {} # the key is a string of the enemies number. Starts at 6


onready var turn_label = get_node("TurnOwnerLabel")
onready var phase_label = get_node("PhaseLabel")


var unit_refs: Array # Holds reference to all units
var players: Array
var enemies: Array
var player_count: int = 0
var enemy_count: int = 0

var player_actions_selected: int = 0
var enemy_actions_selected: int  = 0

var current_attacker

const die_colors = {
	"1": Color8(160, 178, 200), # blue
	"2": Color8(156, 195, 150), # green 
	"3": Color8(177, 155, 190), # purple
	"4": Color8(204, 144, 141), # red
	"5": Color8(224, 203, 121), # yellow
	"Enemy": Color8(207,155,93) # enemy
}

const ui_colors = {
	"1": "blue",
	"2": "green", # green 
	"3": "purple",
	"4": "red",
	"5": "yellow",
	"Enemy": "enemy"
}


func _ready() -> void:
	_setup_characters()
	_setup_enemies()
	unit_refs = players + enemies

func _set_player_count():
	var count = player_loadout.loadout.size()
	if count > 5:
		assert("There are too many characters in this party")
	player_count = count

func _set_enemy_count():
	var count = enemy_loadout.size()
	if count > 5:
		count = 5
	enemy_count = count

func _setup_characters() -> void:
	_set_player_count()
	# TODO: set a parameter that takes an existing party
	
	# Read the player loadout and add children to PlayerUnits
	var player_resource = load("res://CharacterUnit.tscn")
	var player_units_node = get_node("PlayerUnits")
	for i in player_count:
		var player = player_resource.instance()
		player_units_node.add_child(player)
		player.name = str(i+1)
		
	
	# loop through added children and set them up
	var player_units = player_units_node.get_children()
	for i in player_units:
		var data  = player_loadout.loadout[i.name]
		if !data:
			assert("You need to supply character data to build this unit")
		i.initialize(data.duplicate(), die_colors[i.name], ui_colors[i.name])
		i.connect("action_selected", self, "_on_ActionSelected")
		i.connect("target_selected", self, "_on_TargetSelected")
	players = player_units


func _setup_enemies():
	_set_enemy_count()
	var enemy = load("res://EnemyUnit.tscn").instance()
	for i in enemy_loadout.size():
		enemy.name = str(6+i) # Change to num of players + 1 instead of 6
		$EnemyUnits.add_child(enemy)
	var enemy_units = get_node("EnemyUnits").get_children()
	for j in enemy_units:
		var data = enemy_loadout[j.name]
		if !data:
			continue
		j.initialize(data.duplicate(), die_colors["Enemy"], ui_colors["Enemy"])
		j.connect("action_selected", self, "_on_ActionSelected")
		j.connect("target_selected", self, "_on_TargetSelected")
	enemies = enemy_units

func _on_ActionSelected(who:bool):
	print("YEP ITS IN HERE")
	if who:
		player_actions_selected += 1
		if player_actions_selected == player_count:
			emit_signal("actions_selected")
	else:
		enemy_actions_selected += 1
		if enemy_actions_selected == enemy_count:
			emit_signal("actions_selected")

# used to trigger target selection
func _on_TargetSelected(who):
	print("HELLOOOOOOOO")
	if who:
		print("WHO: ", who)
		if current_attacker.line:
			current_attacker.line.queue_free()
			current_attacker.target = who
	emit_signal("target_picked")
