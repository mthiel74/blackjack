# Community notebook

A Wolfram Notebook (`blackjack.nb`) written in the style of a
Wolfram Community post. Combines an abstract, the mathematical
background of Blackjack, the basic-strategy and Hi-Lo card-counting
theory, and a live, playable embed of the game.

## Contents

| File                  | Purpose                                                                         |
|-----------------------|---------------------------------------------------------------------------------|
| `blackjack.nb`        | The notebook. Open in a Wolfram Front End.                                      |
| `blackjack.pdf`       | PDF export of the same content (for offline review / Community preview).        |
| `build_notebook.wls`  | Rebuilds `blackjack.nb` + `blackjack.pdf` from prose + images.                  |
| `generate_images.wls` | Rebuilds the five PNGs in `images/` from the live package code.                 |
| `images/`             | Figures + demo recording.                                                       |

### `images/` contents

| File                       | Role                                                                 |
|----------------------------|----------------------------------------------------------------------|
| `game_overview.png`        | Static mock-up of the UI (used for Figure 1).                        |
| `cards_showcase.png`       | Eight rank templates + card back (Figure 2).                         |
| `dealer_bust.png`          | Exact S17 dealer-bust probability by upcard (Figure 3).              |
| `basic_strategy.png`       | Hit/Stand basic-strategy chart (Figure 4).                           |
| `ev_heatmap.png`           | EV(Hit) - EV(Stand) heatmap (Figure 5).                              |
| `blackjack_demo_frame.png` | Representative still from the screen recording (teaser in §0 and §8). |
| `blackjack_demo.gif`       | Full animated recording, 720×846 @ 12 fps, 94 s, 7.4 MB.             |
| `blackjack_demo.mp4`       | Same recording as H.264 (788 KB) for readers who want a smaller, higher-fidelity alternative to the GIF. |

The notebook ships with the still frame visible at the top (teaser) and
again in §8. Each still is immediately followed by a ready-to-evaluate
`AnimatedImage[Import[...]]` cell: one click plays the full animation
in place.

The original screen-capture `.mov` is intentionally `.gitignore`d
(~32 MB); only the compressed GIF and MP4 are tracked.

## Reading it

Open `blackjack.nb` in any Wolfram Front End (Mathematica, Wolfram Player,
Wolfram Cloud). The notebook contains a Title, Abstract, nine numbered
sections, and a playable cell near the end.

To run the embedded game, evaluate the two input cells in §8 (Play the
game). They `Get[]` the two `.wl` packages from the parent directory
(`Wolfram/`) and then call `BlackjackGame[]` — the full interactive UI
appears underneath.

If you don't have the repository cloned but want to try the game
standalone, download `Wolfram/Blackjack.wl` and
`Wolfram/BlackjackGame.wl`, place them next to the notebook (or
anywhere on disk) and adjust the two `Get[...]` paths accordingly.

## Rebuilding

From this directory:

```bash
# Regenerate the 5 PNG figures (requires a Wolfram Front End).
wolframscript -file generate_images.wls

# Rebuild blackjack.nb and blackjack.pdf from the figures and prose.
wolframscript -file build_notebook.wls
```

`generate_images.wls` loads `../Blackjack.wl` + `../BlackjackGame.wl`
and uses their internal rendering helpers so every figure is produced
by the same code that powers the game. The EV heatmap runs ~30 s of
Monte-Carlo; everything else is instant.

## Structure of the post

1. **Abstract** — summary + cover screenshot.
2. **What is Blackjack?** — rules and actions.
3. **Cards and visual representation** — the card data model + pip layouts.
4. **The mathematics** — P(natural), dealer bust distribution, Bellman equation, house edge, rule-variation table.
5. **Basic strategy** — the Hit/Stand chart.
6. **Monte-Carlo EV** — how `EstimateEV` works + a heatmap of EV(Hit) - EV(Stand).
7. **Card counting** — Hi-Lo, true count, linear EV model, Kelly criterion.
8. **Package architecture** — the public API of `Blackjack\`` and `BlackjackGame\``.
9. **Play the game** — embedded live UI + how-to-play bullets.
10. **Standalone use** — running outside this notebook.
11. **References** — the canonical Blackjack literature.
