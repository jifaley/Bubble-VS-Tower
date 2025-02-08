extends Node2D

class_name Level

enum GAME_STATE
{
	READY,
	WAITING,
	AIMING,
	LAUNCHED,
	TURN_END,
	VICTORY,
	DEFEAT
}

@onready var spawnPoints: Array[Marker2D] = [
	$GenerateRocks,
	$GenerateRocks2,
	$GenerateRocks3
]

@export var blocks: Array[PackedScene] = [
	preload("res://scripts/entities/Block_010.tscn"),
	preload("res://scripts/entities/Block_027.tscn"),
	preload("res://scripts/entities/Block_028.tscn"),
	preload("res://scripts/entities/Block_035.tscn"),
	
	preload("res://scripts/entities/Block_012.tscn"),
	preload("res://scripts/entities/Block_020.tscn"),
	
	preload("res://scripts/entities/Block_Metal013.tscn"),
	preload("res://scripts/entities/Block_Metal021.tscn")
]

@export var enemies: Array[PackedScene] = [
	preload("res://scripts/entities/Enemy.tscn"),
	preload("res://scripts/entities/Enemy.tscn"),
	preload("res://scripts/entities/Enemy2.tscn")
]

var game_state: GAME_STATE = GAME_STATE.READY:
	set(value):
		print("状态切换: ", GAME_STATE.keys()[value])
		game_state = value
		match game_state:
			GAME_STATE.WAITING:
				waiting()
			GAME_STATE.LAUNCHED:
				launch()
			GAME_STATE.TURN_END:
				end_turn()
			GAME_STATE.VICTORY:
				sig_victory.emit()
			GAME_STATE.DEFEAT:
				count_down_timer.stop()
				sig_defeat.emit()

@onready var slingshot: Node2D = $Slingshot
@onready var core_inst: Core = $core

@onready var bullets: Node2D = $Bullets

@export var bullet_num: int = 1
@export var reload_time: float = 3
@export var ENEMY_SPAWN_TIME: int = 7
@export var BLOCK_SPAWN_TIME: int = 4

@onready var timer_label: Label = %TimerLabel
@onready var count_down_timer: Timer = %CountDownTimer

@onready var cut_line_marker: Marker2D = %cutLineMarker
@onready var btn_reload: Button = $CanvasLayer2/btn_reload
@onready var progress_bar: ProgressBar = $CanvasLayer2/btn_reload/ProgressBar
@onready var reload_timer: Timer = $CanvasLayer2/btn_reload/ReloadTimer


@onready var cash_label: Label = $CanvasLayer2/cash_label

@onready var camera_2d: Camera2D = $Camera2D
@onready var sub_viewport: SubViewport = $CanvasLayer2/SubViewportContainer/SubViewport

@onready var upright: Marker2D = $upright
@onready var downleft: Marker2D = $downleft


var cur_bullet_impact_threshold: float = 500
var	cur_bullet_required_impacts: int = 1
var cur_extra_profit: int = 1

var generate_bullet_idx: int = 0
var onload_bullet_idx: int = 0

var s_bullet_arr: Array[PackedScene] = [
	preload("res://scripts/entities/Bullet.tscn"),
	preload("res://scripts/entities/Bullet2.tscn"),
	preload("res://scripts/entities/Bullet3.tscn")
]

var s_bullet : PackedScene = preload("res://scripts/entities/Bullet.tscn")
var bullet: RigidBody2D:
	set(value):
		bullet = value
		slingshot.bullet = value

#视为子弹静止的阈值速度
@export var MIN_VELOCITY_THRESHOLD: float = 50

#碰撞后等待时间(s)
@export var COLLISION_WAIT_TIME: float = 0.5
var last_collision_time: float = 0

#倒计时
@export var WAVE_TIME = 60
var cur_time = 0
var time_left = 0

var mode_2_activate:bool = false
@export var MODE_2_BLOCK_SPAWN_TIME: int = 20

signal sig_victory
signal sig_defeat
signal sig_total_victory

@export var camera_node: Node2D
@export var player_node: Node2D


func _ready() -> void:
	camera_node.global_position = player_node.global_position
	sub_viewport.world_2d = camera_2d.get_world_2d()#get_tree().root.world_2d
	slingshot.visible = true
	slingshot.aiming_started.connect(_on_slingshot_aiming_started)
	slingshot.aiming_canceled.connect(_on_slingshot_aiming_canceled)
	
	slingshot.upgrade_slingshot_factor = GameManager.get_cur_slingshot_speed()
	slingshot.max_stretch_length = GameManager.get_cur_slingshot_max_length()
	cur_bullet_impact_threshold = GameManager.get_cur_bullet_impact_threshold()
	cur_bullet_required_impacts = GameManager.get_cur_bullet_required_impacts()
	bullet_num = GameManager.get_cur_reload_num()
	reload_time = GameManager.get_cur_reload_time()
	cur_extra_profit = GameManager.get_extra_profit()
	var cur_level_index = GameManager.current_level_index
	WAVE_TIME = GameManager.level_countdown[cur_level_index]
	mode_2_activate = false
	GameManager.into_mode_2 = false
	
	reload_ready()
	update_cash()
	level_ready()

	

	
