extends Control


# There will be a label for each of these monitors
var monitors := [
	Performance.TIME_FPS,
	Performance.TIME_PROCESS,
	Performance.MEMORY_STATIC,
	Performance.OBJECT_COUNT,
	Performance.OBJECT_NODE_COUNT,
	Performance.OBJECT_RESOURCE_COUNT,
	Performance.OBJECT_ORPHAN_NODE_COUNT,
	Performance.RENDER_2D_DRAW_CALLS_IN_FRAME,
	Performance.AUDIO_OUTPUT_LATENCY,
]

# Labels will be placed within this Array
var labels := []
# Keeps the Y position of the last label
var last_position := 0


func _ready():
	if not OS.is_debug_build():
		queue_free()
	
	for i in monitors.size():
		var label := preload("res://debug/MonitorLabel.tscn").instance()
		label.set_name("Label")
		labels.append(label)
		label.target_monitor = monitors[i]
		add_child(label)
		label.rect_position.y = last_position
		last_position += label.get_line_height()

		
func _process(_delta):
	for i in range(labels.size()):
		labels[i].refresh()
