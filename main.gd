extends Control

const BG_MENU = preload("res://menu_inicial.png")
const BG_CLEAN = preload("res://casa_sem_botoes.jpg")
const BG_WORDS = preload("res://Gemini_Generated_Image_amajuamajuamajua.jpg")
const BG_REPORT = preload("res://Gemini_Generated_Image_t0yd63t0yd63t0yd.jpg")
const BG_QUIZ = preload("res://WhatsApp Image 2026-10-14 at 14.57.31.jpeg")
const GREEN = Color("#25a85e")
const MINT = Color("#77edac")
const DARK = Color("#10242b")
const DARKER = Color("#0a171d")
const PAPER = Color("#f4fbf6")
const TEXT_DARK = Color("#16352d")
const SAVE_PATH = "user://relatorio.json"

const QUESTIONS = [
	{"kind":"CAPACIDADE","ask":"QUAL CAIXA GUARDA MAIS ÁGUA?","a":"CAIXA A  ·  500 LITROS","b":"CAIXA B  ·  1.000 LITROS","correct":1,"hint":"COMPARE A QUANTIDADE DE LITROS."},
	{"kind":"COMPRIMENTO","ask":"QUAL PRATELEIRA É MAIS COMPRIDA?","a":"CAMINHO A  ·  8 METROS","b":"CAMINHO B  ·  5 METROS","correct":1,"hint":"COMPARE O NÚMERO DE METROS."},
	{"kind":"MASSA","ask":"QUAL SACO DE COMPOSTO É MAIS LEVE?","a":"SACO A  ·  2 QUILOS","b":"SACO B  ·  5 QUILOS","correct":0,"hint":"QUILOS INDICAM A MASSA."},
]
const WORDS = ["SUSTENTABILIDADE", "EFICIÊNCIA", "CONSUMO", "DESPERDÍCIO", "ECONOMIA", "GRANDEZAS", "MEDIDAS"]
const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVXZ"

var page: String = "MENU"
var student_name: String = ""
var question_index: int = 0
var score: int = 0
var answered: bool = false
var elapsed: float = 0.0
var is_paused: bool = false
var found_words: Array[String] = []
var found_cells: Array[Vector2i] = []
var grid: Array = []
var word_start := Vector2i(-1, -1)
var report_rows: Array = []
var session_id := ""
var report_path := SAVE_PATH
var progress_path := "user://progresso.json"
var report_phase := 1
var feedback_label: Label
var clock_label: Label
var exercise_area: VBoxContainer

func _ready() -> void:
	get_window().title = "CASA SUSTENTÁVEL | GRANDEZAS E MEDIDAS"
	load_report()
	show_menu()

func _process(delta: float) -> void:
	if page == "PALAVRAS" and not is_paused:
		elapsed = minf(elapsed + delta, 3599.0)
		if is_instance_valid(clock_label):
			clock_label.text = format_time(int(elapsed))

func clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("#eaf5ed")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	page = ""

func make_label(text: String, size: int = 24, color: Color = TEXT_DARK, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func make_button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text.to_upper()
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color.WHITE if primary else PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", panel_style(GREEN if primary else DARK, MINT, 18, 3))
	button.add_theme_stylebox_override("hover", panel_style(Color("#16784a") if primary else Color("#1c3841"), MINT, 18, 3))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#11633d"), MINT, 18, 3))
	button.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, MINT, 18, 4))
	button.pressed.connect(callback)
	return button

func panel_style(fill: Color, border: Color = Color.TRANSPARENT, radius: int = 16, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func make_panel(fill: Color = Color.WHITE) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(fill, Color("#b5d8c4"), 24, 2))
	return panel

func content_column(gap: int = 14) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return box

