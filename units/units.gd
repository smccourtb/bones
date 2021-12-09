extends Control
# triggered when all actions are set
signal actions_selected
signal targets_selected
signal target_picked

export var player_loadout: Resource # the key is a string of the characters number. Starts at 1
export var enemy_loadout = {} # the key is a string of the enemies number. Starts at 6


onready var turn_label: Label = $TurnOwnerLabel
onready var phase_label: Label = $PhaseLabel
onready var player_units_node: VBoxContainer = $HBoxContainer/PlayerBattlers
onready var enemy_units_node: VBoxContainer = $HBoxContainer/EnemyBattlers


var unit_refs: Array # Holds reference to all units
var players: Array # holds reference to just player nodes
var enemies: Array # holds reference to just enemy nodes
var player_count: int = 0 # not super necessary
var enemy_count: int = 0

var player_targets_selected : int = 0
var player_actions_selected: int = 0
var enemy_actions_selected: int  = 0

var current_attacker: Control

# TODO: die colors should be moved into character_unit.gd and the parameter
#		removed from the initialize functions
const die_colors = {
	"1": Color8(82, 107, 135), # blue
	"2": Color8(85, 130, 78), # green 
	"3": Color8(109, 84, 125), # purple
	"4": Color8(140, 71, 68), # red
	"5": Color8(163, 138, 45), # yellow
	"Enemy": Color8(135,94,46) # enemy
}

const ui_colors = {
	"1": "blue",
	"2": "green",
	"3": "purple",
	"4": "red",
	"5": "yellow",
	"Enemy": "enemy"
}

func _process(_delta: float) -> void:
#	i THINK i use this so i can deselect a character when choosing a target
#	units.gd blocks the screen from mouse input. i need it during roll phase
#	to be able to click on the die but other times i need to be able to click
#	on the character portraits. I know it doesnt make much sense. Im tired.
	if Global.turn_phase == "roll":
		mouse_filter = 2
	else:
		mouse_filter = 1


func _gui_input(event) -> void:
#	tied to the above _process function i believe. hence the whole contradictory
#	select and deselect a character thing. ill dive deeper at some point and
#	get a clearer picture. It works right now
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			set_current_attacker(null)


func _ready() -> void:
#	setup the CharacterUnits.tscn
	_setup_characters()
#	setup the EnemyUnits.tscn
	_setup_enemies()
#	store a list of all character (unit) nodes
#	unit_refs = players + enemies
	connect("target_picked", self, "_on_TargetsPicked")


func _set_player_count() -> void:
#	used for action and target picking
	var count = player_loadout.loadout.size()
	if count > 5:
		assert("There are too many characters in this party")
	player_count = count


func _set_enemy_count() -> void:
#	used for action picking
	var count = enemy_loadout.size()
	if count > 5:
		count = 5
	enemy_count = count


func _setup_characters() -> void:
	_set_player_count()
#	TODO: set a parameter that takes an existing party to be used when loading 
#	a previous save
	
	# Read the player loadout and add children to PlayerUnits
	var player_resource = preload("res://units/PlayerBattler.tscn")
#	add instace and add nodes to the tree, set the name
	for i in player_count:
		var player = player_resource.instance()
		player_units_node.add_child(player)
		player.name = str(i+1) # "1", "2", "3", "4', "5'
		
#	same as enemies, need to reloop due to the coupling of the key of the loadout
#	dictionary and the name of the node
	var player_units = player_units_node.get_children()
	for i in player_units:
		var data  = player_loadout.loadout[i.name]
#		just a check to make sure data was supplied should probably handle it
		if !data:
			assert("You need to supply character data to build this unit")
		i.initialize(data.duplicate(), die_colors[i.name], ui_colors[i.name])
		i.connect("action_selected", self, "_on_ActionSelected")
		i.connect("target_selected", self, "_on_TargetSelected")
#	set the players array. not sure if needed but nice to grab while im here
	players = player_units


func _setup_enemies() -> void:
	_set_enemy_count()
	var Enemy = preload("res://units/EnemyBattler.tscn")
	for i in enemy_loadout.size():
		var enemy = Enemy.instance()
		enemy.name = str(6+i) # Change to num of players + 1 instead of 6
		enemy_units_node.add_child(enemy)
		
#	need to loop over htem again to i can match the enemy_loadout key to the name
#	if the node. This is also what i was talking about
	var enemy_units = enemy_units_node.get_children()
	for j in enemy_units:
		var data = enemy_loadout[j.name]
		if !data:
			continue
		j.initialize(data.duplicate(), die_colors["Enemy"], ui_colors["Enemy"])
		j.connect("action_selected", self, "_on_ActionSelected")
#	set the enemies array. not sure if needed but nice to grab while im here
	enemies = enemy_units


func _on_ActionSelected(who:bool) -> void:
#	used to know when to trigger actions selected to trigger the next phase
#	main.gd is listening on actions_selected function
	if who:
		player_actions_selected += 1
		if player_actions_selected == player_count:
			emit_signal("actions_selected")
	else:
		enemy_actions_selected += 1
		if enemy_actions_selected == enemy_count:
			emit_signal("actions_selected")


func _on_TargetsPicked() -> void:
#	used as a signal to end player target phase
#	same thing as _on_ActionSelected() but we only care about the player for
#	targets
	player_targets_selected += 1
	if player_targets_selected == player_count:
		emit_signal("targets_selected")


func _on_TargetSelected(who) -> void:
#	used to trigger target selection
#	only used on player target phase
	if who:
#		sets target variable of character who is choosing the target to the 
#		provided paramater
		current_attacker.set_target(who)
#		returns the character display ui back with the others
		current_attacker.set_current_attacker(false)
#		this is necessary for the _on_CharacterDisplay_gui_input() in character_unit.gd
		set_current_attacker(null)
#	sets any units that were targetable to false and stops the corresponding animation
	for i in unit_refs:
		i.set_targetable(false)
#	triggers _on_TargetsPicked() that keeps track of when to call targets_selected
#	signal to change the phase to combat
	emit_signal("target_picked")


func set_current_attacker(to) -> void:
#	blocks mouse input when not in target phase
	if Global.turn_phase == "target":
#		swap attackers if any
		if current_attacker:
			current_attacker.set_current_attacker(false)
		current_attacker = to
		if !current_attacker:
			for i in unit_refs:
				i.set_targetable(false)
		if current_attacker:
			current_attacker.set_current_attacker(true)
