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
	{"kind":"COMPRIMENTO","ask":"QUAL CAMINHO É MAIS COMPRIDO?","a":"CAMINHO A  ·  8 METROS","b":"CAMINHO B  ·  5 METROS","correct":0,"hint":"COMPARE O NÚMERO DE METROS."},
	{"kind":"MASSA","ask":"QUAL SACO DE COMPOSTO É MAIS LEVE?","a":"SACO A  ·  2 QUILOS","b":"SACO B  ·  5 QUILOS","correct":0,"hint":"QUILOS INDICAM A MASSA."},
	{"kind":"TEMPO","ask":"QUAL LÂMPADA FICA ACESA POR MAIS TEMPO?","a":"LÂMPADA A  ·  4 HORAS","b":"LÂMPADA B  ·  7 HORAS","correct":1,"hint":"COMPARE A QUANTIDADE DE HORAS."},
	{"kind":"TEMPERATURA","ask":"QUAL DIA ESTÁ MAIS QUENTE?","a":"DIA A  ·  18 GRAUS","b":"DIA B  ·  25 GRAUS","correct":1,"hint":"COMPARE OS GRAUS DO TERMÔMETRO."}
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
var feedback_label: Label
var clock_label: Label
var exercise_area: VBoxContainer

func _ready() -> void:
	get_window().title = "CASA SUSTENTÁVEL | GRANDEZAS E MEDIDAS"
	load_report()
	show_menu()

func _process(delta: float) -> void:
	if page == "PALAVRAS" and not is_paused:
		elapsed += delta
		if is_instance_valid(clock_label):
			clock_label.text = format_time(int(elapsed))

func clear_screen() -> void:
	for child in get_children():
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
	row.add_child(make_button("▶  INICIAR JOGO", ask_student_name, true))
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
	question_index = 0
	score = 0
	answered = false
	is_paused = false
	show_question()

func show_question() -> void:
	clear_screen()
	page = "FASE1"
	var background := TextureRect.new()
	background.texture = BG_QUIZ
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var question: Dictionary = QUESTIONS[question_index]
	var prompt := make_panel(Color(0.025, 0.10, 0.20, 0.96))
	prompt.anchor_left = 0.15
	prompt.anchor_top = 0.14
	prompt.anchor_right = 0.72
	prompt.anchor_bottom = 0.33
	add_child(prompt)
	var prompt_col := content_column(3)
	prompt.add_child(prompt_col)
	prompt_col.add_child(make_label("EXERCÍCIO %d DE %d  ·  %s" % [question_index + 1, QUESTIONS.size(), question.kind], 19, MINT, true))
	prompt_col.add_child(make_label(question.ask, 29, PAPER, true))
	var answer_back := ColorRect.new()
	answer_back.color = Color(0.025, 0.08, 0.12, 0.94)
	answer_back.anchor_left = 0
	answer_back.anchor_top = 0.66
	answer_back.anchor_right = 1
	answer_back.anchor_bottom = 1
	answer_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(answer_back)
	var options := HBoxContainer.new()
	options.anchor_left = 0.115
	options.anchor_top = 0.69
	options.anchor_right = 0.89
	options.anchor_bottom = 0.83
	options.offset_left = 0
	options.offset_top = 0
	options.offset_right = 0
	options.offset_bottom = 0
	options.add_theme_constant_override("separation", 18)
	add_child(options)
	var a := make_button("A  ·  " + question.a, func(): answer_question(0), true)
	var b := make_button("B  ·  " + question.b, func(): answer_question(1), true)
	a.custom_minimum_size.y = 86
	b.custom_minimum_size.y = 86
	options.add_child(a)
	options.add_child(b)
	feedback_label = make_label("TOQUE NA RESPOSTA CERTA.", 18, PAPER, true)
	feedback_label.anchor_left = 0.12
	feedback_label.anchor_top = 0.835
	feedback_label.anchor_right = 0.56
	feedback_label.anchor_bottom = 0.89
	add_child(feedback_label)
	var progress := ProgressBar.new()
	progress.max_value = QUESTIONS.size()
	progress.value = question_index
	progress.anchor_left = 0.12
	progress.anchor_top = 0.92
	progress.anchor_right = 0.55
	progress.anchor_bottom = 0.945
	add_child(progress)
	var next := make_button("PRÓXIMO  →", next_question, true)
	next.disabled = true
	next.anchor_left = 0.63
	next.anchor_top = 0.86
	next.anchor_right = 0.89
	next.anchor_bottom = 0.95
	next.offset_left = 0
	next.offset_top = 0
	next.offset_right = 0
	next.offset_bottom = 0
	add_child(next)
	var settings := make_button("⚙", show_phase_settings)
	settings.anchor_left = 0.94
	settings.anchor_top = 0.02
	settings.anchor_right = 0.99
	settings.anchor_bottom = 0.12
	settings.offset_left = 0
	settings.offset_top = 0
	settings.offset_right = 0
	settings.offset_bottom = 0
	add_child(settings)
	set_meta("next_button", next)

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
	add_footer(column, show_menu)

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
		var finish := make_button("CONCLUIR JOGO", complete_game, true)
		word_place(finish, Rect2(808, 686, 386, 64))