func centered_panel() -> VBoxContainer:
	var outer := CenterContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 38
	outer.offset_right = -38
	outer.offset_top = 30
	outer.offset_bottom = -30
	add_child(outer)
	var panel := make_panel(Color("#f8fcf8"))
	panel.custom_minimum_size = Vector2(820, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	outer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var column := content_column(16)
	margin.add_child(column)
	return column

func add_heading(parent: VBoxContainer, title: String, subtitle: String = "") -> void:
	parent.add_child(make_label(title, 34, TEXT_DARK, true))
	if not subtitle.is_empty():
		parent.add_child(make_label(subtitle, 18, Color("#487061"), true))

func add_footer(parent: VBoxContainer, back_callback: Callable, show_pause: bool = false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var back := make_button("VOLTAR AO MENU", back_callback)
	row.add_child(back)
	if show_pause:
		var pause := make_button("PAUSAR", toggle_pause)
		row.add_child(pause)

func show_menu() -> void:
	clear_screen()
	page = "MENU"
	var bg := TextureRect.new()
	bg.texture = BG_MENU
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var lower := TextureRect.new()
	var clean := BG_CLEAN
	var crop := AtlasTexture.new()
	crop.atlas = clean
	crop.region = Rect2(0, clean.get_height() * 0.76, clean.get_width(), clean.get_height() * 0.24)
	lower.texture = crop
	lower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lower.anchor_top = 0.76
	lower.anchor_right = 1.0
	lower.anchor_bottom = 1.0
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 58
	layout.offset_right = -58
	layout.anchor_top = 0.81
	layout.anchor_bottom = 0.92
	layout.offset_top = 0
	layout.offset_bottom = 0
	layout.add_theme_constant_override("separation", 14)
	add_child(layout)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	layout.add_child(row)
	row.add_child(make_button("▶  INICIAR JOGO", play_or_resume, true))
	row.add_child(make_button("▤  RELATÓRIO", show_report))
	row.add_child(make_button("★  CRÉDITOS", show_credits))
	row.add_child(make_button("⏻  SAIR DO JOGO", quit_game))

func ask_student_name() -> void:
	clear_screen()
	page = "NOME"
	add_screen_background(BG_CLEAN, Color(0.02, 0.10, 0.08, 0.22))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "NamePanel"
	panel.custom_minimum_size = Vector2(900, 350)
	var frame := panel_style(Color(0.045, 0.13, 0.15, 0.96), MINT, 28, 3)
	frame.content_margin_left = 48
	frame.content_margin_right = 48
	frame.content_margin_top = 36
	frame.content_margin_bottom = 36
	frame.shadow_color = Color(0, 0.07, 0.04, 0.35)
	frame.shadow_size = 18
	frame.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	panel.add_child(column)
	var heading := make_label("DIGITE O SEU NOME", 42, PAPER, true)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(heading)
	var input := LineEdit.new()
	input.name = "StudentName"
	input.custom_minimum_size = Vector2(0, 88)
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.add_theme_font_size_override("font_size", 34)
	input.add_theme_color_override("font_color", TEXT_DARK)
	input.add_theme_color_override("caret_color", GREEN)
	input.add_theme_color_override("selection_color", Color("#b5e9c9"))
	input.add_theme_color_override("font_selected_color", TEXT_DARK)
	input.add_theme_stylebox_override("normal", panel_style(PAPER, Color("#92bbab"), 16, 2))
	input.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, MINT, 16, 3))
	input.max_length = 40
	column.add_child(input)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 22)
	column.add_child(actions)
	var begin := make_button("COMEÇAR", submit_student_name.bind(input), true)
	begin.name = "Begin"
	begin.custom_minimum_size.y = 76
	begin.add_theme_font_size_override("font_size", 28)
	begin.add_theme_stylebox_override("disabled", panel_style(Color("#27634b"), Color("#579e75"), 18, 2))
	begin.add_theme_color_override("font_disabled_color", Color("#c8dcd0"))
	begin.disabled = true
	actions.add_child(begin)
	var back := make_button("VOLTAR", show_menu)
	back.custom_minimum_size.y = 76
	back.add_theme_font_size_override("font_size", 28)
	actions.add_child(back)
	input.text_changed.connect(func(value: String):
		var caret := input.caret_column
		input.text = value.to_upper()
		input.caret_column = caret
		begin.disabled = input.text.strip_edges().is_empty()
	)
	input.text_submitted.connect(func(_value: String): submit_student_name(input))
	input.call_deferred("grab_focus")

func submit_student_name(input: LineEdit) -> void:
	var clean_name := input.text.strip_edges().to_upper()
	if clean_name.is_empty():
		input.grab_focus()
		return
	student_name = clean_name
	start_game()

func start_game() -> void:
	clear_snapshot()
	session_id = str(Time.get_unix_time_from_system()) + "-" + str(randi())
	found_words.clear()
	elapsed = 0.0
	question_index = 0
	score = 0
	answered = false
	is_paused = false
	show_question()

