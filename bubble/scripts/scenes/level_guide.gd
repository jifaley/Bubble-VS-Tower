extends Node2D


@onready var scrolling_text: Label = $CanvasLayer/Control/ScrollingText


var scroll_speed = 80  # 滚动速度，可以根据需要调整
var mytext = ""
var isActive : bool = true
var target_stop_y := 20 

signal sig_levelguide_over

func _ready():
	
	var current_level: int = GameManager.current_level_index
	var current_level_name: String = GameManager.level_names[current_level]
	
	mytext = ("第%d关" % (current_level + 1)) + " " + current_level_name
	
	scrolling_text.text = mytext
	scrolling_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # 设置文本换行模式
	scrolling_text.size.x = get_viewport().size.x * 0.75  # 设置宽度为视口宽度，确保文本换行  # 设置最小宽度为视口宽度，确保文本换行
	scrolling_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 等待两帧确保文本布局完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	
	# 计算初始位置
	var text_height = _get_real_text_height()
	
	target_stop_y = get_viewport_rect().size.y / 2 - text_height
	
	scrolling_text.position = Vector2(
		(get_viewport_rect().size.x - scrolling_text.size.x) / 2,  # 水平居中
		get_viewport_rect().size.y / 2 + text_height  # 初始位置在屏幕底部外
	)
	


func _process(delta):
	if not isActive:
		return
	scrolling_text.position.y -= scroll_speed * delta  # 从下往上滚动
	
	var current_top = scrolling_text.position.y
	if current_top <= target_stop_y:
		scrolling_text.position.y = target_stop_y  # 对齐到精确位置
		isActive = false
		
		await get_tree().create_timer(1).timeout
		scrolling_text.visible = false
		sig_levelguide_over.emit()
		set_process(false)  # 停止process循环
	
		
		
func _get_real_text_height() -> float:
	# 精确计算文本高度
	var font = scrolling_text.get_theme_font("font")
	var font_size = scrolling_text.get_theme_font_size("font_size")
	return font.get_multiline_string_size(
		scrolling_text.text,
		HORIZONTAL_ALIGNMENT_CENTER,
		scrolling_text.size.x,
		font_size
	).y
		
