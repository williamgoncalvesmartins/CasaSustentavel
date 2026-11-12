extends SceneTree
var game
func _initialize(): call_deferred("check")
func snap(label):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://layout_" + label + ".png")
func check():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://layout_test_report.json"
	game.progress_path = "res://layout_test_progress.json"
	game.report_rows = []
	game.student_name = "ANA"
	game.start_game()
	game.score = 3
	game.show_phase_one_result()
	await snap("phase1")
	var panel = game.find_child("PhaseOneComplete",true,false)
	assert(panel.size == Vector2(760,380))
	for label in panel.find_children("*","Label",true,false):
		assert(label.text != "ANA")
		assert(not label.text.contains("AGORA VAMOS"))
	game.save_current_progress()
	game.resume_snapshot()
	assert(game.page == "PALAVRAS")
	game.elapsed = 135
	await snap("clock")
	game.found_words.assign(game.WORDS)
	game.complete_game()
	await snap("final")
	assert(game.page == "FINAL")
	for i in range(9):
		game.report_rows.append({"aluno":"ALUNO TESTE " + str(i+1),"concluido":true,"fase_1_total":3,"fase_1_acertos":3-i%4,"tempo_fase_2_segundos":80+i*13})
	for phase in [1,2]:
		game.report_phase = phase
		game.show_report()
		await snap("report" + str(phase))
		var labels = game.find_children("*","Label",true,false)
		for label in labels:
			if label.text == "POSIÇÃO":
				assert(is_equal_approx(label.global_position.x+label.size.x/2,309.0))
			if label.text in ["PONTUAÇÃO","TEMPO DE CONCLUSÃO"]:
				assert(is_equal_approx(label.global_position.x+label.size.x/2,949.0))
	game.clear_snapshot()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: COMPACT COMPLETION; SAVE AND RESUME; CLOCK; FINAL SCREEN; REPORT COLUMN CENTERS")
	quit()