func show_question() -> void:
	clear_screen()
	page = "FASE1"
	var art := Control.new()
	art.set_script(preload("res://challenge_art.gd"))
	art.room = question_index
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_place(art, Rect2(0, 0, 1364, 768))
	var header := Panel.new()
	header.add_theme_stylebox_override("panel", word_style(DARK, 22, 2))
	word_place(header, Rect2(184, 24, 1000, 142))
	report_label(header, "FASE 1 · DESAFIO %d/3" % (question_index + 1), Rect2(24, 14, 952, 34), 23, MINT, true)
	report_label(header, QUESTIONS[question_index].ask, Rect2(24, 61, 952, 55), 32, PAPER, true)
	var rooms := ["ÁREA DE SERVIÇO", "COZINHA", "ESTUFA"]
	word_place(make_label(rooms[question_index], 21, TEXT_DARK, true), Rect2(200, 180, 840, 36))
	var measures := [["500 LITROS", "1.000 LITROS"], ["1 METRO", "2 METROS"], ["2 QUILOS", "5 QUILOS"]]
	for i in range(2):
		var target := Button.new()
		target.name = "Object" + str(i)
		target.tooltip_text = measures[question_index][i]
		target.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		target.add_theme_stylebox_override("hover", word_style(Color(0.3,0.9,0.6,0.12), 18, 3))
		target.add_theme_stylebox_override("focus", word_style(Color.TRANSPARENT, 18, 3))
		target.pressed.connect(answer_question.bind(i))
		word_place(target, Rect2(245+i*430, 244, 355, 316))
		var plate := Panel.new()
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel", word_style(DARK, 12, 1))
		word_place(plate, Rect2(280+i*430, 568, 280, 53))
		report_label(plate, measures[question_index][i], Rect2(8,5,264,43), 27, PAPER, true)
	feedback_label = make_label("TOQUE NO OBJETO PARA RESPONDER." if not answered else "RESPOSTA REGISTRADA. CONTINUE.", 22, TEXT_DARK, true)
	word_place(feedback_label, Rect2(180, 638, 1000, 34))
	var next := make_button("PRÓXIMO DESAFIO" if question_index < 2 else "CONCLUIR FASE 1", next_question, true)
	next.disabled = not answered
	word_place(next, Rect2(482, 688, 400, 64))
	set_meta("next_button", next)
	var gear_image := AtlasTexture.new()
	gear_image.atlas = BG_WORDS
	gear_image.region = Rect2(1290,23,61,61)
	var gear := TextureButton.new()
	gear.texture_normal = gear_image
	gear.pressed.connect(toggle_pause)
	word_place(gear, Rect2(1290,23,61,61))

func answer_question(choice: int) -> void:
	if page != "FASE1" or answered:
		return
	var right := choice == int(QUESTIONS[question_index].correct)
	if right:
		score += 1
		feedback_label.text = "MUITO BEM! VOCÊ COMPAROU AS MEDIDAS COM ATENÇÃO."
		feedback_label.add_theme_color_override("font_color", GREEN)
	else:
		feedback_label.text = "BOA TENTATIVA! OBSERVE OS NÚMEROS E SIGA EM FRENTE."
		feedback_label.add_theme_color_override("font_color", Color("#9a6635"))
	answered = true
	var next: Button = get_meta("next_button")
	next.disabled = false
	save_current_row()

func next_question() -> void:
	if not answered:
		return
	question_index += 1
	answered = false
	if question_index >= QUESTIONS.size():
		show_phase_one_result()
	else:
		show_question()

func show_phase_one_result() -> void:
	clear_screen()
	page = "RESULTADO1"
	var column := centered_panel()
	add_heading(column, "FASE 1 CONCLUÍDA!", student_name)
	column.add_child(make_label("VOCÊ ACERTOU %d DE %d EXERCÍCIOS." % [score, QUESTIONS.size()], 30, GREEN, true))
	column.add_child(make_label("AGORA VAMOS ENCONTRAR AS PALAVRAS DA CIDADE SUSTENTÁVEL.", 21, TEXT_DARK, true))
	var start := make_button("COMEÇAR FASE 2  →", start_word_search, true)
	column.add_child(start)
	column.add_child(make_button("SALVAR E VOLTAR AO MENU", save_current_progress))

func start_word_search() -> void:
	found_words.clear()
	found_cells.clear()
	elapsed = 0.0
	build_grid()
	show_word_search()

