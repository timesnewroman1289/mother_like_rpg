## Sound effects, autoloaded as "Sfx". Call Sfx.play("confirm").
##
## There are no audio files: every sound is a chiptune blip synthesized into
## an AudioStreamWAV at startup. To use real sounds instead, replace an entry
## with load("res://sounds/whatever.wav").
extends Node

const RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	# Menus and text
	_sounds["move"] = _make([900], 0.035, 0.15)
	_sounds["confirm"] = _make([660], 0.08, 0.2, 1800.0)
	_sounds["cancel"] = _make([520], 0.08, 0.18, -2200.0)
	_sounds["buzz"] = _make([110], 0.12, 0.22)
	_sounds["text"] = _make([1300], 0.018, 0.06)
	# Battle
	_sounds["hit"] = _make([0], 0.12, 0.35, 0.0, "noise")
	_sounds["smash"] = _make([0], 0.35, 0.5, 0.0, "noise")
	_sounds["hurt"] = _make([220], 0.18, 0.3, -500.0)
	_sounds["miss"] = _make([300], 0.15, 0.18, -1200.0, "triangle")
	_sounds["note"] = _make([523.25], 0.12, 0.25, 0.0, "triangle")
	_sounds["psi"] = _make([400], 0.4, 0.18, 2400.0)
	_sounds["defeat"] = _make([600], 0.3, 0.2, -1500.0, "triangle")
	_sounds["run"] = _make([300, 400, 500, 600], 0.05, 0.18)
	# Music pieces used by the battle beat
	_sounds["kick"] = _make([150], 0.12, 0.6, -900.0, "sine")
	_sounds["hat"] = _make([0], 0.03, 0.1, 0.0, "noise")
	_sounds["bass"] = _make([110], 0.18, 0.3, 0.0, "triangle")
	# Jingles
	_sounds["heal"] = _make([523, 659, 784, 1046], 0.07, 0.18, 0.0, "triangle")
	_sounds["level"] = _make([523, 659, 784, 659, 784, 1046], 0.08, 0.2, 0.0, "triangle")
	_sounds["win"] = _make([392, 523, 659, 784, 1046], 0.1, 0.2)
	_sounds["save"] = _make([784, 988, 1175], 0.08, 0.18, 0.0, "triangle")
	_sounds["encounter"] = _make([880, 440, 880, 440, 880, 440], 0.05, 0.18)
	_sounds["gameover"] = _make([392, 370, 349, 330], 0.25, 0.2, 0.0, "triangle")


func play(sound: String, pitch := 1.0) -> void:
	if not _sounds.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[sound]
	p.pitch_scale = pitch
	p.play()


## Builds a sound from a list of note frequencies played one after another.
## slide: Hz per second to bend the pitch. wave: square, triangle, sine, noise.
func _make(notes: Array, note_len: float, volume: float, slide := 0.0, wave := "square") -> AudioStreamWAV:
	var per_note := int(RATE * note_len)
	var total := per_note * notes.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	var phase := 0.0
	for i in total:
		var note_index := int(float(i) / per_note)
		var local := i - note_index * per_note
		var freq: float = notes[note_index] + slide * float(local) / RATE
		phase = fmod(phase + maxf(freq, 20.0) / RATE, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"triangle":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"sine":
				s = sin(phase * TAU)
			"noise":
				s = randf_range(-1.0, 1.0)
		var envelope := 1.0 - float(local) / per_note
		data.encode_s16(i * 2, int(clampf(s * volume * envelope, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
