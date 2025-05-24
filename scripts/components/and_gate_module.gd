class_name AndGateModule
extends Node

@onready var nand1 = NandGate.new()
@onready var nand2 = NandGate.new()

var input_a = InputSource.new()
var input_b = InputSource.new()
var output: bool = false

func _ready():
	add_child(nand1)
	add_child(nand2)

	nand1.input_a_source = input_a
	nand1.input_b_source = input_b

	nand2.input_a_source = nand1
	nand2.input_b_source = nand1

func step():
	nand1.compute_next()
	nand2.compute_next()
	nand1.update()
	nand2.update()
	output = nand2.output
