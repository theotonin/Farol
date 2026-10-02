extends Node

const MIX_RATE := 22050
const PLAYER_COUNT := 6

var muted := false
var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player := 0
var music_theme := ""
var _music: Array[AudioStreamPlayer] = []
var _active_music := 0
var _fade: Tween
var _ocean: AudioStreamPlayer
var _campfire: AudioStreamPlayer
var _fire_volume := -80.0
var _step_timer := 0.0


func _ready() -> void:
	_ensure_audio_pool()
	if DisplayServer.get_name() != "headless":
		for index in 2:
			var player := AudioStreamPlayer.new()
			player.name = "Music%d" % index
			player.volume_db = -80.0
			add_child(player)
			_music.append(player)
		_ocean = _ambient_player("ocean", -24.0)
		_campfire = _ambient_player("campfire", -80.0)


func _exit_tree() -> void:
	if _fade != null:
		_fade.kill()
	for player: AudioStreamPlayer in _music:
		player.stop()
		player.stream = null
	for player in [_ocean, _campfire]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
	_streams.clear()


func set_muted(value: bool) -> void:
	muted = value
	for player: AudioStreamPlayer in _music:
		player.stream_paused = muted
	if is_instance_valid(_ocean):
		_ocean.stream_paused = muted
		_campfire.stream_paused = muted
	if muted:
		for player: AudioStreamPlayer in _players:
			player.stop()
			player.stream = null
		_streams.clear()


func update_soundscape(mode: String, night: bool, fire_distance: float, fire_lit: bool) -> void:
	var theme := "day"
	if mode in ["rescue", "victory"]:
		theme = "rescue"
	elif mode in ["playing", "paused", "intro"] and night:
		theme = "night"
	if theme != music_theme:
		music_theme = theme
		if not _music.is_empty():
			_crossfade(theme)
	_fire_volume = lerpf(-18.0, -80.0, clampf(fire_distance / 320.0, 0.0, 1.0)) if fire_lit and mode == "playing" else -80.0
	if is_instance_valid(_campfire):
		_campfire.volume_db = _fire_volume


func update_steps(delta: float, moving: bool, running: bool) -> void:
	if not moving:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		play_cue("step")
		_step_timer = 0.25 if running else 0.39


func _loop_stream(kind: String) -> AudioStreamWAV:
	var stream := load("res://assets/audio/%s.wav" % kind).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	# Imported WAVs may use QOA compression; byte counts are not PCM frames.
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream


func _ambient_player(kind: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = kind.capitalize()
	player.stream = _loop_stream(kind)
	player.volume_db = volume
	add_child(player)
	player.play()
	return player


func _crossfade(theme: String) -> void:
	if _fade != null:
		_fade.kill()
	var previous := _music[_active_music]
	_active_music = 1 - _active_music
	var current := _music[_active_music]
	current.stop()
	current.stream = _loop_stream(theme)
	current.volume_db = -60.0
	current.play()
	current.stream_paused = muted
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(previous, "volume_db", -60.0, 2.5)
	_fade.tween_property(current, "volume_db", -12.0, 2.5)
	_fade.chain().tween_callback(previous.stop)


func play_cue(kind: String) -> void:
	# Headless uses a dummy audio backend that retains playback objects during
	# immediate test shutdown. There is no audible output to produce there.
	if muted or DisplayServer.get_name() == "headless":
		return
	_ensure_audio_pool()
	if not _streams.has(kind):
		var stream := _synthesize(kind)
		if stream == null:
			return
		_streams[kind] = stream
	var player := _find_player()
	player.stream = _streams[kind]
	player.volume_db = -21.0 if kind == "step" else -10.0 if kind == "swing" else -6.0
	player.pitch_scale = randf_range(0.90, 1.10) if kind == "step" else 1.0
	player.play()


func _ensure_audio_pool() -> void:
	if not _players.is_empty():
		return
	for index in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "CuePlayer%d" % index
		player.volume_db = -6.0
		add_child(player)
		_players.append(player)


func _find_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return player


func _synthesize(kind: String) -> AudioStreamWAV:
	var frequency := 440.0
	var end_frequency := 440.0
	var duration := 0.16
	var harmonic := 0.15
	var noise := 0.0
	var pulse_rate := 0.0
	match kind:
		"step":
			frequency = 95.0; end_frequency = 52.0; duration = 0.09; harmonic = 0.05; noise = 0.82
		"swing":
			frequency = 340.0; end_frequency = 95.0; duration = 0.18; harmonic = 0.10; noise = 0.75
		"collect":
			frequency = 520.0; end_frequency = 820.0; duration = 0.13; harmonic = 0.20
		"hit":
			frequency = 150.0; end_frequency = 82.0; duration = 0.10; harmonic = 0.55; noise = 0.22
		"hurt":
			frequency = 235.0; end_frequency = 115.0; duration = 0.24; harmonic = 0.35; noise = 0.12
		"eat":
			frequency = 310.0; end_frequency = 480.0; duration = 0.18; harmonic = 0.08; pulse_rate = 18.0
		"repair":
			frequency = 330.0; end_frequency = 990.0; duration = 0.48; harmonic = 0.24; pulse_rate = 7.0
		"death":
			frequency = 210.0; end_frequency = 48.0; duration = 0.82; harmonic = 0.28; noise = 0.08
		"dawn":
			frequency = 390.0; end_frequency = 780.0; duration = 0.72; harmonic = 0.18; pulse_rate = 5.0
		"ignite":
			frequency = 120.0; end_frequency = 260.0; duration = 0.34; harmonic = 0.32; noise = 0.28
		"click":
			frequency = 760.0; end_frequency = 520.0; duration = 0.045; harmonic = 0.08
		"fire":
			frequency = 92.0; end_frequency = 72.0; duration = 0.30; harmonic = 0.15; noise = 0.42; pulse_rate = 23.0
		_:
			return null
	return _make_stream(kind, frequency, end_frequency, duration, harmonic, noise, pulse_rate)


func _make_stream(kind: String, start_frequency: float, end_frequency: float, duration: float, harmonic: float, noise_amount: float, pulse_rate: float) -> AudioStreamWAV:
	var sample_count := maxi(1, int(duration * MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase := 0.0
	var noise_state := hash(kind) & 0x7fffffff
	for index in sample_count:
		var progress := float(index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / MIX_RATE
		var attack := minf(progress / 0.045, 1.0)
		var release := pow(1.0 - progress, 1.65)
		var envelope := attack * release
		var tone := sin(phase) + harmonic * sin(phase * 2.01)
		if pulse_rate > 0.0:
			tone *= 0.72 + 0.28 * sin(TAU * pulse_rate * progress * duration)
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise_sample := (float(noise_state) / 1073741823.5) - 1.0
		var sample := clampf((tone * (1.0 - noise_amount) + noise_sample * noise_amount) * envelope * 0.52, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
