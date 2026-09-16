## An undirected graph data type.
class_name UndirectedGraph

var nodes: Dictionary[int, UndirectedGraphNode] = {}
var edges: Array[UndirectedGraphEdge] = []

## Next valid ID to generate nodes
var _next_id: int = 0

func _init() -> void:
    pass

## Returns whether this graph has no nodes contained within.
func is_empty() -> bool:
    return nodes.is_empty()

## Clears the graph of all nodes and edges.
func clear() -> void:
    nodes = {}
    edges = []

## Creates a new node, returning the identifier for the newly created node.
func create_node(value: Variant = null) -> int:
    var id = _next_id
    _next_id += 1

    var node := UndirectedGraphNode.new(id, value)
    nodes[id] = node

    return id

## Removes a node with a given identifier from this graph.
func remove_node(id: int) -> void:
    if not has_node(id):
        return

    nodes.erase(id)

    for i in range(edges.size() - 1, -1, -1):
        if edges[i].references(id):
            edges.remove_at(i)

## Returns the node associated with a given identifier.
func find_node(id: int) -> UndirectedGraphNode:
    if nodes.has(id):
        return nodes[id]

    return null

## Returns `true` if a node with a given identifier exists in this graph.
func has_node(id: int) -> bool:
    return find_node(id) != null

## Creates a new edge between the two specified nodes.
## If an edge already exists between the nodes, nothing is done.
func create_edge(node1: int, node2: int, value: Variant = null) -> void:
    if has_edge(node1, node2):
        return

    var edge := UndirectedGraphEdge.new(node1, node2)
    edge.value = value
    edges.append(edge)

## Removes any and all edges that connect the two given nodes directly.
func remove_edge(node1: int, node2: int) -> void:
    for i in range(edges.size() - 1, -1, -1):
        if edges[i].connects(node1, node2):
            edges.remove_at(i)

## Returns `true` if an edge connecting the two given nodes exists in this graph.
func has_edge(node1: int, node2: int) -> bool:
    return find_edge(node1, node2) != null

## Returns the edge connecting the two given nodes. Returns `null` if no such edge
## exists.
func find_edge(node1: int, node2: int) -> UndirectedGraphEdge:
    for edge in edges:
        if edge.connects(node1, node2):
            return edge

    return null

## Returns an array of edges associated with the given node identifier.
func edges_for(node_id: int) -> Array[UndirectedGraphEdge]:
    var result: Array[UndirectedGraphEdge] = []

    for edge in edges:
        if edge.references(node_id):
            result.append(edge)

    return result

## Returns an array of all nodes connected to a given node identifier.
func nodes_from(node_id: int) -> PackedInt64Array:
    var result: PackedInt64Array = []

    for edge in edges:
        if edge.node1 == node_id:
            result.append(edge.node2)
        elif edge.node2 == node_id:
            result.append(edge.node1)

    return result

## Returns an array of all nodes connected to a given node identifier.
func _nodes_from(node_id: int) -> Array[UndirectedGraphNode]:
    var result: Array[UndirectedGraphNode] = []

    for edge in edges:
        if edge.node1 == node_id:
            result.append(find_node(edge.node2))
        elif edge.node2 == node_id:
            result.append(find_node(edge.node1))

    return result

## Performs a breadth-first search through this graph, looking for the shortest
## path between [code]start[/code] and [code]end[/code], while filtering potential
## visitable node ids with [code]filter_callback[/code].
##
## Returns an empty array, if no path was found.
func find_shortest_path(start: int, end: int, filter_callback: Callable = func(_id: int): return true) -> Array[UndirectedGraphNode]:
    if not has_node(start) or not has_node(end):
        return []

    var start_node := find_node(start)

    var queue: Array[_VisitEntry] = [_VisitEntry.new().appending(start_node)]
    var visited: PackedInt64Array = []

    while queue.size() > 0:
        var current: _VisitEntry = queue.pop_front()

        if current.end.id == end:
            return current.nodes

        if visited.has(current.end.id):
            continue
        visited.append(current.end.id)

        var callback_result = filter_callback.call(current.end.id)
        if callback_result == false:
            continue

        for next in _nodes_from(current.end.id):
            queue.append(current.appending(next))

    return []

## Performs a breadth-first search, starting from a given node-id, visiting each
## connected node until `visit_callback` returns `true` when passed that node's
## id.
##
## The search skips double-visits and is guaranteed to always finish.
func breadth_first_search(start: int, visit_callback: Callable) -> UndirectedGraphNode:
    if not has_node(start):
        return null

    var queue: Array[UndirectedGraphNode] = [find_node(start)]
    var visited: PackedInt64Array = []

    while queue.size() > 0:
        var current: UndirectedGraphNode = queue.pop_front()
        if visited.has(current.id):
            continue

        visited.append(current.id)

        var result = visit_callback.call(current.id)
        if result == true:
            return current

        queue.append_array(_nodes_from(current.id))

    return null

## Performs a depth-first search, starting from a given node-id, visiting each
## connected node until `visit_callback` returns `true` when passed that node's
## id.
##
## The search skips double-visits and is guaranteed to always finish.
func depth_first_search(start: int, visit_callback: Callable) -> UndirectedGraphNode:
    if not has_node(start):
        return null

    var stack: Array[UndirectedGraphNode] = [find_node(start)]
    var visited: PackedInt64Array = []

    while stack.size() > 0:
        var current: UndirectedGraphNode = stack.pop_back()
        if visited.has(current.id):
            continue

        visited.append(current.id)

        var result = visit_callback.call(current.id)
        if result == true:
            return current

        stack.append_array(_nodes_from(current.id))

    return null

## Returns an array of components on this graph.
##
## Components are subgraphs of inter-connected nodes that are not part of any
## larger subgraphs.
func components() -> Array[PackedInt64Array]:
    var result: Array[PackedInt64Array] = []
    var remaining := nodes.keys().duplicate()

    while not remaining.is_empty():
        var next: int = remaining[0]
        var current: PackedInt64Array = []

        breadth_first_search(
            next,
            func(n: int):
                current.append(n)
                remaining.erase(n)
                return false
        )

        result.append(current)

    return result

class UndirectedGraphNode:
    var id: int
    var value: Variant

    @warning_ignore("shadowed_variable")
    func _init(id: int, value: Variant) -> void:
        self.id = id
        self.value = value

class UndirectedGraphEdge:
    var node1: int
    var node2: int
    var value: Variant

    @warning_ignore("shadowed_variable")
    func _init(node1: int, node2: int) -> void:
        self.node1 = node1
        self.node2 = node2

    func is_equivalent_to_edge(other: UndirectedGraphEdge) -> bool:
        return connects(other.node1, other.node2)

    func connects(n1: int, n2: int) -> bool:
        return (
            (node1 == n1 and node2 == n2) or
            (node1 == n2 and node2 == n1)
        )

    func references(node_id: int) -> int:
        return node1 == node_id or node2 == node_id

class _VisitEntry:
    var nodes: Array[UndirectedGraphNode] = []
    var end: UndirectedGraphNode:
        get:
            if nodes.is_empty():
                return null
            return nodes[-1]

    func append(node: UndirectedGraphNode) -> void:
        nodes.append(node)

    func appending(node: UndirectedGraphNode) -> _VisitEntry:
        var n := nodes.duplicate()
        var new_visit := _VisitEntry.new()
        new_visit.nodes = n
        new_visit.append(node)
        return new_visit
