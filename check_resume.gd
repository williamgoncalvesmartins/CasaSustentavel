extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.progress_path = "res://resume_test.json"
	game.report_path = "res://resume_report_test.json"
	game.report_rows = []
	game.student_name = "TESTE"
	game.start_game()
	assert(game.QUESTIONS.size() == 3)
	for i in range(3):
		game.question_index = i
		game.answered = false
		game.show_question()
		game.save_current_progress()
		game.question_index = 0
		game.resume_snapshot()
		assert(game.question_index == i and not game.answered)
	game.answer_question(0)
	var points: int = game.score
	game.toggle_pause()
	game.toggle_pause()
	assert(not game.get_meta("next_button").disabled)
	game.answer_question(0)
	assert(game.score == points, "DUPLICATE SCORE")
	game.start_word_search()
	game.elapsed = 91.5
	game.found_words.append("MEDIDAS")
	for x in range(4, 11):
		game.found_cells.append(Vector2i(x, 0))
	game.save_current_progress()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.progress_path = "res://resume_test.json"
	game.report_path = "res://resume_report_test.json"
	game.report_rows = []
	game.resume_snapshot()
	assert(game.page == "PALAVRAS")
	assert(game.elapsed == 91.5 and game.found_cells.size() == 7 and game.found_words.has("MEDIDAS"))
	game.elapsed = 3598.5
	game._process(10)
	assert(game.elapsed == 3599)
	game.toggle_pause()
	game._process(10)
	assert(game.elapsed == 3599)
	game.toggle_pause()
	game.found_words.assign(game.WORDS)
	game.show_word_search()
	assert(game.is_paused)
	assert(not FileAccess.file_exists(game.progress_path))
	game.report_rows = [{"aluno":"A", "concluido":true,"fase_1_total":3,"fase_1_acertos":3,"tempo_fase_2_segundos":100},{"aluno":"B", "concluido":true,"fase_1_total":3,"fase_1_acertos":1,"tempo_fase_2_segundos":50}]
	game.report_phase = 1
	assert(game.ranking_rows()[0].aluno == "A")
	game.show_report()
	game.report_phase = 2
	assert(game.ranking_rows()[0].aluno == "B")
	game.show_report()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: 3 QUESTIONS; SAVED/RELOADED PROGRESS; MARKED WORDS/TIME; PAUSE; 59:59 CAP; COMPLETION; TWO RANKINGS")
	quit()
