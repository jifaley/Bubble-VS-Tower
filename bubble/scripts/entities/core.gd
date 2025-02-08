extends Block

class_name Core

@onready var sprite_2d: Sprite2D = $Sprite2D

signal sig_core_destroyed
signal sig_mode_2

var original_modulate
var mode_2_start: bool = false
@export var danger_hits :int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_modulate = sprite_2d.modulate
	mode_2_start = false
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	var contact_count = state.get_contact_count()
	for i in range(contact_count):
		var collider = state.get_contact_collider(i)
		var impact_force = state.get_contact_impulse(i).length()
		
		
		
		if impact_force >= impact_threshold:
			
			var tween = create_tween()
			original_modulate = sprite_2d.modulate
			tween.tween_property(sprite_2d, "modulate", Color(1, 0, 0, 0.8), 0.1)  # 半透红
			tween.tween_property(sprite_2d, "modulate", original_modulate, 0.1)
			
			if impact_force >= impact_threshold * 2:
				impact_count += 2
			elif impact_force >= impact_threshold:
				impact_count += 1
		
			if impact_count >= danger_hits and mode_2_start == false:
				print("mode 2 start!")
				mode_2_start = true
				tween.tween_property(sprite_2d, "modulate", Color(0.8, 0, 0, 1), 0.1)  # 半透红
				sig_mode_2.emit()
			
				
		if impact_count >= required_impacts:
			break_object()
	
	# 按间隔时间检测落地状态
	if (not is_onground):
		time_since_last_check += state.step
		if time_since_last_check >= check_interval:
			time_since_last_check = 0.0
			if state.linear_velocity.length() < velocity_threshold and abs(state.angular_velocity) < angular_threshold:
				is_onground = true					
				self.gravity_scale = 1


func break_object() -> void:
	#添加金钱
	if self == null:
		return
	if is_locked == false:
		#锁定，否则可能多重释放
		is_locked = true
		# 显示绿色文字提示
		show_money_popup(money_reward * 100)
		sig_core_destroyed.emit()
		self.queue_free() 
