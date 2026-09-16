## Performs power generation and distribution tasks on a building graph.
class_name PowerSystem
extends Node

var _building_graph: BuildingGraph
var _networks: Array[Network] = []

func assign_building_graph(building_graph: BuildingGraph) -> void:
    if _building_graph != null:
        _building_graph.on_graph_modified.disconnect(_on_building_network_graph_modified)

    _building_graph = building_graph
    regenerate_networks()

    if _building_graph != null:
        _building_graph.on_graph_modified.connect(_on_building_network_graph_modified)

## Regenerates the internal array of building networks.
func regenerate_networks() -> void:
    if _building_graph == null:
        _networks = []
    else:
        _networks = Network.networks_from_graph(_building_graph)

func _process(delta: float) -> void:
    for network in _networks:
        network.process(delta)

#region Signals

func _on_building_network_graph_modified() -> void:
    regenerate_networks()

#endregion

## Represent a network of inter-connected power buildings.
class Network:
    var buildings: Array[BuildingBase]
    var generators: Array[BuildingBase]
    var consumers: Array[BuildingBase]
    var storages: Array[BuildingBase]

    var total_generation: float = 0.0
    var total_storage: float = 0.0
    var total_potential_power_draw: float = 0.0

    @warning_ignore("shadowed_variable")
    func _init(
        buildings: Array[BuildingBase],
        generators: Array[BuildingBase],
        consumers: Array[BuildingBase],
        storages: Array[BuildingBase],
    ) -> void:
        self.buildings = buildings
        self.generators = generators
        self.consumers = consumers
        self.storages = storages

        _recompute_draw_and_generation()

    func process(delta: float) -> void:
        var available := _generate_power(delta)
        available += _consume_stored_power()
        var remaining := _distribute_power_to_consumers(available)
        _store_power(remaining)

    func _recompute_draw_and_generation() -> void:
        total_generation = 0.0
        total_storage = 0.0
        total_potential_power_draw = 0.0

        for generator in generators:
            var component := generator.find_component(BuildingComponent.Kind.POWER_GENERATOR) as PowerGeneratorComponent
            if component != null:
                total_generation += component.power_generation

        for consumer in consumers:
            var component := consumer.find_component(BuildingComponent.Kind.POWER_CONSUMER) as PowerConsumerComponent
            if component != null:
                total_storage += component.power_capacity
                total_potential_power_draw += component.max_power_consumed

        for storage in storages:
            var component := storage.find_component(BuildingComponent.Kind.POWER_STORAGE) as PowerStorageComponent
            if component != null:
                total_storage += component.power_capacity

    func _generate_power(delta: float) -> float:
        var total := 0.0

        for generator in generators:
            if not generator.is_enabled:
                continue

            var component := generator.find_component(BuildingComponent.Kind.POWER_GENERATOR) as PowerGeneratorComponent
            if component != null:
                total += component.generate_power(delta)

        return total

    func _consume_stored_power() -> float:
        var total := 0.0

        for storage in storages:
            var component := storage.find_component(BuildingComponent.Kind.POWER_STORAGE) as PowerStorageComponent
            if component != null:
                total += component.drain_all_power()

        return total

    func _distribute_power_to_consumers(power: float) -> float:
        # Make passes, attempting to distribute power until we either run out of
        # power to distribute, or available distributable sources.
        while power > 0.0:
            var available_consumers := get_available_power_consumers()
            if available_consumers.is_empty():
                break

            var per_building := power / available_consumers.size()

            var has_consumed := false

            for consumer in available_consumers:
                var component := consumer.find_component(BuildingComponent.Kind.POWER_CONSUMER) as PowerConsumerComponent

                var stored := component.store(per_building)
                if stored > 0.0:
                    power -= stored
                    has_consumed = true

            if not has_consumed:
                break

        return power

    func _store_power(power: float) -> float:
        # Make passes, attempting to store power until we either run out of power
        # to store, or storage sources.
        while power > 0.0:
            var available_storages := get_available_power_storages()
            if available_storages.is_empty():
                break

            var per_building := power / available_storages.size()

            var has_consumed := false

            for storage in available_storages:
                var component := storage.find_component(BuildingComponent.Kind.POWER_STORAGE) as PowerStorageComponent

                var stored := component.store(per_building)
                if stored > 0.0:
                    power -= stored
                    has_consumed = true

            if not has_consumed:
                break

        return power

    func get_available_power_consumers() -> Array[BuildingBase]:
        return consumers.filter(
            func (b: BuildingBase):
                return b.is_enabled and not b.find_component(BuildingComponent.Kind.POWER_CONSUMER).is_full()
        )

    func get_available_power_storages() -> Array[BuildingBase]:
        return storages.filter(
            func (b: BuildingBase):
                return b.is_enabled and not b.find_component(BuildingComponent.Kind.POWER_STORAGE).is_full()
        )

    func get_total_available_power() -> float:
        var total := 0.0

        for consumer in consumers:
            var component := consumer.find_component(BuildingComponent.Kind.POWER_CONSUMER) as PowerConsumerComponent
            total += component.power_available
        for storage in storages:
            var component := storage.find_component(BuildingComponent.Kind.POWER_STORAGE) as PowerStorageComponent
            total += component.power_available

        return total

    static func networks_from_graph(building_graph: BuildingGraph) -> Array[Network]:
        var result: Array[Network] = []

        var networks := building_graph.connected_buildings()
        for network in networks:
            result.append(from_buildings_list(network))

        return result

    static func from_buildings_list(buildings_list: Array) -> Network:
        @warning_ignore_start("shadowed_variable")
        var buildings: Array[BuildingBase] = []
        var generators: Array[BuildingBase] = []
        var consumers: Array[BuildingBase] = []
        var storages: Array[BuildingBase] = []
        @warning_ignore_restore("shadowed_variable")

        for building: BuildingBase in buildings_list:
            buildings.append(building)

            if building.has_component(BuildingComponent.Kind.POWER_GENERATOR):
                generators.append(building)
            if building.has_component(BuildingComponent.Kind.POWER_CONSUMER):
                consumers.append(building)
            if building.has_component(BuildingComponent.Kind.POWER_STORAGE):
                storages.append(building)

        return Network.new(buildings, generators, consumers, storages)
