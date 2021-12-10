extends Label

var target_monitor
var refresher

func refresh():
	if refresher == null:
		match target_monitor:
			Performance.TIME_FPS:
				refresher = FPS.new()
			Performance.TIME_PROCESS:
				refresher = TimeProcess.new()
			Performance.MEMORY_STATIC:
				refresher = RAM.new()
			Performance.OBJECT_COUNT:
				refresher = ObjectCount.new()
			Performance.OBJECT_NODE_COUNT:
				refresher = NodeCount.new()
			Performance.OBJECT_RESOURCE_COUNT:
				refresher = ResourceCount.new()
			Performance.OBJECT_ORPHAN_NODE_COUNT:
				refresher = OrphanNodeCount.new()
			Performance.RENDER_2D_DRAW_CALLS_IN_FRAME:
				refresher = Render2DDrawCalls.new()
			Performance.AUDIO_OUTPUT_LATENCY:
				refresher = AudioOutputLatency.new()
	refresher.refresh(self)

class Refresh:
	func refresh(_label):
		pass

class FPS extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " FPS")

class TimeProcess extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " s")

class RAM extends Refresh:
	func refresh(label):
		label.set_text(str(stepify(Performance.get_monitor(label.target_monitor) / 1048576.0, 0.0001)) + " MiB (RAM)")

class ObjectCount extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " objects")

class NodeCount extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " nodes")

class ResourceCount extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " resources")

class OrphanNodeCount extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " orphan nodes")

class Render2DDrawCalls extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " draw calls/frame")

class AudioOutputLatency extends Refresh:
	func refresh(label):
		label.set_text(str(Performance.get_monitor(label.target_monitor)) + " audio output latency")