func _process(delta: float) -> void:
	
	if game_state == GAME_STATE.AIMING:
		aiming()
	elif game_state == GAME_STATE.LAUNCHED:
		update_camera_position()
		if bullet == null or _is_turn_end():
			game_state = GAME_STATE.TURN_END
			

#关卡初始化
func level_ready() -> void:
	if game_state != GAME_STATE.READY: return
	
	var cur_level_index: int = GameManager.current_level_index
	if cur_level_index == 4:
		if core_inst != null:
			core_inst.sig_core_destroyed.connect(
				func() -> void:
				sig_total_victory.emit()
			)
			core_inst.sig_mode_2.connect(
				mode_2_start
			)
			shake_camera(camera_2d,4,2)
		await get_tree().create_timer(3).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	await reset_camera() #注意此处，要等待函数内部结束否则内部的await失效
	reload_bullets()
	time_left = WAVE_TIME
	cur_time = -1
	timer_label.text = str(time_left)
	timer_label.visible = true
	count_down_timer.connect("timeout", _on_CountdownTimer_timeout)
	
func level_gameover() -> void:
	count_down_timer.stop()
	slingshot.visible = false
	
	
	
func _on_CountdownTimer_timeout():
	if time_left > 0:
		time_left -= 1
		cur_time += 1
		timer_label.text = str(time_left).pad_zeros(2)  # 确保显示两位数字
		if (cur_time % ENEMY_SPAWN_TIME == 0):
			spawn_one_enemy()
		if (cur_time % BLOCK_SPAWN_TIME == 0):
			spawn_one_block()
		if (mode_2_activate and cur_time % MODE_2_BLOCK_SPAWN_TIME == 0):
			enemy_reinforce()
		check_max_height()
		update_cash()
	else:
		# 倒计时结束，停止计时器
		count_down_timer.stop()
		timer_label.text = "00"
		slingshot.visible = false
		bullets.visible = false
		game_state = GAME_STATE.VICTORY

func spawn_one_enemy() -> void:
	var spawnPointIdx = randi_range(0, spawnPoints.size() - 1)
	var enemyIdx = randi_range(0, enemies.size() - 1)
	#print("spawnPointIdx: ", spawnPointIdx, " enemyIdx: ", enemyIdx)
	#print(spawnPoints)
	var spawnLoc: Vector2 = spawnPoints[spawnPointIdx].position
	var enemy = enemies[enemyIdx].instantiate()
	enemy.position = Vector2.ZERO
	enemy.gravity_scale = 0.2
	enemy.linear_damp = 0.2
	enemy.angular_damp = 0.2
	enemy.money_reward = enemy.money_reward + cur_extra_profit
	spawnPoints[spawnPointIdx].add_child(enemy)
	
func spawn_one_block_target(spawnPointIdx:int) -> void:
	var cur_level_index: int = GameManager.current_level_index
	var blockIdx_min: int = GameManager.level_block_id_min[cur_level_index]
	var blockIdx_max: int = GameManager.level_block_id_max[cur_level_index]
	
	var blockIdx = randi_range(blockIdx_min, blockIdx_max)
	#print("spawnPointIdx: ", spawnPointIdx, " blockIdx: ", blockIdx)
	#print(spawnPoints)
	var spawnLoc: Vector2 = spawnPoints[spawnPointIdx].position
	var block = blocks[blockIdx].instantiate()
	block.position = Vector2.ZERO
	block.gravity_scale = 0.2
	block.linear_damp = 0.2
	block.angular_damp = 0.2
	block.money_reward = block.money_reward + cur_extra_profit
	spawnPoints[spawnPointIdx].add_child(block) 

func spawn_one_block() -> void:
	var spawnPointIdx = randi_range(0, spawnPoints.size() - 1)
	
	var cur_level_index: int = GameManager.current_level_index
	var blockIdx_min: int = GameManager.level_block_id_min[cur_level_index]
	var blockIdx_max: int = GameManager.level_block_id_max[cur_level_index]
	
	var blockIdx = randi_range(blockIdx_min, blockIdx_max)
	#print("spawnPointIdx: ", spawnPointIdx, " blockIdx: ", blockIdx)
	#print(spawnPoints)
	var spawnLoc: Vector2 = spawnPoints[spawnPointIdx].position
	var block = blocks[blockIdx].instantiate()
	block.position = Vector2.ZERO
	block.gravity_scale = 0.2
	block.linear_damp = 0.2
	block.angular_damp = 0.2
	block.money_reward = block.money_reward + cur_extra_profit
	spawnPoints[spawnPointIdx].add_child(block) 

