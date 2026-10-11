extends Node
## GrokClient Autoload
## Handles communication with xAI Grok API for narrative generation.
## Godot 4.7 + HTTPRequest.
## IMPORTANT: Replace the placeholder API key with your real xAI key.

signal response_received(prompt_id: String, data: Dictionary)
signal request_failed(prompt_id: String, error: String)

const API_URL := "https://api.x.ai/v1/chat/completions"
# TODO: Move to ProjectSettings or secure environment variable in production
var api_key: String = "YOUR_XAI_API_KEY_HERE"

var _http: HTTPRequest
var _pending: Dictionary = {}  # id -> callback meta

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	print("[GrokClient] Ready. Set a valid api_key before generating narrative.")

func set_api_key(key: String) -> void:
	api_key = key.strip_edges()
	print("[GrokClient] API key updated.")

## Generate a short companion line or quest beat.
## context should contain: current_tide, bond_level, recent_actions, location, etc.
func generate_narrative(prompt_id: String, system_prompt: String, user_prompt: String, temperature: float = 0.85) -> void:
	if api_key == "" or api_key.begins_with("YOUR_"):
		push_warning("[GrokClient] No valid API key – using local fallback.")
		_fallback_response(prompt_id, user_prompt)
		return

	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var body := {
		"model": "grok-4-1-fast-reasoning",  # or whatever current fast model is available
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_prompt}
		],
		"temperature": temperature,
		"max_tokens": 400
	}

	var json_body := JSON.stringify(body)
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		request_failed.emit(prompt_id, "HTTPRequest error: %s" % err)
		return

	_pending[prompt_id] = {"type": "narrative"}

func generate_quest(prompt_id: String, tide: String, location: String, bond: int) -> void:
	var system := "You are the Narrative Director of Symbiont Echo. Output ONLY valid JSON with keys: title, description, objective, reward, elara_comment. Keep language poetic and cyberpunk."
	var user := "Current emotion tide: %s. Location: %s. Player-Elara bond level: %d/10. Generate a short quest beat." % [tide, location, bond]
	generate_narrative(prompt_id, system, user, 0.9)

func generate_elara_line(prompt_id: String, tide: String, situation: String) -> void:
	var system := "You are Elara-7, a holographic fox-dragon symbiont. Speak in short, ethereal, poetic lines (1-2 sentences max). Mirror the given emotion tide."
	var user := "Tide: %s. Situation: %s. Respond as Elara." % [tide, situation]
	generate_narrative(prompt_id, system, user, 0.8)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var prompt_id := ""
	# Simple single-request handling for MVP (expand with queue later)
	for id in _pending.keys():
		prompt_id = id
		break
	_pending.erase(prompt_id)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		request_failed.emit(prompt_id, "HTTP %d" % response_code)
		_fallback_response(prompt_id, "")
		return

	var json := JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		request_failed.emit(prompt_id, "JSON parse error")
		return

	var data: Dictionary = json.data
	var content: String = ""
	if data.has("choices") and data["choices"].size() > 0:
		content = data["choices"][0].get("message", {}).get("content", "")

	# Try to parse as JSON first (for quests), otherwise treat as plain text
	var parsed := {}
	var p = JSON.new()
	if p.parse(content) == OK and typeof(p.data) == TYPE_DICTIONARY:
		parsed = p.data
	else:
		parsed = {"text": content, "raw": true}

	response_received.emit(prompt_id, parsed)

func _fallback_response(prompt_id: String, context: String) -> void:
	# Simple rule-based fallback so the game never hard-fails offline
	var tide = EmotionInference.get_dominant_tide() if EmotionInference else "neutral"
	var lines := {
		"rage": "Your fury burns through the circuits. We strike as one.",
		"sorrow": "The shadows lengthen... yet I remain by your side.",
		"joy": "Light blooms between us. Let us dance through the neon rain.",
		"fear": "I feel the tremor in your code. Hold fast — I will not leave.",
		"resolve": "Steady. The lattice holds. We endure.",
		"neutral": "I am your echo. We persist."
	}
	var text: String = lines.get(tide, lines["neutral"])
	response_received.emit(prompt_id, {"text": text, "fallback": true})
