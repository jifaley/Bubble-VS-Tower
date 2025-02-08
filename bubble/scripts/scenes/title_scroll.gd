extends Node2D

@onready var scrolling_text: Label = $CanvasLayer/Control/ScrollingText
@onready var help_button: TextureButton = $CanvasLayer/Control/helpButton

var scroll_speed = 80
var mytext = "    在遥远的泡泡王国，邪恶的高塔突然崛起，释放黑暗力量，企图触碰高空的神殿，引发灾难。勇敢的泡泡战士们为守护神殿，汇聚力量，挑战高塔的层层关卡。传说只有最强的泡泡能击碎高塔核心，阻止其触碰神殿，恢复王国的光明。指挥官，我们的部队就交给你了！"
var isActive := true
var target_stop_y := 20  # 距离屏幕顶部的停止位置

signal sig_scrolltitle_over

func _ready():
	# 初始化设置
	help_button.visible = false
	scrolling_text.text = mytext
	scrolling_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scrolling_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	# 设置初始宽度（留出10%边距）
	scrolling_text.size.x = get_viewport_rect().size.x * 0.8
	
	# 等待两帧确保文本布局完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 计算初始位置
	var text_height = _get_real_text_height()
	scrolling_text.position = Vector2(
		(get_viewport_rect().size.x - scrolling_text.size.x) / 2,  # 水平居中
		0 * get_viewport_rect().size.y / 2 + text_height  # 初始位置在屏幕底部外
	)

func _process(delta):
	if not isActive:
		return
	
	# 滚动文本
	scrolling_text.position.y -= scroll_speed * delta
	
	# 计算停止条件
	var current_top = scrolling_text.position.y
	if current_top <= target_stop_y:
		scrolling_text.position.y = target_stop_y  # 对齐到精确位置
		isActive = false
		
		await get_tree().create_timer(1).timeout
		scrolling_text.visible = false
		help_button.visible = true
		help_button.pressed.connect(press_start)
		set_process(false)  # 停止process循环

func _get_real_text_height() -> float:
	# 精确计算文本高度
	var font = scrolling_text.get_theme_font("font")
	var font_size = scrolling_text.get_theme_font_size("font_size")
	return font.get_multiline_string_size(
		scrolling_text.text,
		HORIZONTAL_ALIGNMENT_FILL,
		scrolling_text.size.x,
		font_size
	).y

func press_start() -> void:
	sig_scrolltitle_over.emit()
