extends CharacterBody2D
## Simple top-down player controller for the vertical slice.
## Feeds movement & action signals into EmotionInference.
## Godot 4.7

@export var speed: float = 280.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	# Feed movement style into emotion system
	if EmotionInference:
		var spd := velocity.length()
		if spd > 250.0:
			EmotionInference.register_aggression(0.4 * delta * 60.0)  # fast = aggressive
		elif spd < 40.0 and spd > 0.1:
			EmotionInference.register_hesitation(0.25 * delta * 60.0)
		elif spd > 100.0 and spd < 180.0:
			EmotionInference.register_joy_event(0.15 * delta * 60.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("force_rage"):
		EmotionInference.force_tide("rage")
	elif event.is_action_pressed("force_sorrow"):
		EmotionInference.force_tide("sorrow")
	elif event.is_action_pressed("force_joy"):
		EmotionInference.force_tide("joy")
	elif event.is_action_pressed("force_fear"):
		EmotionInference.force_tide("fear")
	elif event.is_action_pressed("force_resolve"):
		EmotionInference.force_tide("resolve")
