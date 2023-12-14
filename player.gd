extends CharacterBody2D

signal player_moving_signal
signal player_stopped_signal

signal player_entering_door_signal
signal player_entered_door_signal


@export var walk_speed = 4.0
@export var jump_speed = 4.0
const TILE_SIZE = 16

@onready var anim_tree = $animationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var ray = $rayCollisionWorld
@onready var gras = $rayEnteredTallGrass


enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

var initial_position = Vector2(0, 0)
var input_direction = Vector2(0, 1)
var is_moving = false
var stop_input: bool = false
var percent_moved_to_next_tile = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	anim_tree.active = true
	initial_position = position
	anim_tree.set("parameters/idle/blend_position", input_direction)
	anim_tree.set("parameters/walk/blend_position", input_direction)
	anim_tree.set("parameters/turn/blend_position", input_direction)
	
func set_spawn(location: Vector2, direction: Vector2):
		anim_tree.set("parameters/idle/blend_position", direction)
		anim_tree.set("parameters/walk/blend_position", direction)
		anim_tree.set("parameters/turn/blend_position", direction)
		position = location
	
func _physics_process(delta):
	if player_state == PlayerState.TURNING or stop_input:
		return
	elif is_moving == false:
		process_player_movement_input()
	elif input_direction != Vector2.ZERO:
		anim_state.travel("walk")
		move(delta)
	else:
		anim_state.travel("idle")
		is_moving = false

func process_player_movement_input():
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		
	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/idle/blend_position", input_direction)
		anim_tree.set("parameters/walk/blend_position", input_direction)
		anim_tree.set("parameters/turn/blend_position", input_direction)
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("turn")
		else:
			initial_position = position
			is_moving = true
	else:
		anim_state.travel("idle")
		
func need_to_turn():
	var new_facing_direction
	if input_direction.x < 0:
		new_facing_direction = FacingDirection.LEFT
	elif input_direction.x > 0:
		new_facing_direction = FacingDirection.RIGHT
	elif input_direction.y < 0:
		new_facing_direction = FacingDirection.UP
	elif input_direction.y > 0:
		new_facing_direction = FacingDirection.DOWN
	
	if facing_direction != new_facing_direction:
		facing_direction = new_facing_direction
		return true
	facing_direction = new_facing_direction
	return false

func finished_turning():
	player_state = PlayerState.IDLE
	

func move(delta):
	var desired_step: Vector2 = input_direction * TILE_SIZE / 2
	ray.target_position = desired_step
	ray.force_raycast_update()
	if !ray.is_colliding():
		if percent_moved_to_next_tile == 0:
			emit_signal("player_moving_signal")
		percent_moved_to_next_tile += walk_speed * delta
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + (input_direction * TILE_SIZE)
			percent_moved_to_next_tile = 0.0
			is_moving = false
			emit_signal("player_stopped_signal")
		else:
			position = initial_position + (input_direction * TILE_SIZE * percent_moved_to_next_tile)
	else:
		is_moving = false
		
	if gras.is_colliding():
		get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

