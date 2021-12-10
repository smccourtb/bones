extends Node


enum TurnPhase {
	ROLL,
	ACTION,
	COMBAT,
	TARGET,
}

const TURN_PHASE = [
	"ROLL",
	"ACTION",
	"COMBAT",
	"TARGET",
]

var turn_phase: int


func get_turn_phase_name() -> String:
	return TURN_PHASE[turn_phase]
