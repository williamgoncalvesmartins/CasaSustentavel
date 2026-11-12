extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(22050*2*30)
	wav.data = bytes
	game.narrator.player.stream = wav
	game.narrator.player.play()
	assert(game.narrator.player.playing)
	var start := Time.get_ticks_msec()
	game.quit_game()
	assert(not game.narrator.player.playing)
	assert(game.narrator.process_id == -1)
	assert(Time.get_ticks_msec()-start < 1000)
	print("PASS: QUIT STOPS AUDIO AND REQUESTS EXIT IMMEDIATELY")
