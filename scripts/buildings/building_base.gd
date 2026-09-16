@abstract
class_name BuildingBase
extends Node2D

@onready
var components: Node = %Components

var is_enabled: bool = true

func has_component(kind: BuildingComponent.Kind) -> bool:
    return find_component(kind) != null

func find_component(kind: BuildingComponent.Kind) -> BuildingComponent:
    for component in components.get_children():
        if component is BuildingComponent and component.get_kind() == kind:
            return component

    return null

## Returns [code]true[/code] if this building's visual area contains a given
## point.
func contains_point(point: Vector2) -> bool:
    return contains_local_point(to_local(point))

## Returns [code]true[/code] if this building's visual area contains a given
## local-space point.
@abstract
func contains_local_point(point: Vector2)
