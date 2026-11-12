extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.show_credits()
	await process_frame
	await process_frame
	var scroll = game.get_node("CreditsScroll")
	assert(scroll.get_v_scroll_bar().max_value > scroll.size.y)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://credits_top.png")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://credits_bottom.png")
	assert(scroll.scroll_vertical > 0)
	var texts := ""
	for label in game.find_children("*","Label",true,false):
		texts += label.text
	assert(texts.contains("OBJETIVO GERAL") and texts.contains("DEFICIÊNCIA INTELECTUAL"))
	assert(texts == texts.to_upper())
	print("PASS: FULL CREDITS; UPPERCASE; VERTICAL SCROLL")
	quit()