func mode_2_start() -> void:
	mode_2_activate = true
	GameManager.into_mode_2 = true
	GameManager.stop_common_bgm()
	GameManager.play_bgm()
	enemy_reinforce()

func enemy_reinforce() -> void:
	for i in range(3):
		spawn_one_block_target(i)
	
	
	
func check_max_height() -> bool:
	var highest_point: float
	highest_point = 630
	for spawnPoint in spawnPoints:
		for child in spawnPoint.get_children():
			if child is Destructable and child.is_onground:
				if child.global_position.y < highest_point:
					highest_point = child.global_position.y  # 找到最高的物体
	#print(highest_point, '---', cut_line_marker.global_position.y)
	if (highest_point < cut_line_marker.global_position.y):
		slingshot.visible = false
		bullets.visible = false
		game_state = GAME_STATE.DEFEAT
				
	return true

func update_cash() -> void:
	var current_cash = GameManager.get_cash()
	cash_label.text = ("Cash: $%d" % current_cash)

func reload_ready() -> void:

	btn_reload.pressed.connect(push_reload_button)
	btn_reload.visible = false
	progress_bar.visible = false
	progress_bar.max_value = reload_time
	progress_bar.value = 0

func push_reload_button() -> void:
	btn_reload.disabled = true
	progress_bar.visible = true
	progress_bar.value = 0
	# 启动 Tween 动画
	var tween: Tween = create_tween()
	tween.tween_property(progress_bar, "value", reload_time, reload_time)
	await  tween.finished
	progress_bar.visible = false
	reload_bullets()
	
	

func reload_bullets() -> void:
	var temp_bullet_num = bullet_num
	if (mode_2_activate):
		bullet_num = bullet_num + 3
	
	print("Reloading Bullets ", "bulletnum = %d" % bullet_num)
	if (bullet_num < 1): return
	var bullet_position_span_x: int = 80
	var bullet_position_offset_x: int = 0
	onload_bullet_idx = generate_bullet_idx
	bullets.visible = true
	for i in range(bullet_num - 1):
		await get_tree().create_timer(0.3).timeout
		generate_bullet_idx = generate_bullet_idx + 1
		
		s_bullet = s_bullet_arr[generate_bullet_idx % 3]
		var cur_bullet = s_bullet.instantiate()
		bullet_position_offset_x -= bullet_position_span_x
		cur_bullet.position.x += bullet_position_offset_x
		cur_bullet.bullet_idx = generate_bullet_idx
		cur_bullet.gravity_scale = 0.2
		bullets.add_child(cur_bullet)
		
		print("i = %d " % i," bullet_idx = %d" % generate_bullet_idx)
		
	btn_reload.visible = false
	btn_reload.disabled = false
	bullet_num = temp_bullet_num
	game_state = GAME_STATE.WAITING
	
	

#等待玩家输入
func waiting() -> void:
	s_bullet = s_bullet_arr[onload_bullet_idx % 3]
	print("load_bullet_idx = %d" % onload_bullet_idx)
	bullet = s_bullet.instantiate()
	bullet.impact_threshold = cur_bullet_impact_threshold
	bullet.required_impacts = cur_bullet_required_impacts
	bullet.mass *= (1 + (cur_bullet_required_impacts - 1) / 2.0)
	bullet.body_entered.connect(_on_bullet_body_entered)
	bullet.angular_damp = 0.2
	if bullet is bullet:
		bullet.sig_bullet_crash.connect(
			func() -> void:
				pass
				#shake_camera(camera_2d, 0.5, 0.2)
		)

#进行瞄准
func aiming() -> void:
	slingshot.aiming()

#进行发射
func launch() -> void:
	slingshot.launch()
	
