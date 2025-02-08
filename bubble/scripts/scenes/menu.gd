extends Node2D

#@onready var btn_new_game_maintitle: Button = %btn_new_game_maintitle
@onready var btn_settings: Button = %btn_settings
@onready var btn_credits: Button = %btn_credits
#@onready var btn_quit: Button = %btn_quit


@onready var btn_new_game_maintitle: TextureButton = %TextureButton
@onready var btn_quit: TextureButton = %TextureButton2



signal sig_game_pressed

func _ready() -> void:
	btn_new_game_maintitle.pressed.connect(
		func() -> void:
			sig_game_pressed.emit()
			print("game_pressed已释放")
			
	)
	btn_quit.pressed.connect(
		func() -> void:
			get_tree().quit()
	)
