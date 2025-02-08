extends Node2D


@export var levels: Array[PackedScene] = [
	preload("res://scripts/levels/level2_00.tscn"),
	preload("res://scripts/levels/level2_01.tscn"),
	preload("res://scripts/levels/level2_02.tscn"),
	preload("res://scripts/levels/level2_03.tscn"),
	preload("res://scripts/levels/level2_04.tscn")
]

@export var s_shop: PackedScene = preload("res://scripts/scenes/shop.tscn")
@export var s_levelguide: PackedScene = preload("res://scripts/scenes/levelGuide.tscn")
@export var s_victoryScroll: PackedScene = preload("res://scripts/scenes/VictoryScroll.tscn")

var current_level_index: int = 0
var current_level: Level:
	set(value):
		print("Change Current Level: ", value)
		if (current_level != null): #如果当前有关卡
			current_level.sig_victory.disconnect(_on_current_level_victory)
			current_level.sig_defeat.disconnect(_on_current_level_defeat)
			remove_child(current_level)
			current_level.queue_free()
		current_level = value
		if (current_level != null):
			add_child(current_level)
			current_level.sig_victory.connect(_on_current_level_victory)
			current_level.sig_defeat.connect(_on_current_level_defeat)
		else:
			pass
		
@onready var label: Label = $CanvasLayer/game/popup_game_over/VBoxContainer/MarginContainer/Label
@onready var btn_quit: Button = $CanvasLayer/game/popup_game_over/VBoxContainer/MarginContainer2/HBoxContainer/btn_quit
@onready var btn_confirm: Button = $CanvasLayer/game/popup_game_over/VBoxContainer/MarginContainer2/HBoxContainer/btn_confirm


@onready var popup_game_over: MarginContainer = $CanvasLayer/game/popup_game_over





var is_success: bool = false


func _ready() -> void:
	popup_game_over.hide()
	btn_quit.pressed.connect(
		func() -> void:
			get_tree().quit()
	)
	btn_confirm.pressed.connect(
		func() -> void:
			if is_success:
				if (GameManager.current_level_index == 4):
					GameManager.try_number += 1
				GameManager.stop_common_bgm()
				GameManager.stop_bgm()
				goto_shop()
				#next_level()
			else:
				#load_level()
				GameManager.try_number += 1
				GameManager.stop_common_bgm()
				GameManager.stop_bgm()
				load_first_level()
			popup_game_over.hide()
	)
	load_level()		
	
func goto_shop() -> void:
	current_level = null
	var shop = s_shop.instantiate()
	get_tree().root.add_child(shop)
	shop.sig_next_level.connect(
		func() -> void:
			shop.queue_free()
			next_level()
	)

func show_popup_game_over() -> void:
	var cur_level_idx = GameManager.current_level_index
	if (cur_level_idx == 4):
		label.text = "暂时撤离...." if is_success else "遗憾落败！"
		btn_confirm.text = "再次挑战" if is_success else "重试"
	else:
		label.text = "恭喜过关！" if is_success else "遗憾落败！"
		btn_confirm.text = "下一关" if is_success else "重试"
	popup_game_over.show()

#进入下一关
func next_level() -> void:
	if levels.size() -1 > current_level_index:
		current_level_index += 1
		GameManager.current_level_index = current_level_index
	
	load_level()

#加载当前关卡
func load_level() -> void:
	GameManager.play_common_bgm()
	var level_guide = s_levelguide.instantiate()
	get_tree().root.add_child(level_guide)
	await level_guide.sig_levelguide_over
	get_tree().root.remove_child(level_guide)
	level_guide.queue_free()
	
	print("load level: level ", current_level_index)
	current_level = levels[current_level_index].instantiate()
	if (current_level_index == 4):
		current_level.sig_total_victory.connect(_on_total_victory)

#加载最初
func load_first_level() -> void:
	current_level_index = 0
	GameManager.current_level_index = current_level_index
	load_level()




func _on_current_level_victory() -> void:
	is_success = true
	await current_level.reset_camera()
	show_popup_game_over()

func _on_current_level_defeat() -> void:
	is_success = false
	await current_level.reset_camera()
	show_popup_game_over()

func _on_total_victory() -> void:
	await current_level.reset_camera()
	current_level.queue_free()
	var victory_scroll = s_victoryScroll.instantiate()
	get_tree().root.add_child(victory_scroll)
	await victory_scroll.sig_scrolltitle_over
	get_tree().root.remove_child(victory_scroll)
	victory_scroll.queue_free()
	get_tree().quit()
	
	
