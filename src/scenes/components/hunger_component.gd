class_name HungerComponent
extends Node

## Đói/no của vật nuôi. Phải cho ăn ĐÚNG loại thức ăn (feed_item_id) thì tới kỳ
## mới ra sản phẩm (ProductionComponent kiểm tra qua consume_fed()).
## Cho ăn: đứng cạnh chuồng + nhấn "interact" → chuồng gọi feed() cho mọi con.

@export var feed_item_id: StringName
## Vị trí bong bóng đói phía trên con vật (chỉnh cho khớp từng loài nếu cần).
@export var bubble_offset: Vector2 = Vector2(0, -24)

var fed: bool = false

var _feed_bubble: IndicatorBubble
var _icon_set: bool = false

func _ready() -> void:
	# Bong bóng đói gắn trên CHÍNH con vật này (mỗi con 1 cái, vì có thể nhiều
	# loài khác nhau cùng chuồng cần thức ăn khác nhau).
	var animal := get_parent()
	if animal is Node2D:
		_feed_bubble = IndicatorBubble.new()
		_feed_bubble.position = bubble_offset
		_feed_bubble.scale = Vector2(0.7, 0.7)
		_feed_bubble.z_index = 50
		_feed_bubble.visible = false
		animal.add_child.call_deferred(_feed_bubble)

func _process(_delta: float) -> void:
	if _feed_bubble == null or not _feed_bubble.is_inside_tree():
		return
	if not _icon_set and feed_item_id != StringName(""):
		var item: ItemDef = ItemRegistry.get_item(feed_item_id)
		if item != null:
			_feed_bubble.set_icon(item.icon)
			_icon_set = true
	_feed_bubble.visible = (not fed) and _icon_set

## Gọi từ AnimalPlacer khi thả theo breed (AnimalDef.feed_item_id).
func configure(def) -> void:
	if def != null and def.feed_item_id != StringName(""):
		feed_item_id = def.feed_item_id

## ProductionComponent gọi khi tới kỳ sản xuất: true nếu đã được cho ăn
## (đồng thời reset → cần cho ăn lại cho kỳ sau).
func consume_fed() -> bool:
	var was := fed
	fed = false
	return was

## Cho ăn 1 con: chỉ được khi ĐANG CHỌN đúng loại thức ăn trên hotbar & còn trong
## túi & chưa no. Trả về true nếu đã cho ăn.
func feed() -> bool:
	if fed or feed_item_id == StringName(""):
		return false
	# Phải đang chọn đúng thức ăn của con này (bubble đói hiện icon cần chọn).
	if ToolManager.selected_item_id != String(feed_item_id):
		return false
	if InventoryManager.get_count(String(feed_item_id)) <= 0:
		return false
	InventoryManager.remove_collectable(String(feed_item_id))
	fed = true
	_play_feedback(get_parent() as Node2D)
	return true

func _play_feedback(animal: Node2D) -> void:
	if animal == null:
		return
	var sprite := animal.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite == null:
		return
	var base: Vector2 = sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base * 1.25, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", base, 0.12).set_trans(Tween.TRANS_QUAD)