func build_grid() -> void:
	grid.clear()
	var rows := [
		"IDPAMEDIDASVEEAS", "BTOAIAGFABMLEFIG",
		"ELPIOOGECONOMIAR", "ECENSPAAORHDHCEA",
		"OOEPMPPUEEOEAIAN", "ANIBODOUCAVSGELD",
		"PSNGPRPTUDEPINSE", "CUOAEEOOOHUEGCAZ",
		"OMFLAAOEECORUISA", "DOEOENVIAOEDMAVS",
		"SUSTENTABILIDADE", "AOSOOTEEDNNCOHHO",
		"ENEGNTAOOVBIEEPC", "SHPAAHAIVIAOSAES",
		"DMORNHCGBITAUIOC", "FETIUEAGAMRFBIEN"
	]
	for source in rows:
		var row: Array[String] = []
		for letter in source:
			row.append(letter)
		grid.append(row)

func strip_accents(value: String) -> String:
	var result := value.to_upper()
	for pair in [["Á","A"],["À","A"],["Â","A"],["Ã","A"],["É","E"],["Ê","E"],["Í","I"],["Ó","O"],["Ô","O"],["Õ","O"],["Ú","U"],["Ç","C"]]:
		result = result.replace(pair[0], pair[1])
	return result

func word_style(fill: Color, radius: int = 5, border: int = 0) -> StyleBoxFlat:
	var style := panel_style(fill, Color("#80d5a0"), radius, border)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func word_place(control: Control, rect: Rect2) -> void:
	if control is Label:
		control.autowrap_mode = TextServer.AUTOWRAP_OFF
		control.clip_text = true
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	control.size = rect.size
	control.position = rect.position

func show_word_search() -> void:
	clear_screen()
	page = "PALAVRAS"
	add_screen_background(BG_WORDS, Color.TRANSPARENT)
	var board := Panel.new()
	board.add_theme_stylebox_override("panel", word_style(Color("#10232b"), 18, 3))
	word_place(board, Rect2(182, 101, 568, 569))
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.text = grid[y][x]
			button.add_theme_font_size_override("font_size", 23)
			button.add_theme_color_override("font_color", PAPER)
			var selected := found_cells.has(cell) or word_start == cell
			button.add_theme_stylebox_override("normal", word_style(Color("#327d54") if selected else Color("#22343c"), 5, 1 if selected else 0))
			button.add_theme_stylebox_override("hover", word_style(Color("#3b7759"), 5, 1))
			button.add_theme_stylebox_override("pressed", word_style(Color("#438d65"), 5, 1))
			button.add_theme_stylebox_override("focus", word_style(Color.TRANSPARENT, 5, 1))
			word_place(button, Rect2(194 + x * 34.2, 111 + y * 34.3, 30.8, 31.3))
			button.pressed.connect(select_grid_cell.bind(cell, button))
	var side := Panel.new()
	side.add_theme_stylebox_override("panel", word_style(Color("#e7efeb"), 20, 3))
	word_place(side, Rect2(808, 101, 386, 569))
	word_place(make_label("PALAVRAS ENCONTRADAS", 25, TEXT_DARK, true), Rect2(824, 120, 354, 38))
	word_place(make_label("%d/7" % found_words.size(), 29, Color("#559d70"), true), Rect2(830, 157, 340, 37))
	var rule := ColorRect.new()
	rule.color = Color("#84b49a")
	word_place(rule, Rect2(836, 196, 330, 1))
	for i in range(WORDS.size()):
		var word: String = WORDS[i]
		var row := Panel.new()
		row.add_theme_stylebox_override("panel", word_style(Color("#d5f8df"), 10))
		word_place(row, Rect2(827, 223 + i * 62, 347, 46))
		word_place(make_label("✓" if found_words.has(word) else "○", 26, Color("#50a777"), true), Rect2(834, 225 + i * 62, 36, 42))
		word_place(make_label(word, 26, TEXT_DARK), Rect2(878, 225 + i * 62, 296, 42))
	var timer := Panel.new()
	timer.add_theme_stylebox_override("panel", word_style(Color("#12292c"), 16, 2))
	word_place(timer, Rect2(96, 23, 137, 61))
	clock_label = make_label(format_time(int(elapsed)), 33, PAPER, true)
	word_place(clock_label, Rect2(100, 25, 129, 56))
	var settings := Button.new()
	settings.tooltip_text = "PAUSAR E CONFIGURAÇÕES"
	settings.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	settings.add_theme_stylebox_override("hover", word_style(Color(1, 1, 1, 0.1), 14))
	settings.pressed.connect(toggle_pause)
	word_place(settings, Rect2(1290, 23, 61, 61))
	if found_words.size() == WORDS.size():
		show_words_complete()

