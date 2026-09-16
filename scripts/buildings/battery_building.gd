class_name BatteryBuilding
extends BuildingBase

const SIZE := Vector2(40, 70)

@onready
var power_progress_bar: ProgressBar = %PowerProgressBar

var _area := Rect2(-SIZE / 2.0, SIZE)

func _process(_delta: float) -> void:
    var component := find_component(BuildingComponent.Kind.POWER_STORAGE) as PowerStorageComponent
    if component != null:
        power_progress_bar.max_value = component.power_capacity
        power_progress_bar.value = component.power_available

func contains_local_point(point: Vector2) -> bool:
    return _area.grow(4).has_point(point)
