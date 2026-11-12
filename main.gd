extends Control

const BG_CLEAN = preload("res://casa_sem_botoes.jpg")
const BG_WORDS = preload("res://fase2_fundo_sem_relogio.png")
const GREEN = Color("#25a85e")
const MINT = Color("#77edac")
const DARK = Color("#10242b")
const DARKER = Color("#0a171d")
const PAPER = Color("#f4fbf6")
const TEXT_DARK = Color("#16352d")
const SAVE_PATH = "user://relatorio.json"

const QUESTIONS = [
	{"kind":"CAPACIDADE","ask":"QUAL CAIXA GUARDA MAIS ÁGUA?","a":"CAIXA A  ·  500 LITROS","b":"CAIXA B  ·  1.000 LITROS","correct":1,"hint":"COMPARE A QUANTIDADE DE LITROS."},
	{"kind":"COMPRIMENTO","ask":"QUAL PRATELEIRA É MAIS CURTA?","a":"PRATELEIRA A · 1,20 METRO","b":"PRATELEIRA B · 1,50 METRO","correct":0,"hint":"COMPARE O NÚMERO DE METROS."},
	{"kind":"MASSA","ask":"QUAL SACO É MAIS PESADO?","a":"SACO A  ·  2 QUILOS","b":"SACO B  ·  5 QUILOS","correct":1,"hint":"QUILOS INDICAM A MASSA."},
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
var error_cells: Array[Vector2i] = []
var selection_locked := false
var narrator: Node
var last_narrated_screen := ""

func _ready() -> void:
	narrator = preload("res://narration.gd").new()
	narrator.game = self
	get_tree().root.add_child.call_deferred(narrator)
	get_window().title = "CASA SUSTENTÁVEL | GRANDEZAS E MEDIDAS"
	load_report()
	show_menu()

func _process(delta: float) -> void:
	if page == "PALAVRAS" and not is_paused:
		elapsed = minf(elapsed + delta, 3599.0)
		if is_instance_valid(clock_label):
			clock_label.text = format_time(int(elapsed))

func clear_screen() -> void:
	call_deferred("_narrate_screen")
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
	button.set_meta("narration_bound",true)
	button.focus_entered.connect(func(): narrator.say(button.text))
	button.button_down.connect(func(): narrator.say(button.text))
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
	add_screen_background(BG_CLEAN, Color.TRANSPARENT)
	var title := make_label("CASA SUSTENTÁVEL", 64, Color("#d6ffe4"), true)
	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["Arial"])
	title_font.font_weight = 800
	title.add_theme_font_override("font", title_font)
	title.add_theme_color_override("font_outline_color", Color("#095b34"))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", Color(0,0.15,0.08,0.45))
	title.add_theme_constant_override("shadow_offset_y", 5)
	word_place(title, Rect2(180, 10, 1004, 100))
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
	var backgrounds := ["res://desafio_caixas.jpg", "res://desafio_prateleiras.jpg", "res://desafio_composto.jpg"]
	add_screen_background(load(backgrounds[question_index]), Color.TRANSPARENT)
	var header := Panel.new()
	header.add_theme_stylebox_override("panel", word_style(DARK, 20, 0))
	word_place(header, Rect2(260, 24, 920, 106))
	report_label(header, "DESAFIO %d/3" % (question_index + 1), Rect2(24, 10, 872, 28), 23, MINT, true)
	report_label(header, QUESTIONS[question_index].ask, Rect2(24, 44, 872, 48), 32, PAPER, true)
	var phase_badge := Panel.new()
	phase_badge.add_theme_stylebox_override("panel", word_style(DARK, 16, 1))
	word_place(phase_badge, Rect2(26, 26, 140, 60))
	report_label(phase_badge, "FASE 1", Rect2(5,5,130,50), 25, PAPER, true)
	var measures := [["500 LITROS", "1.000 LITROS"], ["1,20 M", "1,50 M"], ["2 QUILOS", "5 QUILOS"]]
	for i in range(2):
		var target := Button.new()
		target.name = "Object" + str(i)
		target.set_meta("speech", ("OBJETO À ESQUERDA. " if i == 0 else "OBJETO À DIREITA. ") + measures[question_index][i])
		target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		target.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		for state in ["hover", "focus", "pressed", "disabled"]:
			target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		target.pressed.connect(answer_question.bind(i))
		var object_rect := Rect2(245+i*430, 244, 355, 316)
		if question_index == 0:
			object_rect = Rect2(343, 277, 270, 180) if i == 0 else Rect2(680, 241, 360, 216)
		elif question_index == 1:
			object_rect = Rect2(220, 270, 305, 218) if i == 0 else Rect2(690, 270, 390, 218)
		else:
			object_rect = Rect2(434, 346, 167, 195) if i == 0 else Rect2(686, 265, 239, 277)
		word_place(target, object_rect)
		if question_index == 2:
			continue
		var plate := Panel.new()
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var plate_rect := Rect2(260 if i == 0 else 740, 490, 230, 46)
		if question_index == 0:
			plate_rect = Rect2(374, 354, 204, 56) if i == 0 else Rect2(738, 346, 240, 64)
		word_place(plate, plate_rect)
		report_label(plate, measures[question_index][i], Rect2(4, 4, plate_rect.size.x-8, plate_rect.size.y-8), 25, PAPER, true)
	if question_index == 0:
		var outline := Control.new()
		outline.set_script(preload("res://tank_highlight.gd"))
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(outline)
		for i in range(2):
			var dimensions := "1,20 M × 0,80 M" if i == 0 else "1,60 M × 1,00 M"
			var label := make_label(dimensions, 21, PAPER, true)
			label.add_theme_color_override("font_shadow_color", DARK)
			label.add_theme_constant_override("shadow_offset_x", 2)
			label.add_theme_constant_override("shadow_offset_y", 2)
			word_place(label, Rect2(345 if i == 0 else 716, 471, 300, 36))
	if question_index > 0:
		var highlight := Control.new()
		highlight.set_script(preload("res://object_highlight.gd"))
		highlight.challenge = question_index
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(highlight)
	var feedback_y := 550 if question_index < 2 else 580
	var footer := Panel.new()
	footer.name = "AnswerFeedback"
	footer.visible = answered
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel", word_style(DARK, 20))
	word_place(footer, Rect2(292, feedback_y, 780, 128))
	feedback_label = make_label("RESPOSTA REGISTRADA. CONTINUE." if answered else "", 24, PAPER, true)
	feedback_label.visible = answered
	word_place(feedback_label, Rect2(310, feedback_y + 12, 744, 38))
	var next := make_button("PRÓXIMO DESAFIO" if question_index < 2 else "CONCLUIR FASE 1", next_question, true)
	next.disabled = not answered
	next.visible = true
	next.add_theme_stylebox_override("disabled", panel_style(Color("#304b48"), Color("#618278"), 18, 2))
	next.add_theme_color_override("font_disabled_color", Color("#a7b9b2"))
	word_place(next, Rect2(482, feedback_y + 60, 400, 64))
	set_meta("next_button", next)
	var gear := Button.new()
	gear.name = "PhaseSettings"
	gear.set_meta("speech", "PAUSAR O JOGO")
	gear.tooltip_text = ""
	gear.add_theme_stylebox_override("normal", word_style(DARK, 17, 3))
	gear.add_theme_stylebox_override("hover", word_style(Color("#235144"), 17, 3))
	gear.add_theme_stylebox_override("focus", word_style(Color.TRANSPARENT, 17, 3))
	gear.pressed.connect(toggle_pause)
	word_place(gear, Rect2(1248, 28, 72, 72))
	var icon := Control.new()
	icon.set_script(preload("res://gear_icon.gd"))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func answer_question(choice: int) -> void:
	if page != "FASE1" or answered:
		return
	var right := choice == int(QUESTIONS[question_index].correct)
	play_word_sound(right)
	get_node("AnswerFeedback").show()
	feedback_label.show()
	if right:
		score += 1
		feedback_label.text = "MUITO BEM! RESPOSTA CERTA."
		feedback_label.add_theme_color_override("font_color", MINT)
	else:
		feedback_label.text = "BOA TENTATIVA! VAMOS CONTINUAR."
		feedback_label.add_theme_color_override("font_color", Color("#ffd095"))
	answered = true
	var next: Button = get_meta("next_button")
	next.disabled = false
	next.show()
	narrator.say(feedback_label.text + " " + next.text)
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
	question_index = 2
	show_question()
	question_index = 3
	page = "RESULTADO1"
	play_celebration(false)
	var cover := ColorRect.new()
	cover.color = Color(0.02, 0.08, 0.08, 0.76)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cover)
	var panel := Panel.new()
	panel.name = "PhaseOneComplete"
	panel.add_theme_stylebox_override("panel", word_style(DARK, 26, 3))
	cover.add_child(panel)
	panel.position = Vector2(302, 194)
	panel.size = Vector2(760, 380)
	report_label(panel, "FASE 1 CONCLUÍDA", Rect2(30, 28, 700, 55), 36, PAPER, true)
	report_label(panel, "VOCÊ ACERTOU %d DE 3 DESAFIOS!" % score, Rect2(30, 112, 700, 48), 30, MINT, true)
	for i in range(2):
		var button := make_button("COMEÇAR FASE 2" if i == 0 else "SALVAR E VOLTAR AO MENU", start_word_search if i == 0 else save_current_progress, i == 0)
		panel.add_child(button)
		button.position = Vector2(100, 208 + i * 82)
		button.size = Vector2(560, 64)

