extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var voice = game.narrator
	assert(voice.clips.size() >= 330)
	for text in voice.clips:
		var stream = voice.clips[text]
		assert(stream is AudioStreamMP3)
		assert(stream.get_length() > 0.1, text)
		assert(stream.instantiate_playback() != null, text)
	voice.say("QUAL PRATELEIRA É MAIS CURTA?")
	assert(voice.player.playing and voice.player.stream is AudioStreamMP3)
	assert(voice.queue.is_empty())
	assert(voice.process_id == -1)
	await create_timer(4).timeout
	voice.say("TEMPO: 02:15")
	assert(voice.player.playing and voice.queue.size() > 0)
	voice.stop()
	assert(not voice.player.playing and voice.queue.is_empty())
	print("PASS: 330 NEURAL CLIPS; VALID MP3; WHOLE PHRASE; OFFLINE PLAYBACK; VARIABLE TIME; IMMEDIATE STOP")
	game.quit_game()
