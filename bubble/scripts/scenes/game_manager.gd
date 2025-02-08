extends Node2D

var sfx_player:AudioStreamPlayer
var bgm_player:AudioStreamPlayer
var common_bgm_player: AudioStreamPlayer
@export var START_CASH: int = 200
var current_cash: int = 0
@export var try_number: int = 0
@export var total_score: int = 0

var current_level_index: int = 0
var level_names: Array[String] = ["前沿阵地","推进战线","高地射击","双塔奇兵","直面核心"]
var level_countdown: Array[int] = [30, 45, 60, 90, 200]
var level_block_id_min: Array[int] = [0, 0, 1, 2, 2]
var level_block_id_max: Array[int] = [3, 4, 5, 7, 7]


var update_cost: Array[int] = [0, 25, 50, 100, 200, 1000]

var MAX_SKILL_LEVEL: int = 5
var slingshot_speed: Array[float] = [1.0, 1.0, 1.0, 1.2, 1.2, 1.5]
var slingshot_length: Array[float] = [150, 175, 200, 225, 250, 300]
var reload_num: Array[int] = [2, 2, 3, 3, 4, 4]
var reload_time: Array[float] = [3.0, 2.5, 2.5, 2.0, 2.0, 1.0]
var bullet_impact_threhsold: Array[float] = [1000, 1500, 2000, 2500, 2500, 3000]
var bullet_required_impacts: Array[int] = [1, 1, 2, 2, 3, 4]

var extra_profit: Array[int] = [0, 2, 5, 8, 10, 50]


var slingshot_level: int = 0
var reloader_level: int = 0
var bullet_level: int = 0
var economy_level: int = 0

@export var into_mode_2: bool = false


func reset_game_manager() -> void:
	slingshot_level = 0
	reloader_level = 0
	bullet_level = 0
	economy_level = 0
	try_number = 0
	current_cash = START_CASH
	into_mode_2 = false
	print("game manager reset")


func get_cash() -> int:
	return current_cash

func spend_cash(amount: int) -> void:
	print("spend cash", amount)
	current_cash -= amount
	
func add_cash(amount: int) -> void:
	print("add cash", amount)
	current_cash += amount
	total_score += amount

func get_cur_slingshot_speed() -> int:
	return slingshot_speed[slingshot_level]
	
func get_cur_slingshot_max_length() -> int:
	return slingshot_length[slingshot_level]

func get_cur_reload_num() -> int:
	return reload_num[reloader_level]

func get_cur_reload_time() -> float:
	return reload_time[reloader_level]

func get_cur_bullet_impact_threshold() -> float:
	return bullet_impact_threhsold[bullet_level]

func get_cur_bullet_required_impacts() -> int:
	return bullet_required_impacts[bullet_level]

func get_extra_profit() -> int:
	return extra_profit[economy_level]

func get_update_cost(level: int) -> int:
	return update_cost[level]
	
func level_up_slingshot() -> void:
	slingshot_level+= 1

func level_up_reloader() -> void:
	reloader_level+=1

func level_up_bullet() -> void:
	bullet_level+=1

func level_up_economy() -> void:
	economy_level+=1
	
	
	
@export var min_pitch := 0.9
@export var max_pitch := 1.1

func play_sound(impact_force):
	if sfx_player == null:
		return
	print("on body entered")
	
	# 根据速度调整音量
	sfx_player.volume_db = remap(impact_force, 200, 3000, -20, -10)  # 速度映射到-30~0dB
	
	# 随机音高避免机械感
	sfx_player.pitch_scale = randf_range(min_pitch, max_pitch)
	
	if not sfx_player.playing:
		print("play sound", sfx_player.volume_db)
		sfx_player.play()
		
func play_bgm():
	if bgm_player == null:
		print("bgm player is null")
		return
	if not bgm_player.playing:
		bgm_player.play()
		
func stop_bgm():
	if bgm_player == null:
		print("bgm player is null")
		return
	bgm_player.stop()
		
func play_common_bgm():
	if bgm_player == null:
		print("common bgm player is null")
		return
	if not common_bgm_player.playing:
		common_bgm_player.play()

func stop_common_bgm():
	if bgm_player == null:
		print("common bgm player is null")
		return
	
	common_bgm_player.stop()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_game_manager()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
