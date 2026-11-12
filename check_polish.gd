extends SceneTree
var game
func _initialize():
	call_deferred("check")
func capture(label: String):
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://polish_" + label + ".png")
func check():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://polish_test_report.json"
	game.progress_path = "res://polish_test_progress.json"
	game.report_rows = []
	game.student_name = "TESTE"
	game.show_credits()
	await capture("credits")
	game.show_menu()
	await capture("menu")
	game.start_game()
	for idx in range(3):
		assert(not game.get_node("AnswerFeedback").visible)
		assert(game.get_meta("next_button").visible and game.get_meta("next_button").disabled)
		await capture("challenge" + str(idx+1))
		game.get_node("Object" + str([1,0,1][idx])).pressed.emit()
		assert(game.get_node("AnswerFeedback").visible)
		assert(game.get_meta("next_button").visible)
		assert(game.feedback_label.text == "MUITO BEM! RESPOSTA CERTA.")
		await capture("answer" + str(idx+1))
		game.get_meta("next_button").pressed.emit()
	assert(game.page == "RESULTADO1")
	await capture("phase1_complete")
	assert(root.get_children().any(func(n): return n is AudioStreamPlayer and n.has_meta("celebration") and n.playing))
	game.save_current_progress()
	game.resume_snapshot()
	assert(game.page == "PALAVRAS")
	assert(game.clock_label.position == Vector2(255,25))
	game.select_grid_cell(Vector2i(1,3),null)
	game.select_grid_cell(Vector2i(1,12),null)
	assert(game.error_cells.size() == 10)
	await capture("error")
	await create_timer(0.8).timeout
	assert(game.error_cells.is_empty())
	var starts = [Vector2i(0,10),Vector2i(13,0),Vector2i(1,3),Vector2i(11,3),Vector2i(7,2),Vector2i(15,1),Vector2i(4,0)]
	var dirs = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.DOWN,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.RIGHT]
	for i in range(7):
		game.select_grid_cell(starts[i],null)
		game.select_grid_cell(starts[i]+dirs[i]*(game.strip_accents(game.WORDS[i]).length()-1),null)
	assert(game.found_words.size() == 7 and game.is_paused)
	await capture("phase2_complete")
	game.complete_game()
	assert(game.page == "FINAL")
	var sound_count = 0
	for n in root.get_children():
		if n is AudioStreamPlayer and n.has_meta("celebration") and not n.is_queued_for_deletion():
			assert(n.stream.get_length() > 3.7)
			assert(n.playing)
			sound_count += 1
	assert(sound_count == 1)
	await capture("final")
	game.clear_snapshot()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: ALL THREE FEEDBACK STATES; PHASE 1 OVERLAY; PHASE 2 RESUME; CLOCK LAYOUT; CONTINUOUS ERROR; SEVEN WORDS; BOTH CELEBRATIONS; FINAL FANFARE")
	quit()
