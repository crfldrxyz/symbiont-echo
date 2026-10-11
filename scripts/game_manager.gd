extends Node
## GameManager Autoload – high-level orchestration for the vertical slice.

func _ready() -> void:
	print("[GameManager] Symbiont Echo vertical slice online (Godot 4.7).")
	if GrokClient:
		GrokClient.response_received.connect(_on_grok_response)

func _on_grok_response(prompt_id: String, data: Dictionary) -> void:
	print("[GameManager] Grok response for ", prompt_id, ": ", data)
	# In a full game we would route this to dialogue UI, quest log, etc.
	if data.has("text"):
		var elara = get_tree().get_first_node_in_group("elara")
		if elara and elara.has_method("say"):
			elara.say(str(data["text"]))
