class_name GeneratorBuilding
extends BuildingBase

const FAN_ROTATE_SPEED := deg_to_rad(360.0)

@onready
var fan: Node2D = %Fan

func contains_local_point(point: Vector2) -> bool:
    return point.length() <= 38

func _process(delta: float) -> void:
    fan.rotate(FAN_ROTATE_SPEED * delta)