func start_word_search() -> void:
	error_cells.clear()
	selection_locked = false
	word_start = Vector2i(-1, -1)
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
	var glow := Control.new()
	glow.set_script(preload("res://word_glow.gd"))
	glow.segments = completed_segments()
	if not error_cells.is_empty():
		glow.error_segment = [error_cells.front(), error_cells.back()]
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.text = grid[y][x]
			button.set_meta("speech", "LETRA " + grid[y][x])
			button.add_theme_font_size_override("font_size", 23)
			button.add_theme_color_override("font_color", PAPER)
			var fill := Color.TRANSPARENT if found_cells.has(cell) else Color("#22343c")
			if word_start == cell:
				fill = Color("#287fcb")
			if error_cells.has(cell):
				fill = Color.TRANSPARENT
			button.add_theme_stylebox_override("normal", word_style(fill, 4, 0))
			button.add_theme_stylebox_override("hover", word_style(fill if word_start == cell or error_cells.has(cell) else Color(0.25,0.6,1,0.2), 4, 0))
			button.add_theme_stylebox_override("pressed", word_style(Color("#287fcb"), 4, 0))
			button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
	for rect in [Rect2(26,23,140,61), Rect2(178,23,61,61), Rect2(251,23,136,61)]:
		var tile := Panel.new()
		tile.add_theme_stylebox_override("panel", word_style(Color("#12292c"), 16, 2))
		word_place(tile, rect)
	word_place(make_label("FASE 2", 25, MINT, true), Rect2(30,25,132,56))
	var clock_icon := Control.new()
	clock_icon.set_script(preload("res://clock_icon.gd"))
	clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_place(clock_icon, Rect2(178,23,61,61))
	clock_label = make_label(format_time(int(elapsed)), 33, PAPER, true)
	word_place(clock_label, Rect2(255,25,128,56))
	var settings := Button.new()
	settings.tooltip_text = ""
	settings.set_meta("speech", "PAUSAR O JOGO")
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

