# Life in the City

A gritty, choice-driven third-person story game set in Toronto. You are **Malik**, 18, born and raised in a two-bedroom apartment at Jane & Finch with his parents. The game follows his climb from the corner to a penthouse above downtown — if the choices you make let him live that long.

## Design pillars

- **3 tight acts, ~30–45 min** — corner → come-up → the top
- **Choices are the gameplay.** Four hidden stats track everything: **REP**, **HEAT**, **LOYALTY**, **CASH**
- **Multiple endings** decided by the stats: Penthouse / Prison / Dead / Out Clean
- **Real Toronto** — Jane & Finch, Scarborough, downtown, King West; real slang, real transit
- **Gritty but grounded** — The Wire / Top Boy energy, no cartoon crime
- Fights are cinematic **QTE scenes**, not a combat system

## Running it

Godot 4.7+ required (`winget install GodotEngine.GodotEngine`).

```powershell
godot --path .          # run the game
godot -e --path .       # open the editor
```

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Camera / turn |
| Shift | Sprint |
| E | Interact |
| Esc | Release/capture mouse |

## Project structure

```
scenes/
  apartment/malik_bedroom.tscn   # Act 0 opening scene (current main scene)
  player/player.tscn             # 3rd-person controller
  ui/hud.tscn                    # stat readout + interact prompt
  ui/dialogue_ui.tscn            # dialogue/choice panel
scripts/
  systems/game_state.gd          # autoload: stats + story flags
  systems/dialogue_manager.gd    # autoload: JSON dialogue graph runner
  player/player.gd
  interaction/interactable.gd    # base for anything you can press E on
  ui/
data/
  dialogue/act0_bedroom.json     # opening scene dialogue
```

## Dialogue format

Dialogue lives in `data/dialogue/*.json` — a dictionary of nodes. Each node has `speaker`, `text`, and either `choices` (each with `next` + optional `effects`) or a `next` id. `effects` adjust stats (`{"rep": 1}`) or set story flags (`{"flags": ["texted_ty"]}`). `"end"` terminates.

## Roadmap

- [x] Bones: player controller, interaction, dialogue engine, stats, HUD
- [x] Act 0 test scene: Malik's bedroom, Jane & Finch apartment
- [x] Placeholder characters: Malik (hoodie, jeans, sneakers) + Ma (shawl, dress) — `scenes/characters/`
- [x] Full 2BR apartment: washroom, master bedroom + ensuite, balcony with skyline view
- [ ] Act 1, Scene 1: "The Lot"
- [ ] Conditional dialogue (branch on flags/stats)
- [ ] QTE fight system
- [ ] Save/load
- [ ] Low-poly art pass (Kenney/Quaternius) + CN Tower skyline
- [ ] Endings engine (stat thresholds → 4 endings)
