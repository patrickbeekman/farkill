extends Control

var value: int = 0
var is_kept := false

func roll():
	value = randi() % 6 + 1
	$ValueLabel.text = str(value)

func _ready():
	$ValueLabel.text = str(value)
	self.gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var parent = get_parent()
		var main = get_tree().root.get_node("Main")  # adjust this if "Main" isn't at the root
		main.move_die(self)

		main.update_current_score_display()

func toggle_keep():
	var parent = get_parent()
	var main = get_node("/root/Main")

	if is_kept:
		main.get_node("VBoxContainer/RollContainer").add_child(self)
		is_kept = false
		modulate = Color(1, 1, 1)
	else:
		main.get_node("VBoxContainer/KeptContainer").add_child(self)
		is_kept = true
		modulate = Color(0.7, 1, 0.7)