func select_grid_cell(cell: Vector2i, _button: Button) -> void:
	if is_paused or selection_locked:
		return
	if word_start.x < 0:
		word_start = cell
		narrator.say("LETRA " + grid[cell.y][cell.x] + ". AGORA ESCOLHA A ÚLTIMA LETRA DA PALAVRA.")
		show_word_search()
		return
	var first := word_start
	word_start = Vector2i(-1,-1)
	var delta := cell - first
	var steps := maxi(absi(delta.x), absi(delta.y))
	var selected: Array[Vector2i] = []
	var guess := ""
	if steps > 0 and (delta.x == 0 or delta.y == 0 or absi(delta.x) == absi(delta.y)):
		for i in range(steps + 1):
			var p := first + Vector2i(signi(delta.x), signi(delta.y)) * i
			selected.append(p)
			guess += grid[p.y][p.x]
	else:
		selected.assign([first, cell])
	for word in WORDS:
		if not found_words.has(word) and (guess == strip_accents(word) or guess.reverse() == strip_accents(word)):
			found_words.append(word)
			narrator.say("MUITO BEM! VOCÊ ENCONTROU " + word + ".")
			for p in selected:
				if not found_cells.has(p):
					found_cells.append(p)
			play_word_sound(true)
			show_word_search()
			return
	narrator.say("ESSA NÃO É UMA DAS PALAVRAS. VAMOS TENTAR NOVAMENTE!")
	error_cells.assign(selected)
	selection_locked = true
	play_word_sound(false)
	show_word_search()
	get_tree().create_timer(0.65).timeout.connect(func():
		error_cells.clear()
		selection_locked = false
		if page == "PALAVRAS" and not is_paused:
			show_word_search()
	)