func old_phase_settings() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "OPÇÕES DA FASE"
	dialog.dialog_text = "O QUE VOCÊ QUER FAZER?"
	dialog.ok_button_text = "CONTINUAR"
	dialog.cancel_button_text = "VOLTAR AO MENU"
	dialog.add_button("PAUSAR", true, "pause")
	add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func():
		dialog.queue_free()
		show_menu()
	)
	dialog.custom_action.connect(func(action: String):
		dialog.queue_free()
		if action == "pause":
			toggle_pause()
	)
	dialog.popup_centered(Vector2i(430, 220))

func add_screen_background(texture: Texture2D, tint: Color) -> void:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var veil := ColorRect.new()
	veil.color = tint
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func select_grid_cell(cell: Vector2i, button: Button) -> void:
	if is_paused:
		return
	if word_start.x < 0:
		word_start = cell
		button.add_theme_stylebox_override("normal", word_style(Color("#327d54"), 5, 2))	
		return
	var end := cell
	var dx := end.x - word_start.x
	var dy := end.y - word_start.y
	var steps := maxi(absi(dx), absi(dy))
	if steps == 0 or (dx != 0 and dy != 0 and absi(dx) != absi(dy)):
		word_start = Vector2i(-1, -1)
		show_word_search()
		return
	var sx := 0 if dx == 0 else signi(dx)
	var sy := 0 if dy == 0 else signi(dy)
	var guess := ""
	for i in range(steps + 1):
		var pos := word_start + Vector2i(sx, sy) * i
		if pos.x < 0 or pos.x >= 16 or pos.y < 0 or pos.y >= 16:
			word_start = Vector2i(-1, -1)
			return
		guess += grid[pos.y][pos.x]
	var reverse := ""
	for i in range(guess.length()):
		reverse = guess.substr(i, 1) + reverse
	for word in WORDS:
		var plain := strip_accents(word)
		if not found_words.has(word) and (guess == plain or reverse == plain):
			found_words.append(word)
			for i in range(steps + 1):
				var matched_cell := word_start + Vector2i(sx, sy) * i
				if not found_cells.has(matched_cell):
					found_cells.append(matched_cell)
	word_start = Vector2i(-1, -1)
	show_word_search()

func toggle_pause() -> void:
	if is_paused:
		is_paused = false
		if page == "FASE1":
			show_question()
		else:
			show_word_search()
		return
	is_paused = true
	var cover := ColorRect.new()
	cover.name = "PauseCover"
	cover.color = Color(0.02, 0.08, 0.08, 0.76)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	var box := CenterContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_child(box)
	var panel := make_panel(PAPER)
	panel.custom_minimum_size = Vector2(620, 280)
	box.add_child(panel)
	var col := content_column(18)
	panel.add_child(col)
	col.add_child(make_label("JOGO PAUSADO", 44, TEXT_DARK, true))
	col.add_child(make_button("CONTINUAR", toggle_pause, true))
	col.add_child(make_button("SALVAR E VOLTAR AO MENU", save_current_progress, true))

func save_current_progress() -> void:
	save_snapshot()
	is_paused = false
	save_current_row()
	show_menu()

func save_current_row() -> void:
	if student_name.is_empty():
		return
	upsert_report({"aluno": student_name, "fase_1_acertos": score, "fase_1_total": QUESTIONS.size(), "fase_2_encontradas": found_words.size(), "fase_2_total": WORDS.size(), "tempo_fase_2_segundos": int(elapsed), "concluido": false, "atualizado_em": Time.get_datetime_string_from_system()})

