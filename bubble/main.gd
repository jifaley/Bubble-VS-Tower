extends Node2D

@onready var menu: Node2D = $Menu
var s_game: PackedScene = preload("res://scripts/scenes/game.tscn")

@export var s_titlescroll: PackedScene = preload("res://scripts/scenes/titleScroll.tscn")


var game:Node2D
var titlescroll:Node2D

func _ready() -> void:
	var camera_2d = get_viewport().get_camera_2d()
	if camera_2d != null:
		print("In Main camera 2d is not null!")
	else:
		print("In Main camera 2d is null!")
	print(camera_2d)
	
	var camera_3d = get_viewport().get_camera_3d()
	if camera_3d != null:
		print("In Main camera 3d is not null!")
	else:
		print("In Main camera 3d is null!")
	print(camera_3d)
	
	GameManager.sfx_player = $AudioStreamPlayer2D
	GameManager.bgm_player = $BgmPlayer
	GameManager.common_bgm_player = $CommonBgmPlayer

	
	
	print("_ready 调用")
	menu.sig_game_pressed.connect(
		func() -> void:
			print("game_pressed已接受")
			self.remove_child(menu)
			menu.queue_free()
			
			titlescroll = s_titlescroll.instantiate()
			self.add_child(titlescroll)
			
			#await get_tree().create_timer(10).timeout
			await titlescroll.sig_scrolltitle_over
			await get_tree().create_timer(1).timeout
			self.remove_child(titlescroll)
			titlescroll.queue_free()
			
			game = s_game.instantiate()
			self.add_child(game)
	)
	print("已连接")
