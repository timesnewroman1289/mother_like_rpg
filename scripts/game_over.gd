## Game over: continue from the last save frog, or start over.
extends Node2D

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ChoiceList = preload("res://scripts/ui/choice_list.gd")


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(320, 240)
	add_child(bg)

	var title := UIKit.make_label(self, "GAME OVER", Vector2(0, 70))
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(320, 30)

	var box := UIKit.make_box(self, Rect2(60, 130, 200, 50))
	UIKit.make_label(box, "• Don't give up! Continue?", Vector2(10, 5))
	var list := ChoiceList.new()
	list.horizontal = true
	list.cell = Vector2(88, 16)
	list.position = Vector2(10, 26)
	list.allow_cancel = false
	box.add_child(list)
	list.set_items(["Continue", "Start over"])

	var pick: int = await list.choose(0)
	if pick == 0:
		Game.load_save()
	else:
		Game.new_game()
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")
