class_name LogicComponent
extends Node2D

# --- Properties ---
## Internal state storage
# Each Input Dictionary: {"identifier": int, "source_node_path": NodePath, "source_pin_id": int, "current_state": bool, "label": String, "area_node": Area2D}
@export var inputs: Array[Dictionary]
# Each Output Dictionary: {"identifier": int, "current_state": bool, "next_state": bool, "label": String, "area_node": Area2D}
@export var outputs: Array[Dictionary]

## Visuals and Interaction
@export var component_label: String = "COMPONENT"
@export var component_color: Color = Color.LIGHT_GRAY
@export var pin_radius: float = 8.0
@export var pin_color: Color = Color.DARK_SLATE_GRAY

@export var _dragging: bool = false
@export var _drag_offset: Vector2
@export var body_area: Area2D

@export var height: float = float(max(inputs.size(), outputs.size(), 1) * 25) + 20
@export var width: float = 100.0

# --- Engine Callbacks ---
func _ready(): 
	if not Engine.is_editor_hint():
		_setup_pins()
		_setup_interactive_areas()

func _draw():
## Component Body
	var body_rect = Rect2(Vector2(-width / 2.0, -height / 2.0), Vector2(width, height))
	draw_rect(body_rect, component_color)

## Component Label
	if component_label:
		var label_size: Vector2 = ThemeDB.fallback_font.get_string_size(component_label, HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeDB.fallback_font_size)
		var label_position = Vector2(-label_size.x / 2.0, label_size.y / 2.0 - height/4)
		draw_string(ThemeDB.fallback_font, label_position, component_label, HORIZONTAL_ALIGNMENT_CENTER, width - 10, ThemeDB.fallback_font_size, Color.BLACK) # Adjust color, width constraint

## Component Inputs
	if inputs.size() > 0:
		var xpos: float = -width / 2.0
		for i in range(inputs.size()):
			var ypos: float = ((i + 1.0) / float(inputs.size() + 1.0)) * height - (height / 2.0)
			var pos = Vector2(xpos, ypos)
			var current_pin_color = pin_color
			if inputs[i].get("current_state", false) == true: current_pin_color = Color.LIME_GREEN
			draw_circle(pos, pin_radius / 2.0, current_pin_color)

## Component Outputs
	if outputs.size() > 0:
		var xpos: float = width / 2.0
		for i in range(outputs.size()):
			var ypos: float = ((i + 1.0) / float(outputs.size() + 1.0)) * height - (height / 2.0)
			var pos = Vector2(xpos, ypos)
			var current_pin_color = pin_color
			if outputs[i].get("current_state", false) == true: current_pin_color = Color.ORANGE_RED
			draw_circle(pos, pin_radius / 2.0, current_pin_color)

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse motion for dragging at a higher level if dragging is active
	if _dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - _drag_offset

# --- Core Logic Methods ---
## Calculates the gate's output(s) based on its current input states.
func _setup_pins() -> void:
	# inputs.append({"identifier": 0, "source_node_path": null, "source_pin_id": -1, "current_state": false})
	# outputs.append({"identifier": 0, "current_state": false, "next_state": false, "label": "Q"})
	pass

func _setup_interactive_areas() -> void:
	# --- Create Body Area for Dragging ---
	if is_instance_valid(body_area): body_area.queue_free()

	body_area = Area2D.new()
	body_area.name = "BodyArea"
	add_child(body_area)

	var body_shape = RectangleShape2D.new()
	body_shape.size = Vector2(width, height)
	var body_collision_shape = CollisionShape2D.new()
	body_collision_shape.shape = body_shape

	body_area.add_child(body_collision_shape)
	body_area.input_event.connect(_on_body_input_event)

	# --- Clear and Create Pin Areas ---
	for input_pin_data in inputs:
		if input_pin_data.has("area_node") and is_instance_valid(input_pin_data["area_node"]):
			input_pin_data["area_node"].queue_free()
	for output_pin_data in outputs:
		if output_pin_data.has("area_node") and is_instance_valid(output_pin_data["area_node"]):
			output_pin_data["area_node"].queue_free()

	# Create Input Pin Areas
	if inputs.size() > 0:
		var xpos: float = -width / 2.0
		for i in range(inputs.size()):
			var input_pin_data = inputs[i]
			var ypos: float = ((i + 1.0) / float(inputs.size() + 1.0)) * height - (height / 2.0)
			var pin_pos = Vector2(xpos, ypos)

			var area = Area2D.new()
			area.name = "InputArea_" + str(input_pin_data.get("identifier", i))
			add_child(area)
			area.position = pin_pos
			input_pin_data["area_node"] = area

			var shape = CircleShape2D.new()
			shape.radius = pin_radius / 2.0
			var collision_shape = CollisionShape2D.new()
			collision_shape.shape = shape
			area.add_child(collision_shape)

			area.input_event.connect(_on_pin_input_event.bind(area, "input", input_pin_data["identifier"]))

	# Create Output Pin Areas
	if outputs.size() > 0:
		var xpos: float = width / 2.0
		for i in range(outputs.size()):
			var output_pin_data = outputs[i]
			var ypos: float = ((i + 1.0) / float(outputs.size() + 1.0)) * height - (height / 2.0)
			var pin_pos = Vector2(xpos, ypos)

			var area = Area2D.new()
			area.name = "OutputArea_" + str(output_pin_data.get("identifier", i))
			add_child(area)
			area.position = pin_pos
			output_pin_data["area_node"] = area

			var shape = CircleShape2D.new()
			shape.radius = pin_radius / 2.0
			var collision_shape = CollisionShape2D.new()
			collision_shape.shape = shape
			area.add_child(collision_shape)

			area.input_event.connect(_on_pin_input_event.bind(area, "output", output_pin_data["identifier"]))

