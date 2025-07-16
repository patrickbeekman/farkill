extends Control

@onready var roll_button = $RollButton
@onready var dice_container = $DiceContainer

const DIE_SCENE = preload("res://scenes/Die.tscn")
const NUM_DICE = 6

var dice_instances = []
var turn_score := 0
var total_score := 0

var current_level := 1
var goal_score := 2000
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
	for die in dice_instances:
		die.roll()
		
	var cur_roll_score = calculate_score()
	
	if cur_roll_score == 0:
		_fark()
		return

	turn_score += cur_roll_score
	$ScoreLabel.text = "Score: " + str(turn_score)


func calculate_score() -> int:
	var counts = {}
	for die in dice_instances:
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
			count -= 3  # Subtract triple

		# Remaining 1s or 5s
		if val == 1:
			current_score += count * 100
		elif val == 5:
			current_score += count * 50

	return current_score

func _on_bank_pressed():
	total_score += turn_score
	rounds_left -= 1
	if total_score >= goal_score:
		_next_level()
	else:
		$ScoreLabel.text = "Banked " + str(turn_score)
		$RoundScoreLabel.text = "Score: " + str(total_score)
		_end_round()

func _reset_dice():
	for die in dice_instances:
		die.value = 0
		die.get_node("ValueLabel").text = "?"
		
func _fark():
	$ScoreLabel.text = "FARK!!!"
	turn_score = 0
	rounds_left -= 1
	_end_round()
	
	
func start_round():
	turn_score = 0
	$ScoreLabel.text = "Level " + str(current_level) + "\nRounds Left: " + str(rounds_left)
	$ActionButtons/BankButton.disabled = false
	$RollButton.disabled = false
	_reset_dice()

func _next_level():
	current_level += 1
	goal_score += 1000  # dynamic scaling
	rounds_left = 3
	total_score = 0
	turn_score = 0

	$LevelLabel.text = "Level " + str(current_level) + "\nGoal " + str(goal_score)
	$RoundScoreLabel.text = "Score: " + str(total_score)
	$ScoreLabel.text = "Level up! Now Level " + str(current_level) + " – Goal: " + str(goal_score)
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
			$ScoreLabel.text += "\n\nGAME OVER! You needed " + str(goal_score)
	else:
		$ScoreLabel.text += "\nStart next round"
