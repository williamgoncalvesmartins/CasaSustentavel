extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_word_search()
	await process_frame
	await process_frame
	var cells := 0
	for child in game.get_children():
		if child is Button and child.text.length() == 1:
			cells += 1
			assert(child.size.x < 35 and child.size.y < 35, "CELL OVERFLOW")
	var starts := [Vector2i(0,10), Vector2i(13,0), Vector2i(1,3), Vector2i(11,3), Vector2i(7,2), Vector2i(15,1), Vector2i(4,0)]
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT]
	for i in range(game.WORDS.size()):
		var word: String = game.strip_accents(game.WORDS[i])
		var actual := ""
		for x in range(word.length()):
			var position: Vector2i = starts[i] + directions[i] * x
			actual += game.grid[position.y][position.x]
		assert(actual == word, "MISSING WORD")
	assert(cells == 256, "MISSING CELLS")
	assert(game.clock_label.position == Vector2(100,25), "TIMER POSITION")
	assert(game.clock_label.size.y <= 56, "TIMER OVERFLOW")
	var count := 0
	for child in game.get_children():
		if child is Label and game.WORDS.has(child.text):
			assert(child.size.y <= 42, "WORD LABEL OVERFLOW")
			assert(child.position.x == 878, "WORD LABEL POSITION")
			count += 1
	assert(count == 7, "WORD LABELS MISSING")
	var dummy := Button.new()
	root.add_child(dummy)
	for i in range(game.WORDS.size()):
		game.select_grid_cell(starts[i], dummy)
		game.select_grid_cell(starts[i] + directions[i] * (game.strip_accents(game.WORDS[i]).length() - 1), dummy)
		await process_frame
	assert(game.found_words.size() == 7, "COMPLETION FAILED")
	print("PASS: REFERENCE POSITIONS; TIMER AND 7 LABELS FIT; ALL 7 WORDS SELECTED")
	quit()
