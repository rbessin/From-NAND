extends Node

@onready var and_gate = AndGateModule.new()
@onready var label = $"OutputLabel"
@onready var toggle_a = $"ToggleA"
@onready var toggle_b = $"ToggleB"

func _ready():
	add_child(and_gate)
	update_inputs()
	display_output()

func _on_StepButton_pressed():
	update_inputs()
	and_gate.step()
	display_output()

func update_inputs():
	and_gate.input_a.output = toggle_a.button_pressed
	and_gate.input_b.output = toggle_b.button_pressed

func display_output():
	label.text = "Output: %s" % str(and_gate.output)
