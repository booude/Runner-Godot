extends Node2D

signal game_over

@export var world_speed = 900

@onready var moving_environment = $Environment/Moving
@onready var distance_label = $HUD/UI/Distance
@onready var score_label = $HUD/UI/Score
@onready var player = $Player
@onready var ground = $Environment/Static/Ground
@onready var game_over_label = $HUD/UI/GameOver

var platform = preload("res://scenes/platform.tscn")
var platform_obstacle = preload("res://scenes/platform_obstacle.tscn")
var platform_enemy = preload("res://scenes/platform_enemy.tscn")
var platform_moving_enemy = preload("res://scenes/platform_moving_enemy.tscn")
var platform_collectible = preload("res://scenes/platform_collectible.tscn")

var rng = RandomNumberGenerator.new()
var last_platform_position = Vector2.ZERO
var next_spawn_time = 0
var distance = 0
var prev_distance = 1.0
var max_speed = world_speed
var min_speed = world_speed
var score = 37

func _ready():
	rng.randomize()
	player.player_died.connect(_on_player_died)
	ground.body_entered.connect(_on_ground_body_entered)

func _process(delta):
	if not player.active:
		if Input.is_action_just_pressed("jump"):
			get_tree().reload_current_scene()
		return

	distance += 0.00003 * world_speed
	score -= 0.0003
	if score <= 30:
		player.die()

	if snapped(distance, 0) == prev_distance:
		prev_distance += 1
		if world_speed < max_speed:
			world_speed += 1

	# Spawn a new platform
	if Time.get_ticks_msec() > next_spawn_time:
		_spawn_next_platform()

	# Update the UI labels
	distance_label.text = "%sm" % snapped(distance, 0)
	score_label.text = "Temp: %sºC" % snapped(score, 0)

func _spawn_next_platform():
	var platforms =[
		platform,
		platform_moving_enemy,
		platform_obstacle,
		platform_enemy,
		platform,
		platform_collectible
	]
	var random_platform = platforms.pick_random()
	var new_platform = random_platform.instantiate()

	# Set position of new platform
	if last_platform_position == Vector2.ZERO:
		new_platform.position = Vector2(300, 550)
	else:
		var x = last_platform_position.x + rng.randi_range(2000, 2400) # Test values
		var y = clamp(last_platform_position.y + rng.randi_range(-150, 150), 350, 700) # Test values
		new_platform.position = Vector2(x, y)

	# Add platform to moving environment
	moving_environment.add_child(new_platform)

	# Update last platform position and increase next spawn
	last_platform_position = new_platform.position
	next_spawn_time += world_speed

func _physics_process(delta):
	if not player.active:
		return

	#Move plataforms left
	moving_environment.position.x -= world_speed * delta

func hit(value):
	player.is_hit()
	if world_speed / 2 > min_speed:
		world_speed = world_speed / 2
	else:
		world_speed = min_speed

func add_score(value):
	score = value

func speed():
	return world_speed

func _on_player_died():
	emit_signal("game_over")
	game_over_label.text = game_over_label.text % snapped(distance, 0)
	game_over_label.set_visible(true)

func _on_ground_body_entered(body):
	if body.is_in_group("player"):
		player.die()