func completed_segments() -> Array:
	var starts := [Vector2i(0,10),Vector2i(13,0),Vector2i(1,3),Vector2i(11,3),Vector2i(7,2),Vector2i(15,1),Vector2i(4,0)]
	var dirs := [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.DOWN,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.RIGHT]
	var result: Array = []
	for i in range(WORDS.size()):
		if found_words.has(WORDS[i]):
			result.append([starts[i], starts[i]+dirs[i]*(strip_accents(WORDS[i]).length()-1)])
	return result

func play_word_sound(correct: bool) -> void:
	var audio := AudioStreamPlayer.new()
	get_tree().root.add_child(audio)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	var count := 8820
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050.0
		var frequency := (660.0 if t < 0.18 else 880.0) if correct else (260.0 - 200.0*t)
		var envelope := minf(t*70,1.0) * maxf(0,1.0-t/0.4)
		var sample := int(sin(TAU*frequency*t)*envelope*5000)
		bytes.encode_s16(i*2,sample)
	wav.data = bytes
	audio.stream = wav
	audio.finished.connect(audio.queue_free)
	audio.play()

func toggle_pause() -> void:
	if is_paused:
		is_paused = false
		if page == "FASE1":
			show_question()
		else:
			show_word_search()
		return
	is_paused = true
	narrator.say("JOGO PAUSADO. CONTINUAR. OU SALVAR E VOLTAR AO MENU.")
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
	play_celebration(true)
	is_paused = false
	clear_snapshot()
	var duration := int(elapsed)
	upsert_report({"aluno": student_name, "fase_1_acertos": score, "fase_1_total": QUESTIONS.size(), "fase_2_encontradas": found_words.size(), "fase_2_total": WORDS.size(), "tempo_fase_2_segundos": duration, "concluido": true, "atualizado_em": Time.get_datetime_string_from_system()})
	clear_screen()
	page = "FINAL"
	add_screen_background(preload("res://final_fundo.png"), Color.TRANSPARENT)
	var gold := Color("#f4df98")
	var content := Control.new()
	word_place(content, Rect2(200, 70, 964, 610))
	report_label(content, "JOGO CONCLUÍDO!", Rect2(20, 20, 924, 70), 48, gold, true)
	report_label(content, "PARABÉNS, " + student_name + "!", Rect2(40, 103, 884, 50), 32, PAPER, true)
	report_label(content, "VOCÊ COMPLETOU AS DUAS FASES.", Rect2(40, 165, 884, 40), 24, gold, true)
	for i in range(2):
		var card := Panel.new()
		var card_style := word_style(Color(0.03,0.14,0.16,0.87), 16, 1)
		card_style.border_color = gold
		card.add_theme_stylebox_override("panel", card_style)
		content.add_child(card)
		card.position = Vector2(72+i*420, 234)
		card.size = Vector2(400, 130)
		report_label(card, "FASE 1 · PONTUAÇÃO" if i == 0 else "FASE 2 · TEMPO", Rect2(20,14,360,36), 23, gold, true)
		report_label(card, "%d DE 3 ACERTOS" % score if i == 0 else format_time(int(elapsed)), Rect2(20,63,360,48), 34, PAPER, true)
	report_label(content, "SEU RESULTADO FOI SALVO NO RELATÓRIO.", Rect2(40,390,884,40), 23, PAPER, true)
	for i in range(2):
		var button := make_button("VER RELATÓRIO" if i == 0 else "VOLTAR AO MENU", show_report if i == 0 else show_menu, i == 0)
		content.add_child(button)
		button.position = Vector2(72+i*420, 470)
		button.size = Vector2(400,70)

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
	report_label(frame, "POSIÇÃO", Rect2(35, 103, 110, 34), 19, MINT, true)
	report_label(frame, "ALUNO", Rect2(165, 103, 370, 34), 19, MINT)
	report_label(frame, "PONTUAÇÃO" if report_phase == 1 else "TEMPO DE CONCLUSÃO", Rect2(605, 103, 250, 34), 19, MINT, true)
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
			badge.position = Vector2(48, 5)
			badge.size = Vector2(34, 34)
		report_label(row, str(i + 1), Rect2(10, 3, 110, 38), 25, DARK if i < 3 else PAPER, true)
		var name_label := report_label(row, str(entry.get("aluno", "")), Rect2(140, 3, 410, 38), 23)
		name_label.tooltip_text = str(entry.get("aluno", "")).to_upper()
		var points := clampi(int(entry.get("fase_1_acertos", 0)), 0, 3)
		for n in range(3 if report_phase == 1 else 0):
			var star := Control.new()
			star.set_script(preload("res://score_star.gd"))
			star.earned = n < points
			row.add_child(star)
			star.position = Vector2(615 + n * 34, 5)
			star.size = Vector2(30, 34)
		if report_phase == 1:
			report_label(row, "%d/3" % points, Rect2(727, 3, 68, 38), 24, PAPER, true)
		else:
			report_label(row, format_time(mini(int(entry.get("tempo_fase_2_segundos", 0)), 3599)), Rect2(580, 3, 250, 38), 27, PAPER, true)
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
	add_screen_background(preload("res://final_fundo.png"), Color.TRANSPARENT)
	var gold := Color("#f4df98")
	report_label(self, "CRÉDITOS", Rect2(200,65,964,80), 50, gold, true)
	var backing := Panel.new()
	backing.add_theme_stylebox_override("panel", word_style(Color(0.025,0.12,0.14,0.78),18))
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_place(backing, Rect2(210,160,944,414))
	var scroll := ScrollContainer.new()
	scroll.name = "CreditsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	word_place(scroll, Rect2(235,178,894,378))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	scroll.add_child(column)
	column.add_child(make_label("JOGO CRIADO POR",26,gold,true))
	var names := ["HENRIQUE GABRIEL KLUCZKOWSKI BRANDT", "HENRIQUE PONTES DE OLIVEIRA", "JOÃO PEDRO MACHADO LIMA", "WILLIAM GONÇALVES MARTINS"]
	for person in names:
		column.add_child(make_label(person,25,PAPER,true))
	column.add_child(make_label("CIÊNCIA DA COMPUTAÇÃO · UTFPR PONTA GROSSA",24,gold,true))
	column.add_child(make_label("DISCIPLINA DE ENGENHARIA DE SOFTWARE",24,gold,true))
	var divider := HSeparator.new()
	column.add_child(divider)
	var sections := [["","Casa Sustentável é um jogo socioeducativo 2D desenvolvido para alunos com deficiência intelectual, com o objetivo de ensinar conceitos de grandezas e medidas de maneira lúdica, acessível e interativa."],["","O jogo apresenta uma temática relacionada à sustentabilidade e ao ambiente doméstico, utilizando elementos visuais, atividades práticas e desafios educativos para estimular o raciocínio, a atenção, a percepção visual e a aprendizagem."],["","O jogo é dividido em duas fases:"],["Primeira fase — Grandezas e Medidas","O jogador participa de atividades interativas nas quais precisa identificar e comparar objetos de diferentes tamanhos, selecionando, por exemplo, qual é o maior entre os elementos apresentados.\n\nA fase conta com instruções simples, tutorial e recursos de áudio para auxiliar na compreensão das atividades. O jogador recebe feedback visual e sonoro de acordo com suas escolhas."],["Segunda fase — Caça-palavras","O jogador deve encontrar palavras relacionadas à sustentabilidade, à casa e aos conceitos trabalhados durante o jogo.\n\nEssa atividade busca estimular a atenção, a identificação de palavras e a associação entre os conteúdos educativos apresentados."],["Recursos do jogo","O jogo possui um menu inicial com opções para começar a partida e visualizar os créditos, além de uma interface em estilo cartoon, com elementos coloridos, botões acessíveis e navegação intuitiva.\n\nAo final das atividades, o sistema gera um relatório de desempenho do jogador, permitindo acompanhar seus resultados durante as fases."],["Objetivo geral","Proporcionar uma experiência educativa inclusiva e divertida, contribuindo para a aprendizagem de grandezas e medidas e para o desenvolvimento de habilidades cognitivas por meio de atividades interativas relacionadas ao cotidiano e à sustentabilidade."]]
	for section in sections:
		if not section[0].is_empty():
			column.add_child(make_label(section[0],26,gold))
		var body := make_label(section[1],23,PAPER)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(body)
	word_place(make_button("VOLTAR AO MENU",show_menu),Rect2(462,600,440,64))

