## Base class for building components
@abstract
class_name BuildingComponent
extends Node

enum Kind {
    POWER_GENERATOR,
    POWER_CONSUMER,
    POWER_STORAGE,
}

@abstract
func get_kind() -> Kind
