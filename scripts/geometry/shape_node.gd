## Draws a shape on screen with the provided color.
@tool
class_name ShapeNode
extends Node2D

@export
var shape: Shape2D:
    set(value):
        shape = value
        queue_redraw()

@export
var color: Color:
    set(value):
        color = value
        queue_redraw()

func _draw() -> void:
    if shape != null:
        shape.draw(get_canvas_item(), color)