func show_phase_settings() -> void:
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
	panel.custom_minimum_size = Vector2(490, 260)
	box.add_child(panel)
	var col := content_column(18)
	panel.add_child(col)
	col.add_child(make_label("JOGO PAUSADO", 30, TEXT_DARK, true))
	col.add_child(make_label("VOCÊ PODE CONTINUAR QUANDO ESTIVER PRONTO.", 18, TEXT_DARK, true))
	col.add_child(make_button("CONTINUAR", toggle_pause, true))
	col.add_child(make_button("SALVAR E VOLTAR AO MENU", save_current_progress, true))

func save_current_progress() -> void:
	is_paused = false
	save_current_row()
	show_menu()

func save_current_row() -> void:
	if student_name.is_empty():
		return
	upsert_report({"aluno": student_name, "fase_1_acertos": score, "fase_1_total": QUESTIONS.size(), "fase_2_encontradas": found_words.size(), "fase_2_total": WORDS.size(), "tempo_fase_2_segundos": int(elapsed), "concluido": false, "atualizado_em": Time.get_datetime_string_from_system()})

func complete_game() -> void:
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
	var replaced := false
	for i in range(report_rows.size()):
		if str(report_rows[i].get("aluno", "")) == student_name:
			report_rows[i] = row
			replaced = true
			break
	if not replaced:
		report_rows.append(row)
	save_report()

func load_report() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		report_rows = parsed

func save_report() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report_rows, "  "))

func show_report() -> void:
	clear_screen()
	page = "RELATORIO"
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 45
	root.offset_right = -45
	root.offset_top = 26
	root.offset_bottom = -26
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	add_heading(root, "RELATÓRIO DOS ALUNOS", "RESULTADOS SALVOS NESTE COMPUTADOR")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	if report_rows.is_empty():
		list.add_child(make_label("AINDA NÃO HÁ RESULTADOS. INICIE O JOGO PARA CRIAR UM RELATÓRIO.", 21, TEXT_DARK, true))
	else:
		var header := make_panel(DARK)
		list.add_child(header)
		var cols := HBoxContainer.new()
		cols.add_child(make_label("ALUNO  ·  FASE 1  ·  FASE 2  ·  TEMPO  ·  SITUAÇÃO", 17, PAPER))
		header.add_child(cols)
		for row in report_rows:
			var card := make_panel(Color("#e6f2e9"))
			list.add_child(card)
			card.add_child(make_label("%s     %d/%d ACERTOS     %d/%d PALAVRAS     %s     %s" % [str(row.get("aluno", "ALUNO")), int(row.get("fase_1_acertos", 0)), int(row.get("fase_1_total", QUESTIONS.size())), int(row.get("fase_2_encontradas", 0)), int(row.get("fase_2_total", WORDS.size())), format_time(int(row.get("tempo_fase_2_segundos", 0))), "CONCLUÍDO" if row.get("concluido", false) else "EM ANDAMENTO"], 18, TEXT_DARK))
	root.add_child(make_label("OS DADOS FICAM SALVOS LOCALMENTE NO DISPOSITIVO.", 15, Color("#487061"), true))
	var row_buttons := HBoxContainer.new()
	row_buttons.add_child(make_button("VOLTAR", show_menu))
	row_buttons.add_child(make_button("EXPORTAR CSV", choose_csv_path, true))
	row_buttons.add_child(make_button("APAGAR RELATÓRIO", clear_report))
	root.add_child(row_buttons)

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
