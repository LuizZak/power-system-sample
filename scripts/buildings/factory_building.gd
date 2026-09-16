class_name FactoryBuilding
extends BuildingBase

const SIZE := Vector2(59, 49)

@onready
var power_progress_bar: ProgressBar = %PowerProgressBar
@onready
var out_of_power: Node2D = %OutOfPower

var _area := Rect2(-SIZE / 2.0, SIZE)

func _process(delta: float) -> void:
    var component := find_component(BuildingComponent.Kind.POWER_CONSUMER) as PowerConsumerComponent
    if component != null:
        out_of_power.visible = not component.try_consume(1.0 * delta)

        power_progress_bar.max_value = component.power_capacity
        power_progress_bar.value = component.power_available

func contains_local_point(point: Vector2):
    return _area.has_point(point)
