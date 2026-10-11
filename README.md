# Symbiont Echo

**Your emotions rewrite the story. Forever.**

Emotion-driven Action-Adventure RPG built with **Godot 4.7** and powered by the **xAI Grok API**.

## Core Features (MVP Vertical Slice)
- Behavioral Emotion Inference Engine (no cameras/mics)
- Elara-7 holographic companion with real-time Tide morphing
- Grok API Narrative Director (quests, dialogue, branching)
- Soul Graph export foundation
- Hybrid online/offline support

## Requirements
- Godot 4.7 or newer
- xAI API key (set in Project Settings → Autoload → GrokClient or environment)

## Quick Start
1. Clone this repository
2. Open the project in Godot 4.7+
3. Set your Grok API key (see `scripts/grok_client.gd`)
4. Run the main scene

## Project Structure
```
symbiont-echo/
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── elara.tscn
│   └── player.tscn
├── scripts/
│   ├── emotion_inference.gd   # Autoload – analyzes player signals
│   ├── grok_client.gd         # Autoload – talks to xAI Grok API
│   ├── elara.gd               # Companion logic + visual morphs
│   ├── player.gd              # Simple player controller
│   └── game_manager.gd        # High-level orchestration
├── assets/                    # Place art, audio, fonts here
└── docs/
    └── (Game Design Document reference)
```

## License
Proprietary / All rights reserved for now. Contact the project owner for licensing.

---
Built with ❤️ and Grok.
