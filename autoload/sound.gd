extends AudioStreamPlayer

func _on_sound_finished():
	queue_free()