func complete_game() -> void:
	is_paused = false
	clear_snapshot()
	var duration := int(elapsed)
	upsert_report({"aluno": student_name, "fase_1_acertos": score, "fase_1_total": QUESTIONS.size(), "fase_2_encontradas": found_words.size(), "fase_2_total": WORDS.size(), "tempo_fase_2_segundos": duration, "concluido": true, "atualizado_em": Time.get_datetime_string_from_system()})
	clear_screen()
	page = "FINAL"
	var col := centered_panel()
	add_heading(col, "PARABÉNS, %s!" % student_name, "AS DUAS FASES FORAM CONCLUÍDAS.")
	col.add_child(make_label("FASE 1: %d DE %d ACERTOS" % [score, QUESTIONS.size()], 25, GREEN, true))
	col.add_child(make_label("FASE 2: %s  ·  %d PALAVRAS" % [format_time(int(elapsed)), WORDS.size()], 25, GREEN, true))
	col.add_child(make_label("SEU RESULTADO FOI SALVO NO RELATÓRIO.", 19, TEXT_DARK, true))
	col.add_child(make_button("VER RELATÓRIO", show_report, true))
	add_footer(col, show_menu)

func upsert_report(row: Dictionary) -> void:
	if session_id.is_empty():
		session_id = str(Time.get_unix_time_from_system()) + "-" + str(randi())
	row["partida_id"] = session_id
	row["aluno"] = str(row.get("aluno", "")).strip_edges().to_upper()
	var replaced := false
	for i in range(report_rows.size()):
		if str(report_rows[i].get("partida_id", "")) == session_id:
			report_rows[i] = row
			replaced = true
			break
	if not replaced:
		report_rows.append(row)
	save_report()

func load_report() -> void:
	if not FileAccess.file_exists(report_path):
		return
	var file := FileAccess.open(report_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		report_rows = parsed

func save_report() -> void:
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report_rows, "  "))

func ranking_rows() -> Array:
	var ranking: Array = []
	for entry in report_rows:
		if entry is Dictionary and (report_phase == 2 or int(entry.get("fase_1_total", 5)) == 3) and entry.get("concluido", false) and not str(entry.get("aluno", "")).strip_edges().is_empty():
			ranking.append(entry)
	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if report_phase == 2:
			return int(a.get("tempo_fase_2_segundos", 0)) < int(b.get("tempo_fase_2_segundos", 0))
		var sa := int(a.get("fase_1_acertos", 0))
		var sb := int(b.get("fase_1_acertos", 0))
		if sa != sb:
			return sa > sb
		var ta := int(a.get("tempo_fase_2_segundos", 0))
		var tb := int(b.get("tempo_fase_2_segundos", 0))
		if ta != tb:
			return ta < tb
		return str(a.get("atualizado_em", "")) < str(b.get("atualizado_em", ""))
	)
	return ranking

func report_label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = PAPER, centered: bool = false) -> Label:
	var label := make_label(text, font_size, color, centered)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.size = rect.size
	label.position = rect.position
	return label

