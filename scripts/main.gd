class_name Main
extends Node2D

enum BuildingType {
    GENERATOR,
    BATTERY,
    FACTORY,
}

@onready
var power_system: PowerSystem = $PowerSystem
@onready
var buildings_container: Node2D = $BuildingsContainer

var building_graph := BuildingGraph.new()

var _mouse_tool: MouseToolBase

func _ready() -> void:
    power_system.assign_building_graph(building_graph)
    _change_mouse_tool(NullMouseTool.new(self))
    building_graph.on_graph_modified.connect(_on_building_graph_modified)

func _draw() -> void:
    _mouse_tool.draw(self)

    _draw_connections()

func _draw_connections() -> void:
    for edge in building_graph.all_edges():
        edge.draw(self)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed:
            _mouse_tool.mouse_down(event)
        else:
            _mouse_tool.mouse_up(event)
    if event is InputEventMouseMotion:
        _mouse_tool.mouse_move(event)
    if event is InputEventKey and event.pressed:
        _handle_key(event)

func _handle_key(event: InputEventKey) -> void:
    match event.keycode:
        KEY_G:
            _change_mouse_tool(BuildMouseTool.new(self, BuildingType.GENERATOR))
        KEY_B:
            _change_mouse_tool(BuildMouseTool.new(self, BuildingType.BATTERY))
        KEY_F:
            _change_mouse_tool(BuildMouseTool.new(self, BuildingType.FACTORY))
        KEY_C:
            _change_mouse_tool(ConnectMouseTool.new(self))
        KEY_X:
            _change_mouse_tool(DestroyMouseTool.new(self))

func add_building(building: BuildingBase, pos: Vector2) -> void:
    buildings_container.add_child(building)
    building_graph.add_building(building)
    building.position = pos

func remove_building(building: BuildingBase) -> void:
    building_graph.remove_building(building)
    building.queue_free()

func _change_mouse_tool(new_tool: MouseToolBase) -> void:
    if _mouse_tool != null:
        _mouse_tool.on_disable()

    _mouse_tool = new_tool

    if _mouse_tool != null:
        _mouse_tool.on_enable()

func _on_building_graph_modified() -> void:
    queue_redraw()

#region Mouse Tools

## Base class for tools that modify the scene by interacting with the mouse.
class MouseToolBase:
    var _owner: WeakRef

    func _init(owner: Main) -> void:
        _owner = weakref(owner)

    ## Gets the node that contains this mouse tool.
    func get_main() -> Main:
        return _owner.get_ref()

    func queue_redraw() -> void:
        get_main().queue_redraw()

    func building_graph() -> BuildingGraph:
        return get_main().building_graph

    func building_under(point: Vector2) -> BuildingBase:
        for building in building_graph().buildings():
            if building.contains_point(point):
                return building

        return null

    func on_enable() -> void:
        pass

    func on_disable() -> void:
        queue_redraw()

    @warning_ignore("unused_parameter")
    func draw(node: Node2D) -> void:
        pass

    @warning_ignore("unused_parameter")
    func mouse_down(event: InputEventMouseButton) -> void:
        pass

    @warning_ignore("unused_parameter")
    func mouse_move(event: InputEventMouseMotion) -> void:
        pass

    @warning_ignore("unused_parameter")
    func mouse_up(event: InputEventMouseButton) -> void:
        pass

## A mouse tool that does nothing.
class NullMouseTool extends MouseToolBase:
    pass

## A mouse tool that creates buildings on click.
class BuildMouseTool extends MouseToolBase:
    var _last_point: Vector2
    var _building_type: BuildingType

    func _init(owner: Main, building_type: BuildingType) -> void:
        super(owner)

        _building_type = building_type

    func on_enable() -> void:
        _last_point = get_main().get_local_mouse_position()

    func draw(node) -> void:
        var can_build := building_under(_last_point) == null

        var color := Color.WHITE
        if not can_build:
            color = Color.INDIAN_RED

        match _building_type:
            BuildingType.GENERATOR:
                node.draw_circle(_last_point, 32, color, true, -1, true)

            BuildingType.BATTERY:
                var rect := Rect2(_last_point - BatteryBuilding.SIZE / 2.0, BatteryBuilding.SIZE)
                node.draw_rect(rect, color, true, -1, true)

            BuildingType.FACTORY:
                var rect := Rect2(_last_point - FactoryBuilding.SIZE / 2.0, FactoryBuilding.SIZE)
                node.draw_rect(rect, color, true, -1, true)

    func mouse_move(event) -> void:
        _last_point = event.position

        queue_redraw()

    func mouse_down(event: InputEventMouseButton) -> void:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return

        _last_point = event.position

        var can_build := building_under(_last_point) == null

        if not can_build:
            return

        match _building_type:
            BuildingType.GENERATOR:
                var node := preload("res://nodes/buildings/generator_building.tscn").instantiate() as GeneratorBuilding
                get_main().add_building(node, _last_point)

            BuildingType.BATTERY:
                var node := preload("res://nodes/buildings/battery_building.tscn").instantiate() as BatteryBuilding
                get_main().add_building(node, _last_point)

            BuildingType.FACTORY:
                var node := preload("res://nodes/buildings/factory_building.tscn").instantiate() as FactoryBuilding
                get_main().add_building(node, _last_point)

## A mouse tool for connecting buildings together.
class ConnectMouseTool extends MouseToolBase:
    var _mouse_down: BuildingBase
    var _mouse_move: BuildingBase
    var _last_point: Vector2

    func draw(node) -> void:
        if _mouse_down == null:
            return

        var end_point := _last_point
        if _mouse_move != null:
            end_point = _mouse_move.position

        node.draw_line(_mouse_down.position, end_point, Color.CYAN, 2.0, true)

    func mouse_down(event: InputEventMouseButton) -> void:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return

        _mouse_down = building_under(event.position)

    func mouse_move(event) -> void:
        _last_point = event.position
        _mouse_move = building_under(event.position)

        queue_redraw()

    func mouse_up(event) -> void:
        if _mouse_down == null:
            return

        var start := _mouse_down
        var end := building_under(event.position)

        if end != null:
            building_graph().connect_buildings(start, end)

        _mouse_down = null
        _mouse_move = null

        queue_redraw()

## A mouse tool for destroying buildings that have been placed down.
class DestroyMouseTool extends MouseToolBase:
    func mouse_down(event: InputEventMouseButton) -> void:
        var building := building_under(event.position)
        if building != null:
            get_main().remove_building(building)

#endregion