func quit_game() -> void:
	if is_instance_valid(narrator):
		narrator.stop()
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
	narrator.say("FASE DOIS CONCLUÍDA! VOCÊ ENCONTROU TODAS AS SETE PALAVRAS. TEMPO: " + spoken_time() + ". CONTINUAR.")
	play_celebration(false)
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

# FANFARRA CURTA PARA AS FASES; ACORDE E MELODIA MAIS LONGOS NO FINAL.
func play_celebration(epic: bool) -> void:
	for child in get_tree().root.get_children():
		if child is AudioStreamPlayer and child.has_meta("celebration"):
			child.stop()
			child.queue_free()
	var audio := AudioStreamPlayer.new()
	audio.set_meta("celebration", true)
	get_tree().root.add_child(audio)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var duration := 3.8 if epic else 1.8
	var notes := [261.63,329.63,392.0,523.25,659.25,783.99,1046.5] if epic else [523.25,659.25,783.99,1046.5]
	var beat := 0.30 if epic else 0.22
	var bytes := PackedByteArray()
	var count := int(duration * 22050)
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050.0
		var note_index := mini(int(t / beat), notes.size()-1)
		var local_time := t - note_index * beat
		var env := minf(local_time * 60,1.0) * exp(-local_time * 2.4)
		var frequency: float = notes[note_index]
		var melody := (sin(TAU*frequency*t) + 0.25*sin(TAU*frequency*2*t)) * env
		var chord := 0.0
		if epic:
			for hz in [130.815,196.0,261.63,329.63,392.0]:
				chord += sin(TAU*hz*t) * 0.12
			chord *= minf(t*5,1.0)
		var fade := minf((duration-t)*2,1.0)
		bytes.encode_s16(i*2, int(clampf((melody*0.55+chord)*fade,-1,1)*11000))
	wav.data = bytes
	audio.stream = wav
	audio.finished.connect(audio.queue_free)
	audio.play()

