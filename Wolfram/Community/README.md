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

| File                          | Role                                                                                                   |
|-------------------------------|--------------------------------------------------------------------------------------------------------|
| `game_overview.png`           | Static mock-up of the UI (Figure 1).                                                                   |
| `cards_showcase.png`          | Eight rank templates + card back (Figure 2).                                                           |
| `dealer_bust.png`             | Exact S17 dealer-bust probability by upcard (Figure 3).                                                |
| `basic_strategy.png`          | Hit/Stand basic-strategy chart (Figure 4).                                                             |
| `ev_heatmap.png`              | EV(Hit) - EV(Stand) heatmap (Figure 5).                                                                |
| `blackjack_demo_frame.png`    | Representative still from the recording, used in §8.                                                   |
| `blackjack_demo_preview.gif`  | **Embedded in the notebook:** low-res teaser (420 × ~494, 6 fps, 40 s, 1.3 MB).                        |
| `blackjack_demo.gif`          | **Attachment:** full recording, 720 × 846, 12 fps, 94 s, 7.4 MB.                                       |
| `blackjack_demo.mp4`          | **Attachment:** same recording as H.264 CRF 28, 788 KB.                                                |

### GIF strategy (why two GIFs)

The notebook needs to stay small for a Wolfram Community post. A full-
resolution animated GIF embedded inline would 30× in size once Wolfram
serialises the per-frame image data, ballooning the `.nb` to ~200 MB.

The approach used here:

- **A reduced-resolution preview** (`blackjack_demo_preview.gif`,
  1.3 MB) is embedded *inline* inside the notebook, at the top, as the
  teaser. It is stored as a raw `ByteArray` literal and wrapped in a
  `DynamicBox` that decodes it into an `AnimatedImage` at display time.
  That keeps the serialised footprint close to the raw GIF size (~1.7 MB
  in the notebook) and plays live when the notebook is opened.

- **The full-quality recording** (`blackjack_demo.gif`, 7.4 MB) and a
  smaller H.264 version (`blackjack_demo.mp4`, 788 KB) live next to the
  notebook as *separate files* — intended to be uploaded as
  attachments to the Wolfram Community post so curious readers can grab
  the full-fidelity version without inflating the notebook itself.

- §8 of the notebook shows a static still frame
  (`blackjack_demo_frame.png`) instead of a second animated copy, to
  avoid embedding the preview bytes twice.

The original screen-capture `.mov` (~32 MB) is `.gitignore`d and kept
locally only.

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
