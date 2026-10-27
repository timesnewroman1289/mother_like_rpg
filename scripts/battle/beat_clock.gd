## Plays the battle "music" (a kick/hat/bass loop) and tracks exactly where
## the beat is, so the rhythm combo can judge how well a press was timed.
extends Node

signal beat(index: int)

const BASS_LINE := [1.0, 1.0, 1.498, 1.0, 1.335, 1.335, 1.498, 1.782]

var bpm := 110.0
var playing := true
var time := 0.0

var _last_beat := -1


func period() -> float:
	return 60.0 / bpm


func _process(delta: float) -> void:
	if not playing:
		return
	time += delta
	var b := floori(time / period())
	if b != _last_beat:
		_last_beat = b
		Sfx.play("kick" if b % 2 == 0 else "hat")
		Sfx.play("bass", BASS_LINE[b % BASS_LINE.size()])
		beat.emit(b)


func nearest_beat() -> int:
	return roundi(time / period())


## Seconds since the given beat (negative = the beat is still coming).
func offset_to(beat_index: int) -> float:
	return time - beat_index * period()
