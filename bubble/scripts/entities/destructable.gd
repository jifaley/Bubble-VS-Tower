extends RigidBody2D

class_name Destructable

#认为受到冲击的阈值
@export var impact_threshold: int = 500
#可受攻击的次数
@export var required_impacts: int = 1
#已收攻击次数
var impact_count: int = 0

# 落地状态
var is_onground: bool = false
# 锁定状态
var is_locked: bool = false
# 判断静止的速度阈值
@export var velocity_threshold: float = 0.1
# 判断静止的角速度阈值
@export var angular_threshold: float = 0.1
# 检测落地的间隔时间
@export var check_interval: float = 0.5
# 计时器
var time_since_last_check: float = 0.0

# 金钱奖励
@export var money_reward: int = 10

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	var contact_count = state.get_contact_count()
	for i in range(contact_count):
		var collider = state.get_contact_collider(i)
		var impact_force = state.get_contact_impulse(i).length()
		if impact_force > 200:
			print("impact force = %d" % impact_force)
			if self is bullet:
				GameManager.play_sound(impact_force)
				self.sig_bullet_crash.emit()
		if impact_force >= impact_threshold * 2:
			impact_count += 2
		elif impact_force >= impact_threshold:
			impact_count += 1
		if impact_count >= required_impacts:
			break_object()
	
	# 按间隔时间检测落地状态
	if (not is_onground):
		time_since_last_check += state.step
		if time_since_last_check >= check_interval:
			time_since_last_check = 0.0
			if state.linear_velocity.length() < velocity_threshold and abs(state.angular_velocity) < angular_threshold:
				is_onground = true
				if (self is not bullet):
					#print("Destructable 非bullet 已静止！")
					self.gravity_scale = 1
				#print("Destructable 已静止！")
				# 可以在这里触发静止状态的逻辑

func break_object() -> void:
	#添加金钱
	if self == null:
		return
	if is_locked == false:
		#锁定，否则可能多重释放
		is_locked = true
		# 显示绿色文字提示
		show_money_popup(money_reward)
		self.queue_free() 
	
var s_popup = preload("res://scripts/scenes/popup.tscn")

# 显示绿色文字提示
func show_money_popup(amount: int) -> void:
	var popup = s_popup.instantiate()
	GameManager.add_cash(money_reward)
	get_tree().root.add_child(popup)
	#print(popup)
	popup.set_text("+$%d" % amount)
	popup.global_position = self.global_position
	popup.start()
	
