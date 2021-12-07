extends Node


var SOUND = preload("res://autoload/sound.tscn")
var SOUND2D = preload("res://autoload/sound_2d.tscn")


func play(sound, volume=1, bus="fx"):
	var snd = SOUND.instance()
	snd.stream = sound
	snd.volume_db = linear2db(volume)
	snd.bus = bus
	add_child(snd)

	
func play_2d(sound, volume=1, bus="fx", position=Vector2(), attenuation=1, max_distance=2000):
	var snd = SOUND2D.instance()
	snd.stream = sound
	snd.volume_db = linear2db(volume)
	snd.bus = bus
	snd.attenuation = attenuation
	snd.max_distance = max_distance
	add_child(snd)
	snd.global_position = position
	snd.play()
