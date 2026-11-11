extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://challenge_test_report.json"
	game.progress_path = "res://challenge_test_progress.json"
	game.report_rows = []
	game.student_name = "TESTE"
	game.start_game()
	await process_frame
	for answer in [1, 1, 0]:
		game.get_node("Object" + str(answer)).pressed.emit()
		assert(not game.get_meta("next_button").disabled)
		game.get_meta("next_button").pressed.emit()
		await process_frame
	assert(game.score == 3 and game.page == "RESULTADO1")
	game.save_current_progress()
	game.resume_snapshot()
	assert(game.page == "PALAVRAS", "PHASE TRANSITION RESTORE")
	game.elapsed = 127
	game.found_words.assign(game.WORDS)
	game.show_word_search()
	await process_frame
	var labels: Array = game.find_children("*", "Label", true, false)
	var has_time := false
	for label in labels:
		if label.text == "TEMPO: 02:07":
			has_time = true
			assert(label.size.y == 54)
	assert(has_time)
	for phase in [1, 2]:
		game.report_phase = phase
		game.show_report()
		await process_frame
		var nav := 0
		for child in game.get_children():
			if child is Button and child.text in ["FASE 1", "FASE 2", "◀  VOLTAR"]:
				assert(child.position.y == 660 and child.size.y == 65)
				nav += 1
		assert(nav == 3)
	game.clear_snapshot()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: OBJECT INPUTS; 3/3 SCORE; PHASE 2 RESUME; COMPLETION TIME; ALIGNED REPORT NAVIGATION")
	quit()
