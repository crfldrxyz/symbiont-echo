extends CharacterBody2D
## Elara-7 – holographic fox-dragon companion
## Follows the player and morphs according to EmotionInference tide.
## Godot 4.7

@export var follow_speed: float = 220.0
@export var float_amplitude: float = 12.0
@export var float_speed: float = 2.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var player: Node2D
var angle: float = 0.0
var current_tide: String = "neutral"

# Simple color map for the 6 Tides (replace with proper shaders / animated sprites later)
var tide_colors := {
	"neutral": Color(0.3, 0.85, 1.0),
	"rage": Color(1.0, 0.2, 0.15),
	"sorrow": Color(0.35, 0.25, 0.85),
	"joy": Color(1.0, 0.85, 0.2),
	"fear": Color(0.7, 0.2, 0.95),
	"resolve": Color(0.2, 0.95, 0.45)
}

func _ready() -> void:
	if EmotionInference:
		EmotionInference.tide_changed.connect(_on_tide_changed)
		current_tide = EmotionInference.get_dominant_tide()
		_apply_tide_visual(current_tide)
	# Try to find the player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Smooth follow with floating motion
	var target := player.global_position + Vector2(-60, -40)
	var dir := (target - global_position)
	if dir.length() > 8.0:
		velocity = dir.normalized() * follow_speed
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.15)
	move_and_slide()

	angle += delta * float_speed
	position.y += sin(angle) * float_amplitude * delta * 10.0

	# Keep label facing camera (2D)
	if label:
		label.text = current_tide.capitalize()

func _on_tide_changed(new_tide: String, _scores: Dictionary) -> void:
	current_tide = new_tide
	_apply_tide_visual(new_tide)
	# Ask Grok for a short reaction line
	if GrokClient:
		GrokClient.generate_elara_line("elara_react_" + str(Time.get_ticks_msec()), new_tide, "Player emotion shifted")

func _apply_tide_visual(tide: String) -> void:
	var col: Color = tide_colors.get(tide, tide_colors["neutral"])
	if sprite:
		sprite.modulate = col
	# Future: swap texture / play animation / change particles here
	print("[Elara] Morph → ", tide)

func say(text: String) -> void:
	if label:
		label.text = text
		# Simple auto-clear after a few seconds could be added with a Timer
