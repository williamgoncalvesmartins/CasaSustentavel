extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://feedback_test_report.json"
	game.progress_path = "res://feedback_test_progress.json"
	game.report_rows = []
	game.student_name = "TESTE"
	game.start_game()
	await process_frame
	assert(game.get_node("Object0").get_theme_stylebox("pressed") is StyleBoxEmpty)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview_feedback_phase1.png")
	game.start_word_search()
	game.select_grid_cell(Vector2i(0,0), null)
	assert(game.word_start == Vector2i(0,0))
	game.select_grid_cell(Vector2i(1,0), null)
	assert(game.selection_locked and game.error_cells.size() == 2)
	await create_timer(0.8).timeout
	assert(not game.selection_locked and game.error_cells.is_empty())
	game.select_grid_cell(Vector2i(4,0), null)
	game.select_grid_cell(Vector2i(10,0), null)
	assert(game.found_words.has("MEDIDAS"))
	assert(game.completed_segments().size() == 1)
	game.select_grid_cell(Vector2i(5,5), null)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview_feedback_phase2.png")
	await create_timer(0.5).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	print("PASS: EMPTY OBJECT BORDERS; BLUE SELECTION; RED ERROR AND RESET; CORRECT WORD; CONNECTED HIGHLIGHT")
	quit()
