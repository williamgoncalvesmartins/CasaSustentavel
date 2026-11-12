extends SceneTree
var game
var failures: Array[String] = []
const REPORT = "res://audit_report_test.json"
const SAVE = "res://audit_progress_test.json"
func _initialize(): call_deferred("check")
func expect(value: bool, message: String):
	if not value:
		failures.append(message)
		push_error(message)
func new_game():
	var node = load("res://main.tscn").instantiate()
	node.report_path = REPORT
	node.progress_path = SAVE
	root.add_child(node)
	node.set_process(false)
	return node
func check():
	game = new_game()
	await process_frame
	await process_frame
	var mode = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() else "full"
	if mode == "write":
		game.student_name = "TESTE REABERTURA"
		game.start_game()
		for answer in [1,0,1]:
			game.answer_question(answer)
			game.next_question()
		game.start_word_search()
		game.elapsed = 91.5
		game.select_grid_cell(Vector2i(4,0),null)
		game.select_grid_cell(Vector2i(10,0),null)
		game.save_current_progress()
		expect(FileAccess.file_exists(SAVE), "SAVE ON DISK")
	else:
		if mode == "read":
			game.play_or_resume()
			expect(game.page == "RETOMAR", "RESUME PROMPT AFTER NEW PROCESS")
			game.resume_snapshot()
			expect(game.page == "PALAVRAS" and game.score == 3, "RESTORE PHASE AND SCORE")
			expect(game.elapsed == 91.5 and game.found_words.has("MEDIDAS") and game.found_cells.size() == 7, "RESTORE WORDS AND TIME")
		else:
			game.student_name = "TESTE"
			game.start_game()
			game.toggle_pause()
			game.answer_question(1)
			expect(not game.answered and game.score == 0, "PAUSE MUST BLOCK ANSWERS")
			game.toggle_pause()
			for i in range(3):
				game.question_index = i
				game.answered = false
				game.show_question()
				game.save_current_progress()
				game.resume_snapshot()
				expect(game.question_index == i and not game.answered, "RESTORE UNANSWERED " + str(i))
				game.answer_question([1,0,1][i])
				var points = game.score
				game.save_current_progress()
				game.resume_snapshot()
				game.answer_question([1,0,1][i])
				expect(game.score == points and game.answered, "NO DOUBLE SCORE AFTER RESUME")
			game.next_question()
			game.save_current_progress()
			game.resume_snapshot()
			expect(game.page == "PALAVRAS", "PHASE 1 TRANSITION SAVE")
		var starts = [Vector2i(0,10),Vector2i(13,0),Vector2i(1,3),Vector2i(11,3),Vector2i(7,2),Vector2i(15,1),Vector2i(4,0)]
		var dirs = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.DOWN,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.RIGHT]
		game.toggle_pause()
		var time = game.elapsed
		game._process(10)
		expect(game.elapsed == time,"PAUSE FREEZES CLOCK")
		game.toggle_pause()
		for i in range(7):
			if game.found_words.has(game.WORDS[i]): continue
			game.select_grid_cell(starts[i],null)
			game.select_grid_cell(starts[i]+dirs[i]*(game.strip_accents(game.WORDS[i]).length()-1),null)
		expect(game.found_words.size() == 7 and game.is_paused,"COMPLETE SEVEN WORDS")
		expect(not FileAccess.file_exists(SAVE),"COMPLETION CLEARS SAVE")
		var rows = game.report_rows.size()
		game.complete_game()
		expect(game.report_rows.size() == rows,"NO DUPLICATE COMPLETION")
		var reload = new_game()
		expect(reload.report_rows.size() == rows,"REPORT PERSISTED")
		expect(reload.report_rows.back().concluido,"COMPLETION STORED")
		game.report_rows = [{"aluno":"A","concluido":true,"fase_1_total":3,"fase_1_acertos":3,"tempo_fase_2_segundos":100},{"aluno":"B","concluido":true,"fase_1_total":3,"fase_1_acertos":1,"tempo_fase_2_segundos":50}]
		game.report_phase = 1
		expect(game.ranking_rows()[0].aluno=="A","SCORE RANKING")
		game.report_phase = 2
		expect(game.ranking_rows()[0].aluno=="B","TIME RANKING")
		game.elapsed = 3598
		game.page = "PALAVRAS"
		game.is_paused = false
		game._process(10)
		expect(game.elapsed == 3599,"59:59 CAP")
		reload.queue_free()
	if failures.is_empty(): print("PASS GAME AUDIT: " + mode)
	else: print("FAIL GAME AUDIT: " + str(failures))
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
