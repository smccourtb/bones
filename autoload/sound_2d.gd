extends AudioStreamPlayer2D

func _on_sound2d_finished():
	queue_free()
