class_name NANDComponent
extends LogicComponent

# --- Core Logic Methods ---
func _init():
	component_label = "NAND"
	component_color = Color.PALE_VIOLET_RED

func _setup_pins() -> void:
	inputs.clear()
	outputs.clear()

	inputs.append({"identifier": 0, "source_node_path": null, "source_pin_id": -1, "current_state": false, "label": "I1"})
	inputs.append({"identifier": 1, "source_node_path": null, "source_pin_id": -1, "current_state": false, "label": "I2"})
	outputs.append({"identifier": 0, "current_state": false, "next_state": false, "label": "Q"})

func _evaluate() -> void:
	# Assumes inputs[0] is Input A and inputs[1] is Input B
	var input_a_state: bool = false
	var input_b_state: bool = false

	for input_pin in inputs:
		if input_pin["identifier"] == 0: input_a_state = input_pin.get("current_state", false)
		elif input_pin["identifier"] == 1: input_b_state = input_pin.get("current_state", false)

	var result: bool = not (input_a_state and input_b_state) # NAND logic: (A AND B) NAND 1 = NOT (A AND B)
	
	# Set the next_state for the output pin
	for output_pin in outputs:
		if output_pin["identifier"] == 0:
			output_pin["next_state"] = result
			break # Assuming only one output for NAND
