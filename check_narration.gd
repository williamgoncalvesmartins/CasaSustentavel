extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://narration_test_report.json"
	game.progress_path = "res://narration_test_progress.json"
	game.student_name = "TESTE"
	game.report_rows = []
	await process_frame
	await process_frame
	var narrator = game.narrator
	narrator.say("Muito bem! Vamos aprender juntos.")
	var waited := 0.0
	while waited < 20 and not narrator.player.playing:
		await create_timer(0.1).timeout
		waited += 0.1
	assert(narrator.player.playing, narrator.last_error)
	assert(narrator.player.stream.get_length() > 1)
	await create_timer(3).timeout
	game.start_game()
	await process_frame
	assert(narrator.last_text.contains("DESAFIO 1"))
	game.get_node("Object1").pressed.emit()
	assert(narrator.last_text.contains("RESPOSTA CERTA"))
	game.question_index = 1
	game.answered = false
	game.show_question()
	game.get_node("Object1").pressed.emit()
	assert(narrator.last_text.contains("BOA TENTATIVA"))
	game.show_credits()
	await process_frame
	assert(narrator.last_text.contains("CRÉDITOS"))
	game.show_report()
	await process_frame
	assert(narrator.last_text.contains("RELATÓRIO"))
	game.start_word_search()
	await process_frame
	game.select_grid_cell(Vector2i(4,0),null)
	assert(narrator.last_text.contains("ÚLTIMA LETRA"))
	game.select_grid_cell(Vector2i(10,0),null)
	assert(narrator.last_text.contains("MEDIDAS"))
	game.toggle_pause()
	assert(narrator.last_text.contains("JOGO PAUSADO"))
	game.clear_snapshot()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: FEMALE PT-BR AUDIO PLAYBACK; SCREEN AND CONTROL NARRATION; CORRECT/INCORRECT FEEDBACK; CREDITS; REPORT; WORDS; PAUSE")
	quit()
