extends Control

@onready var roll_button = $ActionButtons/RollButton
@onready var dice_container = $VBoxContainer/RollContainer
@onready var kept_container = $VBoxContainer/KeptContainer

var help_menu = preload("res://scenes/HelpMenu.tscn").instantiate()

const DIE_SCENE = preload("res://scenes/Die.tscn")
const NUM_DICE = 6

var dice_instances = []
var newly_kept_dice = []
var total_score := 0

var current_level := 1
var goal_score := 500
var rounds_left := 3
var num_rounds := 3

func _ready():
	add_child(help_menu)
	help_menu.visible = false
	randomize()
	for i in range(NUM_DICE):
		var die = DIE_SCENE.instantiate()
		dice_container.add_child(die)
		dice_instances.append(die)

	$LevelLabel.text = "Level " + str(current_level) + "\n Goal " + str(goal_score)
	start_round()

func _on_roll_pressed():
	newly_kept_dice.clear()
	var unkept_dice = dice_container.get_children()
	for die in unkept_dice:
		die.roll()

	if !has_valid_score(unkept_dice):
		_fark()
		return

	var current_roll_score = calculate_score(newly_kept_dice)
	$ScoreLabel.text = "This roll: " + str(current_roll_score)

func calculate_score(dice_to_score: Array) -> int:
	var counts = {}
	for die in dice_to_score:
		var val = die.value
		counts[val] = counts.get(val, 0) + 1

	var current_score = 0
	var values = counts.keys()
	var count_values = counts.values()

	# Special pattern: Straight (1-6)
	if values.size() == 6:
		current_score += 1500
		return current_score

	# Special pattern: Three pairs
	if values.size() == 3 and count_values.count(2) == 3:
		current_score += 1500
		return current_score

	# Special pattern: Two triplets
	if values.size() == 2 and count_values.count(3) == 2:
		current_score += 2500
		return current_score

	# Special pattern: Five-dice full house (3 + 2)
	if dice_to_score.size() == 5 and values.size() == 2:
		if (3 in count_values and 2 in count_values):
			current_score += 1000  # adjust this if you want
			return current_score

	# Count scoring for kinds and singles
	for val in counts:
		var count = counts[val]

		# Three or more of a kind
		if count >= 3:
			if val == 1:
				current_score += 1000
				current_score += (count - 3) * 100  # bonus for each extra '1'
			else:
				current_score += val * 100
				current_score += (count - 3) * val * 100  # bonus per die
			continue  # already scored, skip to next

		# Remaining 1s or 5s
		if val == 1:
			current_score += count * 100
		elif val == 5:
			current_score += count * 50

	return current_score

func update_current_score_display():
	var kept_dice = kept_container.get_children()
	var score = calculate_score(kept_dice)
	$ScoreLabel.text = "Score: %d pts" % score


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
	for die in dice_instances:
		if die.get_parent() != dice_container:
			die.get_parent().remove_child(die)
			dice_container.add_child(die)

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

func move_die(die: Node):
	if die.get_parent() == dice_container:
		dice_container.remove_child(die)
		kept_container.add_child(die)
		die.is_kept = true
		die.modulate = Color(0.7, 1, 0.7)
		newly_kept_dice.append(die)
	elif die.get_parent() == kept_container:
		kept_container.remove_child(die)
		dice_container.add_child(die)
		die.is_kept = false
		die.modulate = Color(1, 1, 1)
		newly_kept_dice.erase(die)

func start_round():
	#$ScoreLabel.text = "Level " + str(current_level) + "\nRounds Left: " + str(rounds_left)
	$ActionButtons/BankButton.disabled = false
	$ActionButtons/RollButton.disabled = false
	$RoundsLabel.text = "Round "  + str(rounds_left) + "/" + str(num_rounds)
	_reset_dice()

func _next_level():
	current_level += 1
	goal_score += 500
	rounds_left = 3
	total_score = 0

	$LevelLabel.text = "Level " + str(current_level) + "\nGoal " + str(goal_score)
	$RoundScoreLabel.text = "Score: " + str(total_score)
	$ScoreLabel.text = "Level up!"
	$ActionButtons/BankButton.disabled = false
	$ActionButtons/RollButton.disabled = false
	_reset_dice()

func _end_round():
	$ActionButtons/BankButton.disabled = true
	$ActionButtons/RollButton.disabled = true

	if rounds_left <= 0:
		if total_score >= goal_score:
			_next_level()
		else:
			$ScoreLabel.text += "GAME OVER!"
			$ActionButtons/BankButton.disabled = true
			$ActionButtons/RollButton.disabled = true
			$ActionButtons/NextRound.disabled = true
			$GameOverButton.visible = true
			$GameOverButton.grab_focus()
	else:
		$ScoreLabel.text += "\nStart next round"
		
func _on_GameOverButton_pressed():
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")
	
func _on_HelpButton_pressed():
	help_menu.visible = true
	