func show_report() -> void:
	clear_screen()
	page = "RELATORIO"
	add_screen_background(BG_CLEAN, Color(0.015, 0.08, 0.06, 0.30))
	var frame := Panel.new()
	var style := word_style(Color("#10232d"), 26, 3)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 16
	frame.add_theme_stylebox_override("panel", style)
	word_place(frame, Rect2(219, 26, 926, 590))
	report_label(frame, "RELATÓRIO", Rect2(20, 10, 886, 57), 44, PAPER, true)
	report_label(frame, "RANKING DOS ALUNOS", Rect2(20, 63, 886, 30), 22, MINT, true)
	var line := ColorRect.new()
	line.color = Color("#569c7c")
	frame.add_child(line)
	line.position = Vector2(42, 93)
	line.size = Vector2(842, 2)
	report_label(frame, "POS.", Rect2(47, 103, 65, 34), 19, MINT, true)
	report_label(frame, "ALUNO", Rect2(145, 103, 230, 34), 19, MINT)
	report_label(frame, "PONTUAÇÃO" if report_phase == 1 else "TEMPO DE CONCLUSÃO", Rect2(470, 103, 400, 34), 19, MINT)
	var scroll := ScrollContainer.new()
	scroll.name = "RankingScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	word_place(scroll, Rect2(244, 166, 878, 331))
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	var ranking := ranking_rows()
	if ranking.is_empty():
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(850, 140)
		list.add_child(empty)
		report_label(empty, "NENHUMA PARTIDA CONCLUÍDA AINDA.", Rect2(0, 32, 850, 40), 24, PAPER, true)
		report_label(empty, "TERMINE AS DUAS FASES PARA APARECER AQUI.", Rect2(0, 77, 850, 40), 19, MINT, true)
	for i in range(ranking.size()):
		var entry: Dictionary = ranking[i]
		var row := Panel.new()
		row.custom_minimum_size = Vector2(850, 44)
		row.add_theme_stylebox_override("panel", word_style(Color("#20553f") if i == 0 else Color("#1b303c"), 13, 1))
		if i == 0:
			var gold := word_style(Color("#20553f"), 13, 2)
			gold.border_color = Color("#e8d47f")
			row.add_theme_stylebox_override("panel", gold)
		list.add_child(row)
		var medal := Color("#f3d878") if i == 0 else (Color("#c4d3dd") if i == 1 else (Color("#dca778") if i == 2 else MINT))
		if i < 3:
			var badge := Panel.new()
			badge.add_theme_stylebox_override("panel", word_style(medal, 18, 2))
			row.add_child(badge)
			badge.position = Vector2(33, 5)
			badge.size = Vector2(34, 34)
		report_label(row, str(i + 1), Rect2(17, 3, 65, 38), 25, DARK if i < 3 else PAPER, true)
		var name_label := report_label(row, str(entry.get("aluno", "")), Rect2(120, 3, 231, 38), 23)
		name_label.tooltip_text = str(entry.get("aluno", "")).to_upper()
		var points := clampi(int(entry.get("fase_1_acertos", 0)), 0, 3)
		for n in range(3 if report_phase == 1 else 0):
			var star := Control.new()
			star.set_script(preload("res://score_star.gd"))
			star.earned = n < points
			row.add_child(star)
			star.position = Vector2(460 + n * 34, 5)
			star.size = Vector2(30, 34)
		if report_phase == 1:
			report_label(row, "%d/3" % points, Rect2(580, 3, 75, 38), 24)
		else:
			report_label(row, format_time(mini(int(entry.get("tempo_fase_2_segundos", 0)), 3599)), Rect2(460, 3, 270, 38), 27)
	var note := Panel.new()
	note.add_theme_stylebox_override("panel", word_style(Color("#1c3038"), 14, 1))
	word_place(note, Rect2(244, 507, 877, 90))
	report_label(note, "FASE 1: CADA ACERTO VALE UMA ESTRELA." if report_phase == 1 else "FASE 2: TEMPO QUE FOI CONCLUÍDO.", Rect2(10, 25, 857, 40), 21, PAPER, true)
	var back := make_button("◀  VOLTAR", show_menu)
	word_place(back, Rect2(554, 660, 256, 65))
	word_place(make_button("FASE 1", func(): report_phase = 1; show_report(), report_phase == 1), Rect2(274, 660, 256, 65))
	word_place(make_button("FASE 2", func(): report_phase = 2; show_report(), report_phase == 2), Rect2(834, 660, 256, 65))

func choose_csv_path() -> void:
	var picker := FileDialog.new()
	picker.title = "SALVAR RELATÓRIO"
	picker.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.current_file = "RELATORIO_ALUNOS.csv"
	picker.add_filter("*.csv", "ARQUIVO CSV")
	picker.file_selected.connect(export_report_csv)
	add_child(picker)
	picker.popup_centered(Vector2i(760, 520))

func export_report_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("ALUNO;FASE 1 ACERTOS;FASE 1 TOTAL;FASE 2 PALAVRAS;FASE 2 TOTAL;TEMPO;SITUACAO")
	for row in report_rows:
		var values := [str(row.get("aluno", "")), str(row.get("fase_1_acertos", 0)), str(row.get("fase_1_total", QUESTIONS.size())), str(row.get("fase_2_encontradas", 0)), str(row.get("fase_2_total", WORDS.size())), format_time(int(row.get("tempo_fase_2_segundos", 0))), "CONCLUÍDO" if row.get("concluido", false) else "EM ANDAMENTO"]
		var escaped := PackedStringArray()
		for value in values:
			escaped.append('"' + value.replace('"', '""') + '"')
		file.store_line(";".join(escaped))
	file.close()

func clear_report() -> void:
	var confirm := ConfirmationDialog.new()
	confirm.title = "APAGAR RELATÓRIO"
	confirm.dialog_text = "APAGAR TODOS OS RESULTADOS SALVOS?"
	confirm.ok_button_text = "APAGAR"
	confirm.cancel_button_text = "CANCELAR"
	add_child(confirm)
	confirm.confirmed.connect(func():
		report_rows.clear()
		save_report()
		confirm.queue_free()
		show_report()
	)
	confirm.canceled.connect(func(): confirm.queue_free())
	confirm.popup_centered()