func spoken_time() -> String:
	return "%d MINUTOS E %d SEGUNDOS" % [int(elapsed)/60, int(elapsed)%60]

func _narrate_screen() -> void:
	if not is_instance_valid(narrator):
		return
	narrator.bind_controls(self)
	var key := page + str(question_index) + str(report_phase) + str(is_paused)
	if key == last_narrated_screen:
		return
	last_narrated_screen = key
	var message := ""
	match page:
		"MENU": message = "BEM-VINDO À CASA SUSTENTÁVEL! VAMOS APRENDER JUNTOS? ESCOLHA INICIAR JOGO, RELATÓRIO, CRÉDITOS OU SAIR DO JOGO."
		"NOME": message = "DIGITE O SEU NOME. DEPOIS, ESCOLHA COMEÇAR."
		"RETOMAR": message = "VOCÊ TEM UMA PARTIDA SALVA. QUER CONTINUAR DE ONDE PAROU OU REINICIAR?"
		"FASE1": message = "FASE UM. DESAFIO %d DE TRÊS. " % (question_index+1) + QUESTIONS[question_index].ask + " TOQUE NO OBJETO PARA ESCOLHER."
		"RESULTADO1": message = "FASE UM CONCLUÍDA! VOCÊ ACERTOU %d DE TRÊS DESAFIOS. COMEÇAR FASE DOIS. OU SALVAR E VOLTAR AO MENU." % score
		"PALAVRAS":
			if not is_paused: message = "FASE DOIS. CAÇA-PALAVRAS. ENCONTRE AS SETE PALAVRAS DA LISTA. TOQUE NA PRIMEIRA LETRA E DEPOIS NA ÚLTIMA LETRA."
		"RELATORIO": message = "RELATÓRIO DA FASE %d. " % report_phase + ("CADA ACERTO VALE UMA ESTRELA." if report_phase == 1 else "TEMPO DE CONCLUSÃO DA FASE.") + " PASSE O PONTEIRO SOBRE OS RESULTADOS PARA OUVIR."
		"CREDITOS": message = "CRÉDITOS. CONHEÇA OS AUTORES E A PROPOSTA DO JOGO. ROLE PARA BAIXO E PASSE O PONTEIRO SOBRE O TEXTO PARA OUVIR."
		"FINAL": message = "PARABÉNS! VOCÊ COMPLETOU O JOGO! FASE UM: %d ACERTOS. FASE DOIS: " % score + spoken_time() + ". SEU RESULTADO FOI SALVO. VER RELATÓRIO OU VOLTAR AO MENU."
	if not message.is_empty():
		narrator.say(message)
