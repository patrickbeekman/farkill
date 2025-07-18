extends Control

@onready var roll_button = $RollButton
@onready var dice_container = $VBoxContainer/RollContainer
@onready var kept_container = $VBoxContainer/KeptContainer

const DIE_SCENE = preload("res://scenes/Die.tscn")
const NUM_DICE = 6

var dice_instances = []
var newly_kept_dice = []
var total_score := 0

var current_level := 1
var goal_score := 1000
var rounds_left := 3

func _ready():
	randomize()
	# Instantiate dice once at startup
	for i in range(NUM_DICE):
		var die = DIE_SCENE.instantiate()
		dice_container.add_child(die)
		dice_instances.append(die)

	$LevelLabel.text = "Level " + str(current_level) + "\n Goal " + str(goal_score)
	start_round()

	
func _on_roll_pressed():
	newly_kept_dice.clear()
	var roll_container = $VBoxContainer/RollContainer
	var unkept_dice = roll_container.get_children()

	for die in unkept_dice:
		die.roll()

	if !has_valid_score(unkept_dice):
		_fark()
		return

	var current_roll_score = calculate_score(newly_kept_dice)
	$ScoreLabel.text = "This roll: " + str(current_roll_score) + "\nSelect dice to keep and press Bank"



func calculate_score(dice_to_score: Array) -> int:
	var counts = {}
	for die in dice_to_score:
		var val = die.value
		counts[val] = counts.get(val, 0) + 1

	var current_score = 0

	for val in counts:
		var count = counts[val]

		# Three or more of a kind
		if count >= 3:
			if val == 1:
				current_score += 1000
			else:
				current_score += val * 100
			count -= 3

		# Remaining 1s or 5s
		if val == 1:
			current_score += count * 100
		elif val == 5:
			current_score += count * 50

	return current_score

func _on_bank_pressed():
	var kept_dice = kept_container.get_children()
	var banked_score = calculate_score(kept_dice)
	total_score += banked_score
	rounds_left -= 1

	if total_score >= goal_score:
		_next_level()
	else:
		$ScoreLabel.text = "Banked " + str(banked_score)
		$RoundScoreLabel.text = "Score: " + str(total_score)
		_end_round()


func _reset_dice():
	var roll_container = $VBoxContainer/RollContainer
	var selected_container = $VBoxContainer/KeptContainer

	for die in dice_instances:
		# Ensure die is moved back to roll container if it's not already there
		if die.get_parent() != roll_container:
			die.get_parent().remove_child(die)
			roll_container.add_child(die)

		# Reset visual and state
		die.is_kept = false
		die.modulate = Color(1, 1, 1)
		die.roll()
	newly_kept_dice.clear()
		
func has_valid_score(dice_to_check: Array) -> bool:
	return calculate_score(dice_to_check) > 0
	
func _fark():
	$ScoreLabel.text = "FARK!!!"
	rounds_left -= 1
	_end_round()
	
func move_die_to_selected(die: Node):
	if die.get_parent() == dice_container:
		dice_container.remove_child(die)
		kept_container.add_child(die)
		newly_kept_dice.append(die)

	
func start_round():
	$ScoreLabel.text = "Level " + str(current_level) + "\nRounds Left: " + str(rounds_left)
	$ActionButtons/BankButton.disabled = false
	$RollButton.disabled = false
	_reset_dice()

func _next_level():
	current_level += 1
	goal_score += 500  # dynamic scaling
	rounds_left = 3
	total_score = 0

	$LevelLabel.text = "Level " + str(current_level) + "\nGoal " + str(goal_score)
	$RoundScoreLabel.text = "Score: " + str(total_score)
	$ScoreLabel.text = "Level up!"
	$ActionButtons/BankButton.disabled = false
	$RollButton.disabled = false
	_reset_dice()

func _end_round():
	$ActionButtons/BankButton.disabled = true
	$RollButton.disabled = true

	if rounds_left <= 0:
		if total_score >= goal_score:
			_next_level()
		else:
			$ScoreLabel.text += "\nGAME OVER! Click to return.\nYou needed " + str(goal_score)
			$ActionButtons/BankButton.disabled = true
			$RollButton.disabled = true
			$NextRound.disabled = true  # if you have one

			# Delay and return to start
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")
	else:
		$ScoreLabel.text += "\nStart next round"
