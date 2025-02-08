extends Node2D

@onready var label: Label = $popuplabel

# 设置文字内容
func set_text(text: String) -> void:
	label.text = text
	label.modulate = Color(0,0,0,1)
	
func start() -> void:
	# 文字上浮效果
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -50), 1.0)
	# 文字淡出效果
	tween.tween_property(label, "modulate", Color(0, 0, 0, 0), 1.0)
	
	# 动画完成后销毁
	tween.finished.connect(self.queue_free)
	
	

func _ready() -> void:
	print("popup ready")
	print(label)
	
	