## Handles input events on the component's body area
func _on_body_input_event(viewport, event: InputEvent, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			get_viewport().set_input_as_handled() # Consume event so pins don't also process it
		else: # Mouse button released
			_dragging = false
			get_viewport().set_input_as_handled()
	# Removed mouse motion handling from here to use _unhandled_input for smoother global dragging

## Handles input events on the pin areas
func _on_pin_input_event(event: InputEvent, area_node: Area2D, pin_type: String, pin_identifier: int, viewport, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if not _dragging:
			print("Clicked on %s pin with identifier: %s (Node: %s)" % [pin_type, pin_identifier, area_node.name])
			# Add your logic here, e.g., start a connection, toggle a manual input, etc.
			get_viewport().set_input_as_handled()

## Fetches the current state from all connected source nodes for each input pin.
func update_input_states() -> void:
	if Engine.is_editor_hint(): return

	for i in range(inputs.size()):
		var input_pin = inputs[i]
		if input_pin.has("source_node_path") and input_pin["source_node_path"] != null and input_pin["source_node_path"] != NodePath(""):
			var source_node = get_node_or_null(input_pin["source_node_path"])
			if source_node is LogicComponent:
				var source_pin_id = input_pin.get("source_pin_id", -1)
				if source_pin_id != -1: input_pin["current_state"] = source_node.get_output_current_state(source_pin_id)
				else: input_pin["current_state"] = false # No valid source pin ID
			else: input_pin["current_state"] = false # No valid source node
		else: input_pin["current_state"] = false # No source connected
	queue_redraw() # Redraw to reflect new input states visually

## Calculates the next_state for all output pins based on current input states and component logic.
func _evaluate() -> void:
	if Engine.is_editor_hint(): return
	# Derived classes will implement their specific logic here and set the "next_state" of their output pins.
	pass

## Commits the calculated next_state to current_state for all output pins.
## This is typically called by a simulation manager at the end of a tick/evaluation phase.
func commit_outputs() -> void:
	if Engine.is_editor_hint(): return

	var changed_state = false
	for i in range(outputs.size()):
		var output_pin = outputs[i]
		if output_pin.get("current_state", false) != output_pin.get("next_state", false):
			output_pin["current_state"] = output_pin.get("next_state", false)
			changed_state = true
	if changed_state: queue_redraw()

# --- Helper methods ---
## Connects an input source to a specific input index.
func set_input_source(identifier: int, source_node: Node, source_node_identifier) -> void:
	if not source_node is LogicComponent: return

	for i in range(inputs.size()):
		if inputs[i]["identifier"] == identifier: 
			inputs[i]["source"] = source_node
			inputs[i]["source_node_path"] = get_path_to(source_node)
			inputs[i]["source_pin_id"] = source_node_identifier
			inputs[i]["current_state"] = false # Reset state, will be updated
			update_input_states() # Immediately try to fetch the new source's state
			return

## Retrieves the current (stable) state of a specific output pin.
func get_output_current_state(output_identifier: int) -> bool:
	for i in range(outputs.size()):
		if outputs[i]["identifier"] == output_identifier:
			return outputs[i].get("current_state", false)
	return false

## Allows directly setting an input pin's state (e.g., for top-level inputs not connected to other LogicComponents)
func set_external_input_state(input_identifier: int, state: bool) -> void:
	for i in range(inputs.size()):
		if inputs[i]["identifier"] == input_identifier:
			inputs[i]["current_state"] = state
			inputs[i]["source_node_path"] = null # Clear source if set externally
			inputs[i]["source_pin_id"] = -1
			queue_redraw()
			return
