extends Node2D

@onready var line_2d : Line2D = $Line2D
@onready var marker_2d : Marker2D = $Marker2D
@onready var line_2d_2 : Line2D = $Line2D2
@onready var shotbag : Sprite2D = $ShotBag
@onready var area_2d : Area2D = $Area2D

signal aiming_started
signal aiming_canceled


var start_position : Vector2
var drag_position : = Vector2.ZERO


@export var max_stretch_length : float = 100

#制作显示弹道抛物线
var point_texture = preload("res://assets/textures/point.png")
var points = []
#最大显示点数
@export var max_points : int = 20
#初始速度
@export var initial_velocity_factor : float = 10
#重力

@export var upgrade_slingshot_factor: float = 1

var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")


var bullet = null:
	set(value):
		if bullet != null:#如果旧值存在
			marker_2d.remove_child(bullet)
			bullet.queue_free()
		bullet = value
		if bullet != null:
			marker_2d.add_child(bullet)
			#先设置为无重力
			bullet.gravity_scale = 0
		
			

func _ready() -> void:
	start_position = marker_2d.position
	area_2d.input_event.connect(_on_area_2d_input_event)
	_setup_trajectory_points()
	line_2d.visible = false
	line_2d_2.visible = false
	shotbag.visible = false
	

#初始化弹道显示抛物线
func _setup_trajectory_points() -> void:
	for i in range(max_points):
		var point = Sprite2D.new()
		point.texture = point_texture
		points.append(point)
		add_child(point)
		point.visible = false
		

#瞄准	
func aiming() -> void:
	_update_sling_band()
	_update_trajectory()
	line_2d.visible = true
	line_2d_2.visible = true
	shotbag.visible = true

#发射子弹
func launch() -> void:
	bullet.gravity_scale = 1
	bullet.linear_velocity = _get_launch_velocity()
	line_2d.visible = false
	line_2d_2.visible = false
	shotbag.visible = false
		
#更新橡皮筋的显示效果
func _update_sling_band() -> void:
	var local_mouse_pos = get_local_mouse_position()
	var stretch_vector = local_mouse_pos - start_position
	#截断拉伸角度，只能向后拉弹弓
	if stretch_vector.x > -50:
		stretch_vector.x = -50
	#截断拉伸长度，不能无限拉长
	stretch_vector = _clamp_vector_to_length(stretch_vector, max_stretch_length)
	drag_position = start_position + stretch_vector
	line_2d.points[1] = drag_position + Vector2(-25, 15)
	line_2d_2.points[1] = drag_position + Vector2(-25, 15)
	shotbag.position = drag_position + Vector2(-25, 15)
	bullet.global_position = to_global(drag_position)

#更新抛物线
func _update_trajectory() -> void:
	var initial_velocity = _get_launch_velocity()
	var time_step = 0.1
	var total_time = 2.0
	var current_time = 0.0
	var index = 0
	while (current_time <= total_time and index < max_points):
		points[index].global_position = to_global(
			Vector2(
			start_position.x + initial_velocity.x * current_time,
			start_position.y + initial_velocity.y * current_time + gravity * current_time * current_time * 0.5
			)
		)
		points[index].visible = true
		current_time += time_step
		index += 1
	for i in range(index, max_points):
		points[i].visible = false
		

	


#获取初始速度
func _get_launch_velocity() -> Vector2:
	var stretch_vector = start_position - drag_position
	return stretch_vector * initial_velocity_factor * upgrade_slingshot_factor

#截断向量长度
func _clamp_vector_to_length(v: Vector2, max_length: float) -> Vector2:
	return v.normalized() * max_length if max_length < v.length() else v
	


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			aiming_started.emit()
		elif event.is_released():
			aiming_canceled.emit()
			drag_position = start_position
			for p in points:
				p.visible = false
