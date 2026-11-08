extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.ask_student_name()
	await process_frame
	await process_frame
	var panel: PanelContainer = game.find_child("NamePanel", true, false)
	var input: LineEdit = game.find_child("StudentName", true, false)
	var begin: Button = game.find_child("Begin", true, false)
	assert(panel.size.x >= 900 and panel.size.y >= 350)
	assert(input.size.y >= 88)
	assert(begin.disabled)
	assert(panel.get_global_rect().encloses(input.get_global_rect()))
	assert(panel.get_global_rect().encloses(begin.get_global_rect()))
	game.submit_student_name(input)
	assert(game.page == "NOME", "EMPTY NAME ACCEPTED")
	input.text = "  joão silva  "
	input.text_changed.emit(input.text)
	assert(input.text == "  JOÃO SILVA  ")
	assert(not begin.disabled)
	input.text_submitted.emit(input.text)
	assert(game.page == "FASE1")
	assert(game.student_name == "JOÃO SILVA")
	game.ask_student_name()
	await process_frame
	game.show_menu()
	assert(game.page == "MENU")
	print("PASS: LARGE NAME SCREEN, FIELD BOUNDS, EMPTY VALIDATION, UPPERCASE, ENTER, BACK")
	quit()