#结束回合
func end_turn() -> void:
	
	if (bullet != null and bullet.is_locked == false):
		bullet.body_entered.disconnect(_on_bullet_body_entered)
		bullet.break_object()
		
	bullet = null

	if not _has_bullet():
		await reset_camera()
		if (mode_2_activate):
			btn_reload.text = "友情的力量！"
			btn_reload.modulate = Color(1, 0.843137, 0)
		else:
			btn_reload.text = "集结部队！"
			btn_reload.modulate = Color(1, 1, 1)
		btn_reload.visible = true
		
	else:
		await reset_camera()
		#bullets.remove_child(bullets.get_child(0))
		var child_0 = bullets.get_child(0)
		
		print("remove bullet idx: %d" % child_0.bullet_idx)
		
		var reset_position: Vector2 = slingshot.marker_2d.global_position + Vector2(-30, -50)
		var reset_position_2: Vector2 = slingshot.marker_2d.global_position
		
		var tween: Tween = create_tween()
		tween.tween_property(child_0, "global_position", reset_position, 1)
		
		tween.tween_property(child_0, "global_position", reset_position_2, 0.5)
		await tween.finished
		
		
		onload_bullet_idx = child_0.bullet_idx
		
		bullets.remove_child(child_0)
		
		if (bullets.get_child_count() != 0):
			for bulletLeft in bullets.get_children():
				bulletLeft.sleeping = false
		game_state = GAME_STATE.WAITING

	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_released() and game_state == GAME_STATE.AIMING:
			game_state = GAME_STATE.LAUNCHED
			
#摄像机跟随子弹移动
func update_camera_position() -> void:
	if not bullet:
		return
	if bullet.linear_velocity.length() > MIN_VELOCITY_THRESHOLD:
		camera_2d.global_position = bullet.global_position


#摄像机复位
func reset_camera() -> void:
	var tween: Tween = create_tween()
	var reset_position: Vector2
	reset_position.x = get_viewport_rect().size.x * 0.5
	reset_position.y = get_viewport_rect().size.y * 0.5
	tween.tween_property(camera_2d, "position", reset_position, 1.5)
	#补间动画执行2s，继续用await挂起
	await tween.finished
	
#判断当前是否回合结束
func _is_turn_end() -> bool:
	return _is_bullet_outofcontrol() or (
	_is_bullet_stopped() and _has_no_new_collision())

#判断发射出的子弹是否已经静止
func _is_bullet_stopped() -> bool:
	return bullet.linear_velocity.length() < MIN_VELOCITY_THRESHOLD
	
func _is_bullet_outofcontrol() -> bool:
	var pos: Vector2 = bullet.global_position
	if (pos.x < downleft.global_position.x or pos.x > upright.global_position.x): 
		return true
	if (pos.y > downleft.global_position.y or pos.y < upright.global_position.y):
		return true
	return false
	
#判断一段时间内未产生新的碰撞
func _has_no_new_collision() -> bool:
	return Time.get_ticks_msec() - last_collision_time > COLLISION_WAIT_TIME
	
#判断是否还有敌人
func _has_enemy() -> bool:
	return get_tree().get_nodes_in_group("enemy").size() > 0

#判断是否还有可用子弹
func _has_bullet() -> bool:
	return bullets.get_child_count() > 0

func _on_slingshot_aiming_started() -> void:
	if game_state != GAME_STATE.WAITING: return
	game_state = GAME_STATE.AIMING
	
func _on_slingshot_aiming_canceled() -> void:
	if game_state != GAME_STATE.AIMING: return
	game_state = GAME_STATE.WAITING
	
func _on_bullet_body_entered() -> void:
	last_collision_time = Time.get_ticks_msec()

@export var shake_intensity = 0.2  # 抖动强度
@export var shake_duration = 0.5   # 抖动持续时间，单位为秒
@export var shake_interval = 0.02  # 抖动间隔，单位为秒

var shake_timer: Timer
var original_position: Vector2
var camera: Camera2D
var start_time: int

func shake_camera(camera_node: Camera2D, intensity: float, duration: float):
	camera = camera_node
	shake_intensity = intensity
	shake_duration = duration
	original_position = camera.position
	start_time = Time.get_ticks_msec()

	# 创建并配置 Timer 节点
	shake_timer = Timer.new()
	shake_timer.wait_time = shake_interval
	shake_timer.one_shot = false
	add_child(shake_timer)

	# 连接信号
	shake_timer.timeout.connect(_on_shake_timer_timeout)

	# 启动计时器
	shake_timer.start()

func _on_shake_timer_timeout():
	if shake_timer == null:
		return
	var current_time = Time.get_ticks_msec()
	var elapsed_time = (current_time - start_time) / 1000.0  # 转换为秒
	if elapsed_time > shake_duration:
		# 抖动结束，重置相机位置
		camera.position = original_position
		shake_timer.stop()  # 停止计时器
		shake_timer.queue_free()  # 删除 Timer 节点
	else:
		# 计算抖动衰减
		var decay = 1.0 - (elapsed_time / shake_duration)
		var current_intensity = shake_intensity * decay

		# 计算抖动偏移
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		# 平滑过渡到新位置
		camera.position = original_position.lerp(camera.position + shake_offset, 0.1)
