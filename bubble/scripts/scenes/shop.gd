extends Node2D

@onready var cash_label_shop: Label = %cash_label_shop
@onready var next_level_button: TextureButton = %NextLevelButton
@onready var shopguide_label: Label = %shopguide_label
@onready var shopbgm_player: AudioStreamPlayer = $shopbgmPlayer
@onready var shop_sfx_player: AudioStreamPlayer = $shopSFXPlayer


@onready var level_label_1: Label = $CanvasLayer/Control/VBoxContainer/Middle/BoardArea/Upgrade1/levelLabel1
@onready var level_label_2: Label = $CanvasLayer/Control/VBoxContainer/Middle/BoardArea2/Upgrade1/levelLabel2
@onready var level_label_3: Label = $CanvasLayer/Control/VBoxContainer/Middle/BoardArea3/Upgrade1/levelLabel3
@onready var level_label_4: Label = $CanvasLayer/Control/VBoxContainer/Middle/BoardArea4/Upgrade1/levelLabel4



@onready var texture_button_1: TextureButton = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea1/TextureButton1
@onready var texture_button_2: TextureButton = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea2/TextureButton2
@onready var texture_button_3: TextureButton = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea3/TextureButton3
@onready var texture_button_4: TextureButton = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea4/TextureButton4

@onready var price_label_1: Label = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea1/TextureButton1/price_label1
@onready var price_label_2: Label = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea2/TextureButton2/price_label2
@onready var price_label_3: Label = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea3/TextureButton3/price_label3
@onready var price_label_4: Label = $CanvasLayer/Control/VBoxContainer/Down/ButtonArea4/TextureButton4/price_label4

var labelArr: Array[Label]
var buttonArr: Array[Button]

signal sig_next_level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	labelArr.push_back(price_label_1)
	labelArr.push_back(price_label_2)
	labelArr.push_back(price_label_3)
	labelArr.push_back(price_label_4)
	for label in labelArr:
		label.visible = false
	shopguide_label.visible = false
	shopbgm_player.play()
	
	update_shop()
	connect_buttons()
	
func update_shop() -> void:
	var skill_level_1:int = GameManager.slingshot_level
	var skill_level_2:int = GameManager.reloader_level
	var skill_level_3:int = GameManager.bullet_level
	var skill_level_4:int = GameManager.economy_level
	level_label_1.text = "等级 %d " % skill_level_1
	level_label_2.text = "等级 %d " % skill_level_2
	level_label_3.text = "等级 %d " % skill_level_3
	level_label_4.text = "等级 %d " % skill_level_4
	update_cash_shop()
	
func connect_buttons() -> void:
	next_level_button.pressed.connect(
		func() -> void:
			sig_next_level.emit()
	)
	
	texture_button_1.mouse_entered.connect(
		func() -> void:
			var level: int = GameManager.slingshot_level
			if (level < GameManager.MAX_SKILL_LEVEL):
				var price: int = GameManager.get_update_cost(level + 1)
				price_label_1.text = "$%d" % price
			else:
				price_label_1.text = "MAX LEVEL"
			price_label_1.visible = true
			shopguide_label.text = "发射装置：升级后增加弹弓伸长长度"
			shopguide_label.visible = true
	)
	texture_button_1.mouse_exited.connect(
		func() -> void:
			price_label_1.visible = false
			shopguide_label.visible = false
	)
	texture_button_2.mouse_entered.connect(
		func() -> void:
			var level: int = GameManager.reloader_level
			if (level < GameManager.MAX_SKILL_LEVEL):
				var price: int = GameManager.get_update_cost(level + 1)
				price_label_2.text = "$%d" % price
			else:
				price_label_2.text = "MAX LEVEL"
			price_label_2.visible = true
			shopguide_label.text = "装填装置：升级后增加子弹数量与装弹速度"
			shopguide_label.visible = true
	)
	texture_button_2.mouse_exited.connect(
		func() -> void:
			price_label_2.visible = false
			shopguide_label.visible = false
	)
	texture_button_3.mouse_entered.connect(
		func() -> void:
			var level: int = GameManager.bullet_level
			if (level < GameManager.MAX_SKILL_LEVEL):
				var price: int = GameManager.get_update_cost(level + 1)
				price_label_3.text = "$%d" % price
			else:
				price_label_3.text = "MAX LEVEL"
			price_label_3.visible = true
			shopguide_label.text = "子弹强化：升级后增加子弹重量与抗冲击次数"
			shopguide_label.visible = true
	)
	texture_button_3.mouse_exited.connect(
		func() -> void:
			price_label_3.visible = false
			shopguide_label.visible = false
	)
	texture_button_4.mouse_entered.connect(
		func() -> void:
			var level: int = GameManager.economy_level
			if (level < GameManager.MAX_SKILL_LEVEL):
				var price: int = GameManager.get_update_cost(level + 1)
				price_label_4.text = "$%d" % price
			else:
				price_label_4.text = "MAX LEVEL"
			price_label_4.visible = true
			shopguide_label.text = "资金装置：升级后增加摧毁物品获得资金"
			shopguide_label.visible = true
	)
	texture_button_4.mouse_exited.connect(
		func() -> void:
			price_label_4.visible = false
			shopguide_label.visible = false
	)
	
	texture_button_1.pressed.connect(
		func() -> void:
			var skill_level: int = GameManager.slingshot_level
			if (skill_level == GameManager.MAX_SKILL_LEVEL):
				return
			var cost: int = GameManager.get_update_cost(skill_level + 1)
			if (cost <= GameManager.get_cash()):
				GameManager.spend_cash(cost)
				GameManager.level_up_slingshot()
				update_shop()
				shop_sfx_player.play()
				texture_button_1.mouse_entered.emit()
	)
	texture_button_2.pressed.connect(
		func() -> void:
			var skill_level: int = GameManager.reloader_level
			if (skill_level == GameManager.MAX_SKILL_LEVEL):
				return
			var cost: int = GameManager.get_update_cost(skill_level + 1)
			if (cost <= GameManager.get_cash()):
				GameManager.spend_cash(cost)
				GameManager.level_up_reloader()
				update_shop()
				shop_sfx_player.play()
				texture_button_2.mouse_entered.emit()
	)
	texture_button_3.pressed.connect(
		func() -> void:
			var skill_level: int = GameManager.bullet_level
			if (skill_level == GameManager.MAX_SKILL_LEVEL):
				return
			var cost: int = GameManager.get_update_cost(skill_level + 1)
			if (cost <= GameManager.get_cash()):
				GameManager.spend_cash(cost)
				GameManager.level_up_bullet()
				update_shop()
				shop_sfx_player.play()
				texture_button_3.mouse_entered.emit()
	)
	texture_button_4.pressed.connect(
		func() -> void:
			var skill_level: int = GameManager.economy_level
			if (skill_level == GameManager.MAX_SKILL_LEVEL):
				return
			var cost: int = GameManager.get_update_cost(skill_level + 1)
			if (cost <= GameManager.get_cash()):
				GameManager.spend_cash(cost)
				GameManager.level_up_economy()
				update_shop()
				shop_sfx_player.play()
				texture_button_4.mouse_entered.emit()
	)
	
func disconnect_buttons() -> void:
	pass

	

func update_cash_shop() -> void:
	var current_cash = GameManager.get_cash()
	cash_label_shop.text = ("Cash: $%d" % current_cash)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
