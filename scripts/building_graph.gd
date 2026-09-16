## Represents a graph of buildings that can be inter-connected with each other
## to form networks.
class_name BuildingGraph

## Cached array of buildings for fast iterating.
var _buildings: Array[BuildingBase] = []
## A reverse-map of buildings to IDs for fast fetching.
var _building_to_id_map: Dictionary[BuildingBase, int] = {}
## A map of buildings to IDs for fast fetching.
var _id_to_buildings_map: Dictionary[int, BuildingBase] = {}
## Graph containing building connections.
var _graph: UndirectedGraph = UndirectedGraph.new()

## Signal called when the underlying graph has been modified, by e.g. adding/removing
## buildings or connections between them.
signal on_graph_modified()

## Returns whether this building graph is empty of buildings.
func is_empty() -> bool:
    return _buildings.is_empty()

## Returns the array of buildings present in this graph.
##
## Note: For performance reasons, this array is not duplicated from the internal
## implementation, and modifying it directly may result in unpredictable behavior.
func buildings() -> Array[BuildingBase]:
    return _buildings

## Adds a given building to this building graph.
func add_building(building: BuildingBase) -> void:
    if _has_building(building):
        return

    var node_id := _graph.create_node(building)
    _buildings.append(building)
    _building_to_id_map[building] = node_id
    _id_to_buildings_map[node_id] = building

    on_graph_modified.emit()

## Removes a given building from this graph.
func remove_building(building: BuildingBase) -> void:
    if not _has_building(building):
        return

    var node_id := _building_to_id_map[building]
    _buildings.erase(building)
    _graph.remove_node(node_id)
    _building_to_id_map.erase(building)
    _id_to_buildings_map.erase(node_id)

    on_graph_modified.emit()

## Connects two buildings together.
func connect_buildings(b1: BuildingBase, b2: BuildingBase) -> void:
    if not _has_building(b1) or not _has_building(b2):
        return

    var id1 := _id_for_building(b1)
    var id2 := _id_for_building(b2)

    _graph.create_edge(id1, id2)

    on_graph_modified.emit()

## Returns an array-of-arrays that contain networks of inter-connected buildings.
##
## Buildings in one array are guaranteed connected to buildings in the same
## array, but not to any other array.
##
## The return value of this function would be Array[Array[BuildingBase]] if Godot
## supported nested collection types, but is an Array of untyped Arrays instead.
func connected_buildings() -> Array[Array]:
    var result: Array[Array] = []

    var components := _graph.components()

    for component in components:
        var network: Array = []

        for node_id in component:
            network.append(_building_for_id(node_id))

        result.append(network)

    return result

func all_edges() -> Array[BuildingEdge]:
    var result: Array[BuildingEdge] = []

    for edge in _graph.edges:
        var entry := BuildingEdge.new()
        entry.b1 = _building_for_id(edge.node1)
        entry.b2 = _building_for_id(edge.node2)
        result.append(entry)

    return result

func _has_building(building: BuildingBase) -> bool:
    return _building_to_id_map.has(building)

func _building_for_id(node_id: int) -> BuildingBase:
    return _id_to_buildings_map[node_id]

func _id_for_building(building: BuildingBase) -> int:
    return _building_to_id_map[building]

class BuildingEdge:
    var b1: BuildingBase
    var b2: BuildingBase

    func draw(node: Node2D) -> void:
        var b1_local := node.to_local(b1.global_position)
        var b2_local := node.to_local(b2.global_position)

        node.draw_line(b1_local, b2_local, Color.CYAN, 3.0, true)
