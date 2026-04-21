# Blackjack — Wolfram Language

A Wolfram Language port of the browser-based Blackjack game in the repo
root. Runs in any Wolfram Front End (notebook, Wolfram Player) using
`DynamicModule` for the reactive UI and `Graphics` primitives for the cards.
Beyond feature-parity with the JavaScript original, it adds analytical
tooling (basic strategy, Monte-Carlo EV, Hi-Lo count) that's a natural fit
for Wolfram and connects to the math document under `docs/`.

## Files

| File               | Purpose                                                                 |
|--------------------|-------------------------------------------------------------------------|
| `Blackjack.wl`     | Core package: deck, scoring, dealer AI, resolution, Hi-Lo, EV, strategy |
| `BlackjackGame.wl` | Interactive `DynamicModule` UI                                          |
| `tests.wls`        | `wolframscript` test suite (51 assertions)                              |

## Running the game

### In a notebook

```wolfram
Get["/absolute/path/to/Wolfram/BlackjackGame.wl"]
BlackjackGame[]
```

### From the command line

```bash
wolframscript -file BlackjackGame.wl
```

When invoked as a script with a Front End available, a notebook window
opens with the game embedded.

## Features

### Core gameplay
- Hit / Stand / New Game, with keyboard shortcuts **H**, **S**, **N**
- Dealer-draw pacing: cards reveal one at a time after Stand
- Configurable house rule: **S17** (dealer stands on soft 17) or **H17** (hits)
- Multi-deck shoe: **1, 2, 4, 6, 8** decks
- Cut-card reshuffle at adjustable penetration (50 % – 95 %)
- Session statistics with one-click reset

### Analytical side panels
- **Basic strategy hint** — inline under the hands and in the Coach panel. A
  Hit/Stand-only reduction of the standard basic-strategy chart.
- **Monte-Carlo EV** — click *Estimate EV* to run N trials (100 – 3000) and
  display per-unit EV for Hit and Stand under the current board state. The
  unseen-card pool includes the dealer's hole card, so estimates reflect
  what the player actually doesn't know.
- **Hi-Lo running count + true count** — updated live as cards are revealed,
  reset on reshuffle.
- **Session plot** — cumulative net over every round played so far.

## Running the tests

```bash
wolframscript -file tests.wls
```

Covers: deck/shoe construction, multi-deck size, reshuffle threshold,
ace-aware scoring (including permutation-invariance property), soft/bust/
blackjack predicates, S17 and H17 dealer policy, `PlayDealer` termination
(40 random trials), round resolution, Hi-Lo count including the full-deck
invariant, true-count scaling, 10 basic-strategy spot checks, and EV
ordering on two known positions.

## Design notes

- **Core vs. UI split.** All rules live in `Blackjack.wl` as pure functions
  over card associations (`<|"value" -> "A", "suit" -> "♥"|>`). The UI file
  is a thin controller that mutates DynamicModule state in response to
  button / keyboard events.
- **Ace handling.** `HandScore` starts every ace at 11 and demotes aces to
  1 one at a time while the hand is over 21.
- **Soft hands.** `IsSoft` detects whether any ace is still counting as 11
  in the optimal score; feeds both `DealerShouldHit` (for H17) and the
  basic-strategy table.
- **Counting model.** Running count accumulates Hi-Lo values over every
  card the *player* has seen since the last shuffle. The hole card is added
  to the count when it's revealed, not when it's dealt.
- **EV Monte Carlo.** Draws the dealer's hole card and any subsequent
  cards uniformly from the unseen pool. For "Hit" it plays out the player
  with basic strategy after the mandatory draw.
- **DynamicModule idioms.** Helper functions (`doHit`, `doStand`, etc.) are
  declared as DynamicModule locals so their `DownValues` share the
  persistent dynamic context of the state variables they mutate —
  otherwise Button actions would silently no-op after the first click.
- **Naming.** `Values` and `Resolve` are Protected System symbols, so the
  package uses `Ranks` and `ResolveRound`.

## Parity with the JavaScript version

| Feature                               | Browser | Wolfram |
|---------------------------------------|:-------:|:-------:|
| 52-card deck, auto-reshuffle          |   ✓     |   ✓     |
| Hit / Stand / New Game                |   ✓     |   ✓     |
| Ace as 1 or 11 (optimal)              |   ✓     |   ✓     |
| Natural-blackjack detection           |   ✓     |   ✓     |
| Dealer hits until 17                  |   ✓     |   ✓     |
| Hidden dealer hole card               |   ✓     |   ✓     |
| Session Wins / Losses / Pushes        |   ✓     |   ✓     |
| Casino-green themed UI                |   ✓     |   ✓     |
| **Keyboard shortcuts**                |         |   ✓     |
| **Animated dealer draw**              |         |   ✓     |
| **S17 / H17 toggle**                  |         |   ✓     |
| **Multi-deck shoe + cut card**        |         |   ✓     |
| **Reset stats**                       |         |   ✓     |
| **Basic-strategy hint**               |         |   ✓     |
| **Monte-Carlo EV (Hit / Stand)**      |         |   ✓     |
| **Hi-Lo running & true count**        |         |   ✓     |
| **Session plot**                      |         |   ✓     |
