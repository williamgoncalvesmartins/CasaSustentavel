extends Node
# FRANCISCA NEURAL: ARQUIVOS LOCAIS, SEM SÍNTESE OU REDE DURANTE O JOGO.
var game: Control
var player: AudioStreamPlayer
var process_id := -1 # MANTIDO PARA AS VERIFICAÇÕES DE ENCERRAMENTO.
var last_text := ""
var pending_text := ""
var hover_text := ""
var hover_time := 0.0
var last_mouse := Vector2(-999,-999)
var last_error := ""
var clips: Dictionary = {}
var normalized_clips: Dictionary = {}
var phrases: Array[String] = []
var queue: Array[AudioStream] = []
func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.finished.connect(_next_clip)
	clips = preload("res://audio/francisca/voice_bank.gd").CLIPS
	for text in clips:
		var key := normalize(text)
		normalized_clips[key] = clips[text]
		phrases.append(key)
	phrases.sort_custom(func(a: String,b: String): return a.length()>b.length())
	if not pending_text.is_empty(): say(pending_text)
func clean(text: String) -> String:
	for mark in ["▶","◀","→","★","▤","⏻","✓","○","·"]:
		text = text.replace(mark," ")
	var regex := RegEx.new()
	regex.compile("\\s+")
	return regex.sub(text.to_upper()," ",true).strip_edges()
func normalize(text: String) -> String:
	text = clean(text)
	for mark in [".",",","!","?",":",";","—","-","(",")"]:
		text = text.replace(mark," ")
	return clean(text)
func say(text: String) -> void:
	text = clean(text)
	if text.is_empty(): return
	if not is_instance_valid(player):
		pending_text = text
		return
	if text == last_text and player.playing: return
	stop()
	last_text = text
	if clips.has(text):
		queue.append(clips[text])
	else:
		var clock := RegEx.new()
		clock.compile("(\\d{1,2}):(\\d{2})")
		var match_time := clock.search(text)
		if match_time:
			text = text.replace(match_time.get_string(), "%d MINUTOS E %d SEGUNDOS" % [int(match_time.get_string(1)),int(match_time.get_string(2))])
		text = text.replace("1.000","1000").replace("/"," DE ").replace("×"," POR ")
		var remaining := normalize(text)
		while not remaining.is_empty():
			var matched := false
			for phrase in phrases:
				if remaining == phrase or remaining.begins_with(phrase+" "):
					queue.append(normalized_clips[phrase])
					remaining = remaining.substr(phrase.length()).strip_edges()
					matched = true
					break
			if not matched:
				# NOMES NOVOS SÃO SOLETRADOS LOCALMENTE, SEM ENVIO DE DADOS.
				var letter := remaining.substr(0,1)
				if clips.has(letter): queue.append(clips[letter])
				remaining = remaining.substr(1).strip_edges()
	if queue.is_empty():
		last_error = "NARRAÇÃO NÃO ENCONTRADA: " + text
		push_warning(last_error)
	_next_clip()
func _next_clip() -> void:
	if queue.is_empty(): return
	player.stream = queue.pop_front()
	player.play()
func bind_controls(root: Node) -> void:
	for node in root.find_children("*","BaseButton",true,false):
		if node.has_meta("narration_bound"): continue
		node.set_meta("narration_bound",true)
		var text: String = node.get_meta("speech",node.text if node is Button else "")
		if text.is_empty(): continue
		node.focus_entered.connect(func(): say(text))
		if not node.name.begins_with("Object") and not text.begins_with("LETRA"):
			node.button_down.connect(func(): say(text))
	for node in root.find_children("*","LineEdit",true,false):
		if not node.has_meta("narration_bound"):
			node.set_meta("narration_bound",true)
			node.focus_entered.connect(func(): say("DIGITE O SEU NOME."))
func visible_at(control: Control, point: Vector2) -> bool:
	if not control.is_visible_in_tree() or not control.get_global_rect().has_point(point): return false
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents and not parent.get_global_rect().has_point(point): return false
		parent = parent.get_parent()
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(game): return
	var point := game.get_global_mouse_position()
	if point != last_mouse:
		last_mouse = point
		hover_time = 0.0
		hover_text = ""
		var controls := game.find_children("*","Control",true,false)
		controls.reverse()
		for c in controls:
			if not visible_at(c,point): continue
			if c is Button:
				hover_text = c.get_meta("speech",c.text)
				if c.disabled: hover_text += ". RESPONDA PRIMEIRO PARA CONTINUAR."
				break
			if c is Label and not c.text.is_empty():
				hover_text = c.text
				break
	hover_time += delta
	if hover_time > 0.65 and not hover_text.is_empty():
		var text := hover_text
		hover_text = ""
		say(text)
func stop() -> void:
	pending_text = ""
	hover_text = ""
	queue.clear()
	if is_instance_valid(player): player.stop()
func _exit_tree() -> void:
	stop()
