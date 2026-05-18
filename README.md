# Pusoy Natural - Modern Filipino Chinese Poker

## Overview
This is a modern, premium casino-style "Pusoy" (Chinese Poker) card game built using **Godot Engine 4.2+**. It features offline single-player with AI, and local LAN multiplayer support.

## Project Structure
- `assets/`: Contains all graphics (cards, UI, effects) and audio (BGM, SFX).
- `scenes/`: Contains `.tscn` scene files like Main Menu and Gameplay.
- `scripts/autoload/`: Singleton managers that persist across scenes:
  - `GameManager.gd`: Handles player money, stats, and table tier logic.
  - `SaveManager.gd`: Handles saving and loading player profile to local storage.
  - `NetworkManager.gd`: Basic ENet setup for LAN multiplayer (hosting and joining).
- `scripts/core/`: The foundational card logic:
  - `Card.gd`: Card data structure (Suit, Rank).
  - `Deck.gd`: Generating, shuffling, and dealing cards.
  - `HandEvaluator.gd`: Evaluates 3-card and 5-card poker hands, scores them, and checks if Head < Body < Base arrangement is valid.
- `scripts/game/`: The active game session logic:
  - `GameplayManager.gd`: Controls rounds, deals cards, handles hand submission, and scores Pusoy rules.
  - `Player.gd`: Base class holding cards and arranged hand data.
  - `AIPlayer.gd`: AI bot that randomly arranges a valid hand (can be extended for smarter logic).
- `scripts/ui/`: Contains UI controllers like `main_menu.gd`.

## How to Run the Project
1. Open **Godot 4.2** (or latest stable).
2. Click **Import** and select the `project.godot` file in this folder.
3. Open `scenes/main_menu.tscn`.
4. Click the **Play** button (or press `F5`) to run the game.

## Gameplay Logic
The core logic resides in `HandEvaluator.gd` and `GameplayManager.gd`. 
When a round starts, `Deck.deal(13)` provides 13 cards to 4 players. 
Players divide cards into 3 Head, 5 Body, and 5 Base. 
`HandEvaluator.is_valid_arrangement()` ensures the rules are followed. 
Once all hands are submitted, `GameplayManager.evaluate_round()` compares them, applies Pusoy bonus rules, and modifies the human player's bankroll via `GameManager`.

## AI Management
AI is handled in `AIPlayer.gd`. Currently, it attempts to generate valid arrangements by randomly partitioning sorted cards and validating them. To make the AI smarter (Aggressive vs Easy), you would extend `_arrange_cards_ai()` to run a permutation algorithm finding the highest value legal hands instead of random valid ones.

## LAN Multiplayer
LAN Multiplayer utilizes Godot's built-in `ENetMultiplayerPeer`.
Found in `NetworkManager.gd`, a player can Host (creates server on port 4040).
Other players on the same Wi-Fi can Join by providing the host's IP address. 
Once connected, Godot's RPC system can be used to synchronize the `Deck` seed and send arranged hand data.

## Exporting for Android (APK)
1. In Godot, go to **Project > Export**.
2. Click **Add...** and select **Android**.
3. If you haven't set up the Android Build template:
   - Go to **Editor > Editor Settings > Export > Android**.
   - Provide the path to your Android SDK, Android Studio, and Debug Keystore.
4. Under the Android Export preset, check "Custom Build" if needed, and fill out your Package Name (e.g., `com.yourname.pusoynatural`).
5. Click **Export Project**, choose a destination, and it will generate an `.apk`.

## Visual Direction & Inspiration
The game's visual style is inspired by premium mobile casino games, featuring:
- **Dark Luxury Aesthetic**: Deep purple gradients, gold accents, and cyan highlights.
- **Dynamic Progression**: The table felt and atmosphere evolve from a simple green table (Low Bet) to a metallic blue (Medium Bet) and finally a regal gold/brown (High Bet).
- **Cinematic Effects**: A dramatic "PUSOY!" explosion with gold particles and screen shake occurs when a player is defeated in all three hands.
- **Mobile-First UX**: Large, readable card ranks and an intuitive "click-to-move" or "drag-and-drop" arrangement system.

The provided reference images in `assets/images/ui/Pusoy pics/` were used as inspiration for the layout, tier-based progression, and color palette.
