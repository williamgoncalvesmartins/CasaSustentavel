extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.report_path = "res://report_test_data.json"
	game.report_rows = []
	var samples := [["ana", 4, 100, true], ["joão", 5, 180, true], ["ana", 5, 120, true], ["bia", 5, 1, false]]
	for i in range(samples.size()):
		game.session_id = "TEST-" + str(i)
		var s: Array = samples[i]
		game.upsert_report({"aluno": s[0], "fase_1_acertos": s[1], "tempo_fase_2_segundos": s[2], "concluido": s[3]})
	game.report_rows = []
	game.load_report()
	assert(game.report_rows.size() == 4, "HISTORY LOST")
	var ranking: Array = game.ranking_rows()
	assert(ranking.size() == 3, "INCOMPLETE INCLUDED")
	assert(ranking[0].aluno == "ANA" and ranking[0].tempo_fase_2_segundos == 120)
	assert(ranking[1].aluno == "JOÃO")
	assert(ranking[2].fase_1_acertos == 4)
	game.show_report()
	await process_frame
	await process_frame
	var scroll: ScrollContainer = game.get_node("RankingScroll")
	var list := scroll.get_child(0)
	assert(list.size.x >= 850, "COLLAPSED TABLE")
	assert(list.get_child_count() == 3)
	for row in list.get_children():
		assert(row.size.y == 44)
		for cell in row.get_children():
			if cell is Label:
				assert(cell.size.y <= 38, "WRAPPED TEXT")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.report_path))
	print("PASS: SAVED HISTORY, UPPERCASE NAMES, SCORE/TIME RANKING, COMPLETED ONLY, TABLE GEOMETRY")
	quit()
