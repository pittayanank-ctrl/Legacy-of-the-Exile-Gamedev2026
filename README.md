# Legacy of the Exile

**Legacy of the Exile** is a 2D side-scrolling action game developed as part of the **Computer Game Development** course at the **College of Computing, Khon Kaen University**.

The game is set in a medieval fantasy world where the protagonist becomes involved in a story of conflict, loyalty, and revenge. Players will explore villages, forests, cities, and castles while fighting enemies and progressing through the story.

## Preview

![Legacy of the Exile](docs/preview.png)

## Features

- **2D Side-Scrolling Action** — Explore a medieval fantasy world through side-scrolling levels.
- **Sword Combat System** — Attack enemies using a three-hit combo system.
- **Running Attack** — Perform attacks while moving to create more dynamic combat.
- **Block System** — Defend against enemy attacks by blocking at the right time.
- **Stamina System** — Running and blocking consume stamina, requiring players to manage their stamina during combat.
- **Enemy AI** — Enemies can detect, chase, attack, defend, and react to player attacks.
- **Enemy Blocking** — Enemies can block player attacks based on their defensive behavior.
- **Enemy Health System** — Enemies have HP bars displayed above their heads.
- **Knockback & Hurt System** — Characters react to attacks with damage, stun, and knockback effects.
- **Combat Music** — Background music changes when entering and leaving combat.
- **Sound Effects** — Includes walking, running, attacking, blocking, taking damage, and other gameplay sounds.
- **Dialogue System** — Characters can interact with the player and display story dialogue with character portraits.
- **Story Progression** — Dialogue and missions are used to progress the game's story.
- **Mission System** — Complete objectives to advance through the game.
- **Scene Transition** — Smooth fade transitions are used when moving between levels.
- **Save & Load** — Save game progress and important gameplay information.
- **Game State Management** — A central GameManager manages player HP, lives, missions, levels, and save data.
- **Audio Management** — AudioManager controls background music, combat music, sound effects, and audio settings.
- **Medieval Fantasy World** — Explore different environments including villages, forests, cities, and castles.
- **Multiple Levels** — Progress through different areas as the story develops.

## Story

The protagonist lives with his father in a quiet rural village. Behind their peaceful life lies a forgotten past and a deep grudge connected to the kingdom.

As the protagonist grows older, he begins to uncover the truth about his family's past. His journey eventually leads him from his home to the training grounds, forests, city, and royal castle.

Along the way, he meets warriors, villagers, soldiers, and the king. The choices and events of the journey gradually reveal the truth behind the conflict and the reason for his father's past.

## Levels

The game consists of several areas:

1. **Home of the Exile** — The protagonist's home.
2. **Forgotten Village** — A rural village where the journey begins.
3. **The Training Grounds** — A training area where the protagonist learns combat.
4. **Forest of Shadows** — A dangerous forest filled with enemies.
5. **The Deep Wilds** — A deeper and more dangerous part of the forest.
6. **The Fallen City** — A city affected by conflict.
7. **The Royal Castle** — The castle of the kingdom.
8. **The Throne Room** — The final area where the story reaches its conclusion.

## Combat System

### Player

The player can:

- Walk
- Run
- Attack
- Perform attack combos
- Perform running attacks
- Block enemy attacks
- Manage stamina
- Take damage
- Receive knockback
- Recover from attacks
- Die and restart

### Attack Combo

The player's basic attack consists of three attacks:

```text
Attack 1
   ↓
Attack 2
   ↓
Attack 3
