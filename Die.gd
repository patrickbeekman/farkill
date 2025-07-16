extends Control

var value: int = 0

func roll():
	value = randi() % 6 + 1
	$ValueLabel.text = str(value)
