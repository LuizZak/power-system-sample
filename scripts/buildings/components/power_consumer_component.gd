## A component that indicates a building consumes power.
##
## Also stores a small amount of buffer power to be consumed.
class_name PowerConsumerComponent
extends BuildingComponent

## Maximum power that can be consumed by the building, per units of power, per
## second.
@export
var max_power_consumed: float

## Power available to be consumed.
@export
var power_available: float

## Total power capacity that can be stored here.
@export
var power_capacity: float

func get_kind() -> Kind:
    return Kind.POWER_CONSUMER

## Returns [code]true[/code] if the available power meets or exceeds the power
## capacity of this component.
func is_full() -> bool:
    return power_available >= power_capacity

## Returns [code]true[/code] if this power consumer component has the given amount
## of power available to be consumed.
func can_consume(power: float) -> bool:
    return power_available >= power

## Attempts to consume a given amount of power, returning whether it was properly
## consumed.
func try_consume(power: float) -> bool:
    if not can_consume(power):
        return false

    power_available = move_toward(power_available, 0.0, power)

    return true

## Attempts to store a given amount of power in this component, returning the
## amount that was successfully stored.
func store(power: float) -> float:
    var power_before := power_available

    power_available = move_toward(power_available, power_capacity, power)

    return power_available - power_before
