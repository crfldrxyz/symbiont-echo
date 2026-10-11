extends Node
## EmotionInference Autoload
## Analyzes pure in-game behavioral signals (no cameras / mics) and maintains Tide scores.
## Godot 4.7 compatible.

signal tide_changed(new_tide: String, scores: Dictionary)
signal scores_updated(scores: Dictionary)

const TIDES := ["neutral", "rage", "sorrow", "joy", "fear", "resolve"]

var scores: Dictionary = {
	"neutral": 20.0,
	"rage": 0.0,
	"sorrow": 0.0,
	"joy": 0.0,
	"fear": 0.0,
	"resolve": 0.0
}

var current_tide: String = "neutral"
var decay_rate: float = 0.985          # per physics frame approx
var residue_carry: float = 0.15        # how much previous session influences new one

# Runtime tracking
var _last_position: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _kill_count: int = 0
var _retry_count: int = 0
var _dialogue_engages: int = 0
var _dialogue_skips: int = 0
var _pause_frames: int = 0

func _ready() -> void:
	print("[EmotionInference] Online – privacy-first behavioral analysis active.")

func _physics_process(delta: float) -> void:
	# Gentle continuous decay toward neutral baseline
	for t in scores.keys():
		if t == "neutral":
			continue
		scores[t] *= decay_rate
		if scores[t] < 0.5:
			scores[t] = 0.0

	_update_dominant_tide()

# ---------- Public API for other systems ----------

func register_aggression(amount: float = 8.0) -> void:
	scores["rage"] = clampf(scores["rage"] + amount, 0.0, 100.0)
	scores["resolve"] = maxf(0.0, scores["resolve"] - amount * 0.3)
	_emit_update()

func register_hesitation(amount: float = 5.0) -> void:
	scores["fear"] = clampf(scores["fear"] + amount * 0.6, 0.0, 100.0)
	scores["sorrow"] = clampf(scores["sorrow"] + amount * 0.4, 0.0, 100.0)
	_emit_update()

func register_persistence(amount: float = 6.0) -> void:
	scores["resolve"] = clampf(scores["resolve"] + amount, 0.0, 100.0)
	_emit_update()

func register_joy_event(amount: float = 7.0) -> void:
	scores["joy"] = clampf(scores["joy"] + amount, 0.0, 100.0)
	_emit_update()

func register_dialogue_engage() -> void:
	_dialogue_engages += 1
	register_joy_event(3.0)

func register_dialogue_skip() -> void:
	_dialogue_skips += 1
	register_hesitation(4.0)

func register_retry() -> void:
	_retry_count += 1
	register_persistence(5.0)

func force_tide(tide: String) -> void:
	if tide not in TIDES:
		return
	for t in scores.keys():
		scores[t] = 0.0
	scores[tide] = 95.0
	_update_dominant_tide()
	_emit_update()

func get_dominant_tide() -> String:
	return current_tide

func get_scores() -> Dictionary:
	return scores.duplicate()

# ---------- Internal ----------

func _update_dominant_tide() -> void:
	var max_score := -1.0
	var dominant := "neutral"
	for t in scores.keys():
		if scores[t] > max_score:
			max_score = scores[t]
			dominant = t

	# Require a meaningful lead to switch away from current
	if dominant != current_tide and max_score > scores.get(current_tide, 0.0) + 12.0:
		var old := current_tide
		current_tide = dominant
		tide_changed.emit(current_tide, scores.duplicate())
		print("[EmotionInference] Tide shift: %s → %s" % [old, current_tide])

func _emit_update() -> void:
	scores_updated.emit(scores.duplicate())
