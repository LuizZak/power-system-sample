## A component that indicates that a building can store extra leftover energy.
class_name PowerStorageComponent
extends BuildingComponent

## Power available to be consumed.
@export
var power_available: float

## Total power capacity that can be stored here.
@export
var power_capacity: float

func get_kind() -> Kind:
    return Kind.POWER_STORAGE

## Drains all available power out of this component, returning the amount of
## power drained.
func drain_all_power() -> float:
    var power := power_available
    power_available = 0.0
    return power

## Returns [code]true[/code] if the available power meets or exceeds the power
## capacity of this component.
func is_full() -> bool:
    return power_available >= power_capacity

## Attempts to store a given amount of power in this component, returning the
## amount that was successfully stored.
func store(power: float) -> float:
    var power_before := power_available

    power_available = move_toward(power_available, power_capacity, power)

    return power_available - power_before