func show_credits() -> void:
	clear_screen()
	page = "CREDITOS"
	var col := centered_panel()
	add_heading(col, "CRÉDITOS", "JOGO EDUCATIVO  ·  CIDADE INTELIGENTE")
	col.add_child(make_label("CRIADO POR", 19, GREEN, true))
	col.add_child(make_label("HENRIQUE GABRIEL KLUCZKOWSKI BRANDT\nHENRIQUE PONTES DE OLIVEIRA\nJOÃO PEDRO MACHADO LIMA\nWILLIAM GONÇALVES MARTINS", 24, TEXT_DARK, true))
	col.add_child(make_label("CIÊNCIA DA COMPUTAÇÃO  ·  UTFPR PONTA GROSSA\nDISCIPLINA DE ENGENHARIA DE SOFTWARE", 18, Color("#487061"), true))
	add_footer(col, show_menu)

func quit_game() -> void:
	get_tree().quit()

func format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func show_phase_settings() -> void:
	toggle_pause()

func clear_snapshot() -> void:
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_path))

func save_snapshot() -> void:
	var cells: Array = []
	for cell in found_cells:
		cells.append([cell.x, cell.y])
	var data := {"page": page, "name": student_name, "question": question_index, "score": score, "answered": answered, "elapsed": elapsed, "words": found_words, "cells": cells, "grid": grid, "start": [word_start.x, word_start.y], "session": session_id}
	var file := FileAccess.open(progress_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func play_or_resume() -> void:
	if not FileAccess.file_exists(progress_path):
		ask_student_name()
		return
	clear_screen()
	page = "RETOMAR"
	add_screen_background(BG_CLEAN, Color(0.02, 0.10, 0.08, 0.25))
	var col := centered_panel()
	add_heading(col, "PARTIDA SALVA")
	col.add_child(make_button("CONTINUAR DE ONDE PAROU", resume_snapshot, true))
	col.add_child(make_button("REINICIAR O JOGO", func(): clear_snapshot(); ask_student_name()))
	col.add_child(make_button("VOLTAR", show_menu))

func resume_snapshot() -> void:
	var file := FileAccess.open(progress_path, FileAccess.READ)
	if file == null:
		ask_student_name()
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		ask_student_name()
		return
	student_name = str(data.get("name", ""))
	question_index = clampi(int(data.get("question", 0)), 0, 3)
	score = clampi(int(data.get("score", 0)), 0, 3)
	answered = bool(data.get("answered", false))
	elapsed = clampf(float(data.get("elapsed", 0)), 0, 3599)
	session_id = str(data.get("session", ""))
	found_words.assign(data.get("words", []))
	found_cells.clear()
	for cell in data.get("cells", []):
		found_cells.append(Vector2i(int(cell[0]), int(cell[1])))
	grid = data.get("grid", [])
	var start = data.get("start", [-1, -1])
	word_start = Vector2i(int(start[0]), int(start[1]))
	is_paused = false
	if data.get("page", "") == "PALAVRAS":
		show_word_search()
	elif question_index >= 3:
		start_word_search()
	else:
		show_question()

func show_words_complete() -> void:
	is_paused = true
	clear_snapshot()
	upsert_report({"aluno": student_name, "fase_1_acertos": score, "fase_1_total": 3, "fase_2_encontradas": 7, "fase_2_total": 7, "tempo_fase_2_segundos": int(elapsed), "concluido": true, "atualizado_em": Time.get_datetime_string_from_system()})
	var cover := ColorRect.new()
	cover.color = Color(0.02, 0.08, 0.08, 0.76)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cover)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", word_style(DARK, 26, 3))
	cover.add_child(panel)
	panel.position = Vector2(302, 194)
	panel.size = Vector2(760, 380)
	report_label(panel, "FASE 2 CONCLUÍDA", Rect2(30, 30, 700, 55), 36, PAPER, true)
	report_label(panel, "VOCÊ ENCONTROU TODAS AS PALAVRAS!", Rect2(30, 115, 700, 42), 26, PAPER, true)
	report_label(panel, "TEMPO: " + format_time(int(elapsed)), Rect2(30, 178, 700, 54), 34, MINT, true)
	var button := make_button("CONTINUAR", complete_game, true)
	panel.add_child(button)
	button.position = Vector2(160, 276)
	button.size = Vector2(440, 70)
