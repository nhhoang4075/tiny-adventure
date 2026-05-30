class_name ResourceDef
extends Resource

## Định nghĩa data-driven cho một loại tài nguyên có thể respawn (cây, đá, quặng...).
## Tạo file .tres trong res://resources/spawnable/ và chỉnh trong Inspector.

## ID duy nhất, vd "oak_small", "rock", "iron_ore".
@export var id: StringName

## Scene được instantiate khi spawn.
@export var scene: PackedScene

## Số lượng tối đa loại này tồn tại trên map (cap auto top-up).
@export var max_count: int = 20

## Mỗi lượt top-up (mỗi ngày) sinh ngẫu nhiên trong khoảng này, không vượt max_count.
@export var per_round_min: int = 1
@export var per_round_max: int = 3

## Khoảng cách tối thiểu (pixel) tới tài nguyên/đối tượng khác khi spawn.
@export var min_spacing: float = 24.0
