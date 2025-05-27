class_name CompositeComponent
extends LogicComponent

# --- Composite Specific Properties ---
## Defines how this composite's EXTERNAL input pins map to INTERNAL child components' input pins.
## Array of Dictionaries: {"external_input_id": int, "internal_child_path": NodePath, "internal_child_pin_id": int}
@export var external_input_mappings: Array[Dictionary] = []
## Defines how INTERNAL child components' output pins map to this composite's EXTERNAL output pins.
## Array of Dictionaries: {"external_output_id": int, "internal_child_path": NodePath, "internal_child_pin_id": int}
@export var external_output_mappings: Array[Dictionary] = []

# --- Core Logic Methods ---
func _init():
	component_label = "COMPOSITE"
	component_color = Color.STEEL_BLUE

## Defined by the prefab creation process, based on the unconnected ("boundary") pins of the internal circuit.
## To be left empty due to pins being set up externally.
func _setup_pins() -> void: pass

## _evaluate() for a CompositeComponent involves:
## 1. Propagating its external input states to the relevant internal components (handled by update_input_states of children).
## 2. Collecting results from internal components to set its own external output next_states.
## This assumes internal child components are also LogicComponents and are part of the global evaluation tick.
func _evaluate() -> void:
	# --- 1. Propagate external inputs to internal targets (Conceptual) ---
	# The actual propagation happens when the internal children call their `update_input_states()`.
	# For this to work, the `source_node_path` for the relevant input pins of the *first layer*
	# of internal children must point to THIS composite node, and their `source_pin_id` must
	# correspond to one of this composite's *external input pins that acts as a virtual output*.
	# This is a complex part of the wiring setup for composites.
	#
	# A simpler alternative for direct control within the composite (if not relying on global eval order for sub-steps):
	# The CompositeComponent's `external_input_mappings` would be used.
	# For each mapping in `external_input_mappings`:
	#   `external_in_state = self.inputs[mapping.external_input_id]["current_state"]`
	#   `target_child = get_node(mapping.internal_child_path)`
	#   `target_child.set_specific_input_state_for_evaluation(mapping.internal_child_pin_id, external_in_state)`
	# This `set_specific_input_state_for_evaluation` would be a new method in LogicComponent
	# to directly set an input's `current_state` for the upcoming `_evaluate` call, bypassing normal source fetching.
	#
	# For now, we assume the wiring and global evaluation order handles input propagation to internal children.

	# --- 2. Collect internal outputs for external output next_states ---
	for mapping in external_output_mappings:
		var external_output_id = mapping.get("external_output_id", -1)
		var child_path = mapping.get("internal_child_path", null)
		var child_pin_id = mapping.get("internal_child_pin_id", -1)

		if external_output_id == -1 or child_path == null or child_pin_id == -1: continue

		var child_node = get_node_or_null(child_path)
		if child_node is LogicComponent:
			# IMPORTANT: We should read the child's *next_state* if the child has already been
			# evaluated in this same tick phase. If the global evaluation order ensures children
			# are fully evaluated (inputs updated, _evaluate called) before their parent composite
			# collects outputs, then reading their `next_state` is correct.
			# If not, and the child's `next_state` isn't ready, this could be problematic.
			# For simplicity, let's assume child's `next_state` is what we need.
			var internal_value: bool = false 
			# Check if child has already calculated its next_state
			# This depends on evaluation order. If children are evaluated first, their next_state is ready.
			var child_output_pin = null
			for pin_data in child_node.outputs:
				if pin_data["identifier"] == child_pin_id:
					child_output_pin = pin_data
					break
			
			if child_output_pin:
				internal_value = child_output_pin.get("next_state", child_output_pin.get("current_state", false)) # Fallback to current if next_state not set
			else:
				#printerr(name, ": Child output pin ", child_pin_id, " not found on ", child_node.name)
				pass


			# Find the composite's own external output pin to update its next_state
			var found_composite_output = false
			for i in range(outputs.size()):
				if outputs[i]["identifier"] == external_output_id:
					outputs[i]["next_state"] = internal_value
					found_composite_output = true
					break
			#if not found_composite_output:
				#printerr(name, ": Own external output pin ", external_output_id, " not found for mapping.")
		elif child_node != null:
			#printerr(name, ": Mapped internal child ", child_path, " is not a LogicComponent.")
			pass
		#else:
			#printerr(name, ": Mapped internal child not found at path: ", child_path)
			pass
	
	# print_debug(name, ": Composite evaluated. Outputs next_state set based on internal mappings.")


## Helper: To be called by the prefab saver script to define the structure.
func configure_composite(
		external_inputs_config: Array[Dictionary], # [{"identifier": int, "label": String (opt)}]
		external_outputs_config: Array[Dictionary],# [{"identifier": int, "label": String (opt)}]
		new_input_mappings: Array[Dictionary],
		new_output_mappings: Array[Dictionary]
	):
	
	inputs.clear()
	for pin_conf in external_inputs_config:
		inputs.append({
			"identifier": pin_conf["identifier"],
			"source_node_path": null, # External inputs of a composite are typically set by higher-level connections or direct state setting
			"source_pin_id": -1,
			"current_state": false,
			"label": pin_conf.get("label", "In" + str(pin_conf["identifier"]))
		})
		
	outputs.clear()
	for pin_conf in external_outputs_config:
		outputs.append({
			"identifier": pin_conf["identifier"],
			"current_state": false,
			"next_state": false,
			"label": pin_conf.get("label", "Out" + str(pin_conf["identifier"]))
		})
		
	external_input_mappings = new_input_mappings
	external_output_mappings = new_output_mappings
	queue_redraw()
