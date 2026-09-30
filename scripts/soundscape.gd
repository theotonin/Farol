extends Node

const MIX_RATE := 22050
const PLAYER_COUNT := 6

var muted := false
var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player := 0


func _ready() -> void:
	_ensure_audio_pool()


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
	_streams.clear()


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for player: AudioStreamPlayer in _players:
			player.stop()
			player.stream = null
		_streams.clear()


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
