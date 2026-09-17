@abstract
class_name BuildingBase
extends Node2D

@onready
var components: Node = %Components

var is_enabled: bool = true

func has_component(kind: BuildingComponent.Kind) -> bool:
    return find_component(kind) != null

func find_component(kind: BuildingComponent.Kind) -> BuildingComponent:
    match kind:
        BuildingComponent.Kind.POWER_GENERATOR:
            return get_node_or_null(^"%Components/PowerGeneratorComponent")
        BuildingComponent.Kind.POWER_CONSUMER:
            return get_node_or_null(^"%Components/PowerConsumerComponent")
        BuildingComponent.Kind.POWER_STORAGE:
            return get_node_or_null(^"%Components/PowerStorageComponent")

    return null

## Returns [code]true[/code] if this building's visual area contains a given
## point.
func contains_point(point: Vector2) -> bool:
    return contains_local_point(to_local(point))

## Returns [code]true[/code] if this building's visual area contains a given
## local-space point.
@abstract
func contains_local_point(point: Vector2)
