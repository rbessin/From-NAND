class_name NandGate
extends Node

var input_a_source: Node = null
var input_b_source: Node = null
var output: bool = false
var next_output: bool = false

func compute_next():
	if input_a_source == null or input_b_source == null:
		next_output = false
		return
	var a = input_a_source.output
	var b = input_b_source.output
	next_output = !(a and b)

func update():
	output = next_output
