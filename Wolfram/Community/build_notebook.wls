#!/usr/bin/env wolframscript
(* Build Wolfram/Community/blackjack.nb — a Wolfram Notebook suitable for
   posting to the Wolfram Community, with inline math typesetting and
   embedded figures. Also exports the same content as a PDF.             *)

hereDir = DirectoryName[If[$ScriptCommandLine =!= {}, $InputFileName,
                           NotebookFileName[]]];
imgDir  = FileNameJoin[{hereDir, "images"}];
packDir = FileNameJoin[{hereDir, ".."}];

imgWidth = 680;

loadImg[name_] := With[
    {p = FileNameJoin[{imgDir, name}]},
    If[FileExistsQ[p],
        Image[Import[p], ImageSize -> imgWidth],
        Style["[missing image: " <> name <> "]", Red]]];

imgCell[name_, caption_String: ""] := Cell[
    BoxData[ToBoxes[
        If[caption === "",
            loadImg[name],
            Column[{
                loadImg[name],
                Pane[Style[caption, Italic, FontSize -> 10,
                           FontFamily -> "Helvetica"],
                     imgWidth, Alignment -> Center]},
                Alignment -> Center, Spacings -> 0.6]]]],
    "Output",
    ShowCellLabel  -> False,
    TextAlignment  -> Center,
    CellMargins    -> {{0, 0}, {10, 14}}];

(* Embed an animated GIF LAZILY. DynamicBox holds its argument, so the
   ToBoxes+Import call is only evaluated at display time — the .nb stays
   small. We try NotebookDirectory[] first (portable after the user saves
   the notebook); if that fails, we fall back to the absolute build-time
   path baked in via With, which keeps the PDF export on the build
   machine working.                                                       *)
animCell[name_, caption_String: ""] := With[
    {
        nameStr    = name,
        captionStr = caption,
        W          = imgWidth,
        absImg     = FileNameJoin[{imgDir, name}]
    },
    Cell[
        BoxData[
            DynamicBox[
                ToBoxes[
                    Module[{path, anim},
                        path = Quiet @ Check[
                            With[{nbDir = NotebookDirectory[]},
                                With[{p = FileNameJoin[{nbDir, "images", nameStr}]},
                                    If[FileExistsQ[p], p, absImg]
                                ]
                            ],
                            absImg
                        ];
                        anim = If[StringQ[path] && FileExistsQ[path],
                            Pane[Import[path, "AnimatedImage"],
                                 W, Alignment -> Center],
                            Style[
                                "[missing animation: " <> nameStr <> "]",
                                Red]
                        ];
                        If[captionStr === "",
                            anim,
                            Column[{
                                anim,
                                Pane[
                                    Style[captionStr, Italic,
                                          FontSize -> 10,
                                          FontFamily -> "Helvetica"],
                                    W, Alignment -> Center]
                            }, Alignment -> Center, Spacings -> 0.6]]
                    ]
                ]
            ]
        ],
        "Output",
        ShowCellLabel  -> False,
        TextAlignment  -> Center,
        CellMargins    -> {{0, 0}, {10, 14}}
    ]];

(* --- math typesetting helpers ------------------------------------- *)

mathI[box_] := Cell[BoxData[FormBox[box, TraditionalForm]],
    "InlineFormula", FontFamily -> "Times"];

mathD[box_] := Cell[BoxData[FormBox[box, TraditionalForm]],
    "DisplayFormula", TextAlignment -> Center, FontFamily -> "Times"];

(* --- symbolic fragments --- *)

probBJ      = RowBox[{"P", "(", "BJ", ")"}];
handTotal   = RowBox[{"T", SubscriptBox["", "h"]}];
softT       = SubscriptBox["T", "s"];
upcardU     = "u";
Ea          = SubscriptBox["EV", "a"];
Vstar       = SuperscriptBox["V", "*"];
maxAction   = UnderscriptBox["max", "a"];
pi          = "\[Pi]";

probBJEq = RowBox[{
    probBJ, "=",
    RowBox[{"2", "\[CenterDot]",
        FractionBox["4", "52"], "\[CenterDot]",
        FractionBox["16", "51"]}],
    "\[TildeTilde]",
    "0.0483"}];

dealerMarkov = RowBox[{
    RowBox[{"P", "(", SubscriptBox["T", "n + 1"], "\[VerticalSeparator]",
        SubscriptBox["T", "n"], ")"}],
    "=",
    RowBox[{SubscriptBox["p", "card"]}]}];

bellmanEq = RowBox[{
    Vstar, "(", "state", ")", "=",
    maxAction, " ", "\[DoubleStruckCapitalE]", "[",
    RowBox[{SuperscriptBox["V", "*"], "(", "next", ")"}], "\[VerticalSeparator]",
    "action"
    , "]"}];

evStandEq = RowBox[{
    RowBox[{SubscriptBox["EV", "stand"], "(", "T", ",", upcardU, ")"}],
    "=",
    RowBox[{
        UnderoverscriptBox["\[Sum]", "T'", ""], " ",
        RowBox[{"P", "(",
            RowBox[{SubscriptBox["T", "d"], "=", "T'"}],
            "\[VerticalSeparator]", upcardU, ")"}],
        " \[CenterDot] outcome(T, T')"}]}];

houseEdgeEq = RowBox[{
    "house edge", "=", "-",
    RowBox[{"\[DoubleStruckCapitalE]", "[", "return", "]"}],
    "\[TildeTilde]", "0.5", "%"}];

trueCountEq = RowBox[{
    "TC", "=",
    FractionBox["RC", RowBox[{"decks", " ", "remaining"}]]}];

evOfCount = RowBox[{
    "EV", "(", "TC", ")",
    "\[TildeTilde]", "-", "0.5", "%", "+",
    "0.5", "%", "\[CenterDot]", "TC"}];

kellyEq = RowBox[{
    SubscriptBox["f", "*"], "=",
    FractionBox[
        RowBox[{"edge"}],
        RowBox[{"variance"}]]}];

(* --- code snippet helper: Input cell from string --- *)
code[s_String] := Cell[BoxData[s], "Input", ShowCellLabel -> False];

(* --- notebook cells ----------------------------------------------- *)

cells = {

(* ---- Title ---- *)

Cell["Blackjack in the Wolfram Language", "Title"],

Cell["A complete casino game, a basic-strategy coach, and a \
Monte-Carlo expected-value estimator, all in one package.", "Subtitle"],

Cell["Marco Thiel", "Author"],

(* ---- Teaser: representative still from the recording ---- *)

imgCell["blackjack_demo_frame.png",
    "Teaser: still from a recorded session. The full animated \
recording is in images/blackjack_demo.gif (7.4 MB). To watch it \
live inside the notebook, evaluate the cell below."],

Cell[BoxData[
    "AnimatedImage[Import[FileNameJoin[{NotebookDirectory[], \
\"images\", \"blackjack_demo.gif\"}]]]"],
    "Input", ShowCellLabel -> False],

(* ---- Abstract ---- *)

Cell["Abstract", "Section"],

Cell[TextData[{
    "This notebook presents a pure-Wolfram-Language implementation of \
Blackjack. It ships as two packages: ",
    StyleBox["Blackjack`", "Input"],
    " contains the game engine (deck, dealer policy, scoring, payout, \
Hi-Lo counting, a Hit/Stand basic-strategy oracle, and a \
Monte-Carlo EV estimator), and ",
    StyleBox["BlackjackGame`", "Input"],
    " wraps everything in a ",
    StyleBox["DynamicModule", "Input"],
    " front-end with a full casino ruleset \[LongDash] bankroll, \
chip-based betting, 3:2 natural-blackjack payout, double-down, and \
splitting pairs (including the split-aces special case). Beyond the \
playable game, the notebook develops the probability theory of \
Blackjack: the chance of a natural (",
    mathI[probBJ],
    " \[TildeTilde] 4.83%), the dealer's final-total distribution for \
each upcard, the Bellman formulation of the player's decision \
problem, the resulting basic-strategy table, and the Hi-Lo card \
counting system with its linear EV model and the Kelly betting \
criterion. Every figure in the document is produced by the same code \
that powers the game; the game itself can be launched from the cell \
at the end."}],
"Text"],

imgCell["game_overview.png",
    "Figure 1. The Blackjack front-end (screenshot of a \
representative round). Bankroll / bet / last-round badges sit at the \
top; chip buttons adjust the wager; Hit / Stand / Double / Split / \
Deal sit below the hands (each has a single-letter keyboard \
shortcut). The Options / Coach / Shoe & card count / Session \
openers (collapsed here) expose S17/H17, deck-count, basic-strategy \
advice, Monte-Carlo EV, running count, true count, and a cumulative \
bankroll plot."],

(* ---- Section 1: What is Blackjack? ---- *)

Cell["1. What is Blackjack?", "Section"],

Cell[TextData[{
    "Blackjack is a heads-up card game between a player and the \
house (the ",
    StyleBox["dealer", FontSlant -> Italic],
    "). Both parties are dealt two cards from a shared shoe of one or \
more 52-card decks. The player's cards are face up; one of the \
dealer's cards is face-up (the ",
    StyleBox["upcard", FontSlant -> Italic],
    ") and the other is face-down (the ",
    StyleBox["hole card", FontSlant -> Italic],
    "). The goal is to assemble a hand that ",
    StyleBox["beats the dealer's total without exceeding 21", FontWeight -> Bold],
    ". Cards count at face value; J, Q, K count 10; an Ace counts 1 \
or 11, whichever gives a better total."}],
"Text"],

Cell[TextData[{
    "The player acts first, repeatedly choosing one of five \
actions:"}],
"Text"],

Cell[TextData[{
    StyleBox["Hit ", FontWeight -> Bold],
    "take another card;\n",
    StyleBox["Stand ", FontWeight -> Bold],
    "end the player's turn with the current total;\n",
    StyleBox["Double down ", FontWeight -> Bold],
    "double the bet, take exactly one more card, then stand \
automatically;\n",
    StyleBox["Split ", FontWeight -> Bold],
    "when the two initial cards have equal point value, split them \
into two hands with equal bets; split aces receive one more card \
each and cannot be hit further;\n",
    StyleBox["Surrender ", FontWeight -> Bold],
    "(not in this implementation) forfeit half the bet without \
playing."}],
"Text"],

Cell[TextData[{
    "Once the player stands or busts on every hand, the dealer turns \
up the hole card and plays a rigid policy: ",
    StyleBox["hit until the total is at least 17", FontWeight -> Bold],
    ". Casinos differ on whether the dealer also hits a soft 17 \
(\"H17\") or stands on it (\"S17\"); both rules are supported here \
via a checkbox in the ",
    StyleBox["Options", FontSlant -> Italic],
    " opener. A ",
    StyleBox["natural blackjack", FontSlant -> Italic],
    " \[LongDash] an ace plus any ten-valued card on the initial \
deal \[LongDash] pays 3 : 2; other wins pay 1 : 1; equal totals push \
(0); the player loses the bet on any bust regardless of the \
dealer's outcome."}],
"Text"],

(* ---- Section 2: The cards ---- *)

Cell["2. Cards and visual representation", "Section"],

Cell[TextData[{
    "Each card is stored as a plain association with two keys: ",
    StyleBox["\"value\"", "Input"],
    " (one of ",
    StyleBox["\"A\", \"2\", \[Ellipsis], \"10\", \"J\", \"Q\", \"K\"", "Input"],
    ") and ",
    StyleBox["\"suit\"", "Input"],
    " (one of the four Unicode suit glyphs). A fresh shoe is built \
by ",
    StyleBox["CreateShoe[n]", "Input"],
    ", which cross-products ranks and suits ",
    mathI["n"],
    " times and applies ",
    StyleBox["RandomSample", "Input"],
    " for a uniform shuffle. Each face is rendered with pure ",
    StyleBox["Graphics", "Input"],
    " primitives: a white rounded rectangle, rank+suit in the two \
opposite corners, and a per-rank pip layout for 2\[Dash]10, a \
stylised letter for J / Q / K, and one large suit pip for the Ace. \
The back shows a blue crosshatch with a small central medallion."}],
"Text"],

imgCell["cards_showcase.png",
    "Figure 2. The eight rank templates plus the face-down card back. \
Hearts and diamonds render in casino red (#c41e3a); spades and clubs \
in black. Corners carry rank + suit so the card remains readable \
when fanned."],

(* ---- Section 3: Mathematics ---- *)

Cell["3. The mathematics of Blackjack", "Section"],

Cell["3.1 Probability of a natural blackjack", "Subsection"],

Cell[TextData[{
    "From a single freshly-shuffled deck of 52 cards, the \
probability that the player's initial two cards form a natural \
blackjack is"}],
"Text"],

mathD[probBJEq],

Cell[TextData[{
    "(four aces, sixteen ten-valued cards, and the order doesn't \
matter so we multiply by two). Blackjack's 3 : 2 payout on this \
outcome contributes roughly ",
    StyleBox["+2.3%", FontWeight -> Bold],
    " to the player's expected return per hand, which is the single \
largest positive term in the house-edge calculation; take it away \
(some casinos now pay 6 : 5) and the edge roughly doubles against \
the player."}],
"Text"],

Cell["3.2 Dealer bust probability", "Subsection"],

Cell[TextData[{
    "Because the dealer's policy is fixed, the distribution of the \
dealer's final total depends only on the upcard. In the \
infinite-deck approximation (cards drawn with replacement from a \
full rank distribution) the dealer's hand is a Markov chain on \
(hard total, soft?)-pairs, which we can enumerate exactly by \
recursion:"}],
"Text"],

mathD[dealerMarkov],

Cell[TextData[{
    "The probability of finishing ",
    mathI["bust"],
    " from each starting upcard is plotted below. It is roughly \
U-shaped \[LongDash] the dealer is most dangerous showing 7, 8, 9, \
10, or A (where bust probability is ~22\[Dash]25%), and most \
vulnerable showing 4, 5 or 6 (bust probability ~40%). This single \
curve drives almost every asymmetry in basic strategy: the player \
should stand on otherwise-weak totals when the dealer is likely to \
bust, and press the action when the dealer is strong."}],
"Text"],

imgCell["dealer_bust.png",
    "Figure 3. Exact dealer bust probability in the infinite-deck \
S17 model, as a function of the upcard. The valley at 4-5-6 is the \
reason the player stands on a hard 12-16 against those upcards."],

Cell["3.3 Player decisions: the Bellman equation", "Subsection"],

Cell[TextData[{
    "From the player's seat, each state is (hand, bet, dealer \
upcard, remaining deck). The optimal value function satisfies the \
Bellman equation"}],
"Text"],

mathD[bellmanEq],

Cell[TextData[{
    "taken over available actions ",
    mathI[RowBox[{"a", "\[Element]"}]],
    " {Hit, Stand, Double, Split, Surrender}. The Stand branch is \
closed-form once the dealer distribution is known,"}],
"Text"],

mathD[evStandEq],

Cell[TextData[{
    "where ",
    mathI[RowBox[{"outcome", "(", RowBox[{"T", ",", " ", "T'"}], ")"}]],
    " is +1 (win), -1 (loss), or 0 (push). The Hit branch \
recursively invokes ",
    mathI[Vstar],
    " on the post-hit hand; in the finite-deck case the remaining \
deck is smaller by one card, which is what separates the \
correctness of the infinite-deck basic-strategy table from a \
composition-dependent optimum."}],
"Text"],

Cell["3.4 The house edge", "Subsection"],

Cell[TextData[{
    "The house edge is the negative of the optimal player's \
expected return, computed per unit bet over a uniform distribution \
of starting hands:"}],
"Text"],

mathD[houseEdgeEq],

Cell[TextData[{
    "with standard Las Vegas rules (6 decks, S17, 3 : 2 blackjack, \
double-on-anything, split to four hands, late surrender allowed). \
Our implementation omits surrender and caps splits at four hands; \
these restrictions push the edge up to roughly ",
    StyleBox["0.6-0.8%", FontWeight -> Bold],
    " for a perfect player. Notable rule variations:"}],
"Text"],

Cell[TextData[{
    StyleBox["H17 instead of S17: ", FontWeight -> Bold],
    "+0.22% against the player.\n",
    StyleBox["6 : 5 blackjack payout: ", FontWeight -> Bold],
    "+1.39%.\n",
    StyleBox["Single-deck vs six-deck: ", FontWeight -> Bold],
    "~0.4% in the player's favour.\n",
    StyleBox["No double after split: ", FontWeight -> Bold],
    "+0.14%."}],
"Text"],

(* ---- Section 4: Basic strategy ---- *)

Cell["4. Basic strategy", "Section"],

Cell[TextData[{
    "Basic strategy is the action that maximises the Bellman value \
under the infinite-deck assumption, tabulated by (player total, \
dealer upcard). It is the correct play in the absence of any \
information about the shoe composition, and is within ~0.03% of \
perfect composition-dependent play. Because this implementation \
does not expose double/split in the Monte-Carlo EV routine, the \
basic-strategy oracle returns ",
    StyleBox["H", "Input"],
    " or ",
    StyleBox["S", "Input"],
    " only; double and split are still available to the human \
player via the buttons (and the strategy chart shows which 2-card \
starting hands benefit from them)."}],
"Text"],

imgCell["basic_strategy.png",
    "Figure 4. The Hit/Stand basic-strategy chart produced by the \
package's BasicStrategy function. Rows are player totals (hard on \
top, soft on the bottom), columns are dealer upcards. Red = Hit; \
green = Stand. Doubling and splitting entries of the full chart \
collapse to H in this reduced view \[LongDash] e.g. the player's \
11-vs-dealer-6 cell would read \"D\" in a full chart but plays as \
H here when doubling is not permitted."],

Cell[TextData[{
    "Two salient patterns in the chart: (a) the player stands on \
hard 12-16 exactly when the dealer upcard is 4, 5, or 6 (the \
valley in Figure 3); (b) soft 18 is a stand against dealer 2-8 but \
a hit against 9, 10, or A \[LongDash] the strong upcards force the \
player to improve even though 18 is \"normally\" enough."}],
"Text"],

(* ---- Section 5: Monte-Carlo EV ---- *)

Cell["5. Monte-Carlo expected value", "Section"],

Cell[TextData[{
    "For any game state the package can estimate ",
    StyleBox["EV(Hit)", FontSlant -> Italic],
    " and ",
    StyleBox["EV(Stand)", FontSlant -> Italic],
    " by Monte-Carlo simulation. The unseen-card pool is the \
remaining deck plus the dealer's hole card (since the player \
doesn't know it); each trial draws from this pool, plays the \
dealer under the current S17/H17 rule, and \[LongDash] for Hit \
\[LongDash] continues the player under basic strategy after the \
mandatory first extra card. The estimator is exposed as"}],
"Text"],

code["EstimateEV[playerHand, dealerUpcard, \"Hit\" | \"Stand\", \
unseenDeck,\n             \"HitSoft17\" -> False, \"Trials\" -> 600]"],

Cell[TextData[{
    "Rendering ",
    StyleBox["EV(Hit) - EV(Stand)", FontSlant -> Italic],
    " over the player-total / dealer-upcard grid reproduces the \
shape of the basic-strategy chart as a continuous surface:"}],
"Text"],

imgCell["ev_heatmap.png",
    "Figure 5. EV(Hit) - EV(Stand) for hard player totals \
12-20 vs dealer upcards 2-A, 500 Monte-Carlo trials per cell. \
Red (positive) = hitting is strictly better; blue (negative) = \
standing is strictly better. The sharp transition at total 17 \
and the extra band of standing at 12-16 versus dealer 2-6 \
coincide with the discrete H/S boundaries in Figure 4."],

(* ---- Section 6: Card counting ---- *)

Cell["6. Card counting", "Section"],

Cell[TextData[{
    "Basic strategy assumes every card in the shoe is equally \
likely to be the next drawn. As a real shoe is played out, that \
assumption degrades: the composition at the bottom of a six-deck \
shoe can look very different from a fresh shuffle. A ",
    StyleBox["card-counting system", FontSlant -> Italic],
    " tracks a scalar running count that correlates with the \
player's edge. The simplest and most widespread system is ",
    StyleBox["Hi-Lo", FontWeight -> Bold],
    ", which assigns +1 to low cards (2-6), 0 to neutral cards \
(7-9), and -1 to high cards (10, J, Q, K, A). When many high \
cards remain, the dealer is more likely to bust (Figure 3) and \
the player is more likely to draw a natural \[LongDash] both in \
the player's favour."}],
"Text"],

Cell[TextData[{
    "The running count RC is converted to a ",
    StyleBox["true count", FontSlant -> Italic],
    " TC by dividing by the number of decks remaining in the shoe,"}],
"Text"],

mathD[trueCountEq],

Cell[TextData[{
    "which normalises the edge signal across different shoe \
penetrations. The player's expected return is close to affine in \
TC,"}],
"Text"],

mathD[evOfCount],

Cell[TextData[{
    "for typical six-deck rules (the slope ~0.5% per true count is \
an empirical regression coefficient). A classical counting bettor \
sizes the wager proportionally to the edge via the Kelly criterion,"}],
"Text"],

mathD[kellyEq],

Cell[TextData[{
    "capped at a practical table maximum. The game displays the \
live running and true counts in the ",
    StyleBox["Shoe & card count", FontSlant -> Italic],
    " opener, and the cumulative bankroll over all rounds in the \
",
    StyleBox["Session", FontSlant -> Italic],
    " plot \[LongDash] so a curious player can watch their edge \
swing with the count over a sufficiently long session."}],
"Text"],

(* ---- Section 7: The package ---- *)

Cell["7. Package architecture", "Section"],

Cell[TextData[{
    "The code is split into two paclet-style files:"}],
"Text"],

Cell[TextData[{
    StyleBox["Blackjack.wl", FontWeight -> Bold],
    " \[LongDash] pure game logic, no UI. Exposes ",
    StyleBox["Suits", "Input"], ", ",
    StyleBox["Ranks", "Input"], ", ",
    StyleBox["MakeCard", "Input"], ", ",
    StyleBox["CreateShoe", "Input"], ", ",
    StyleBox["DrawCard", "Input"], ", ",
    StyleBox["HandScore", "Input"], ", ",
    StyleBox["IsSoft", "Input"], ", ",
    StyleBox["IsBlackjack", "Input"], ", ",
    StyleBox["IsBust", "Input"], ", ",
    StyleBox["DealerShouldHit", "Input"], ", ",
    StyleBox["PlayDealer", "Input"], ", ",
    StyleBox["ResolveRound", "Input"], ", ",
    StyleBox["Payout", "Input"], ", ",
    StyleBox["CanDouble", "Input"], ", ",
    StyleBox["CanSplit", "Input"], ", ",
    StyleBox["HiLoValue", "Input"], ", ",
    StyleBox["TrueCount", "Input"], ", ",
    StyleBox["BasicStrategy", "Input"], ", ",
    StyleBox["EstimateEV", "Input"], "."
}], "Text"],

Cell[TextData[{
    StyleBox["BlackjackGame.wl", FontWeight -> Bold],
    " \[LongDash] the ",
    StyleBox["DynamicModule", "Input"],
    " front-end. Holds all reactive state (deck, multi-hand \
player, dealer hand, bankroll, bet, session history, running \
count, coach cache), all handlers (",
    StyleBox["doHit", "Input"], ", ",
    StyleBox["doStand", "Input"], ", ",
    StyleBox["doDouble", "Input"], ", ",
    StyleBox["doSplit", "Input"], ", ",
    StyleBox["startRound", "Input"], ", ",
    StyleBox["advanceHand", "Input"], ", ",
    StyleBox["playoutDealerAndSettle", "Input"],
    "), and all widgets (cards, badges, chip buttons, openers, \
session plot)."}],
"Text"],

Cell[TextData[{
    "The only non-obvious idiom is that all handler functions are \
declared in the ",
    StyleBox["DynamicModule", "Input"],
    "'s local-variables list. That puts their ",
    StyleBox["DownValues", "Input"],
    " in the same persistent dynamic context as the state symbols \
they mutate; otherwise Button actions silently no-op after the \
first click because the front-end holds stale references to \
temporary ",
    StyleBox["Module", "Input"],
    " symbols that have been garbage-collected."}],
"Text"],

(* ---- Section 8: Play ---- *)

Cell["8. Play the game", "Section"],

Cell[TextData[{
    "A still from a recorded session is shown below; the full \
animated recording (",
    StyleBox["images/blackjack_demo.gif", "Input"],
    ", 7.4 MB) can be opened in any image viewer, or played inside \
the notebook by evaluating the following cell."}],
"Text"],

imgCell["blackjack_demo_frame.png",
    "A representative frame: adjusting the bet with the chip \
buttons, a dealt round, and the coach / counting / session panels \
(collapsed) below the controls."],

Cell[BoxData[
    "AnimatedImage[Import[FileNameJoin[{NotebookDirectory[], \
\"images\", \"blackjack_demo.gif\"}]]]"],
    "Input", ShowCellLabel -> False],

Cell[TextData[{
    "The notebook loads the two packages from the parent directory \
of its own folder (that is, the directory containing ",
    StyleBox["Blackjack.wl", "Input"],
    " and ",
    StyleBox["BlackjackGame.wl", "Input"],
    "). Evaluate the cell below; a live playable game will appear \
underneath."}],
"Text"],

Cell[BoxData[
    "SetDirectory[NotebookDirectory[]];\n\
packDir = ParentDirectory[NotebookDirectory[]];\n\
Get[FileNameJoin[{packDir, \"Blackjack.wl\"}]];\n\
Get[FileNameJoin[{packDir, \"BlackjackGame.wl\"}]];"],
    "Input", CellLabel -> "In[1]:="],

Cell[BoxData["Pane[BlackjackGame[], Scaled[1], Alignment -> Center]"],
    "Input", CellLabel -> "In[2]:="],

Cell[TextData[{
    StyleBox["How to play:", FontWeight -> Bold], "\n",
    "\[Bullet] Adjust the bet using the ",
    StyleBox["$5 / $25 / $100", FontWeight -> Bold],
    " chip buttons, or ",
    StyleBox["Clear", FontWeight -> Bold], " / ",
    StyleBox["All in", FontWeight -> Bold], ".\n",
    "\[Bullet] Click ",
    StyleBox["Deal", FontWeight -> Bold],
    " (or press N) to start a round. The dealer shows one card; \
the other is face-down until you stand.\n",
    "\[Bullet] On your hand, choose one of:\n",
    "    ",
    StyleBox["Hit (H)", FontWeight -> Bold], " \[LongDash] \
take another card;\n",
    "    ",
    StyleBox["Stand (S)", FontWeight -> Bold], " \[LongDash] end \
your turn;\n",
    "    ",
    StyleBox["Double (D)", FontWeight -> Bold], " \[LongDash] \
available on the first two cards; doubles the bet and deals one \
card;\n",
    "    ",
    StyleBox["Split (P)", FontWeight -> Bold], " \[LongDash] \
available on any pair of equal-value cards; creates a sister hand \
with an equal bet.\n",
    "\[Bullet] When every hand has stood or busted, the dealer \
plays and the round settles. A natural blackjack pays 3 : 2; any \
other win pays 1 : 1; push returns the bet; bust or loss forfeits \
the bet.\n",
    "\[Bullet] The ",
    StyleBox["Options", FontSlant -> Italic],
    " opener lets you toggle H17 / S17, set the number of decks \
(1 / 2 / 4 / 6 / 8), adjust the cut-card penetration and the \
dealer-draw animation speed.\n",
    "\[Bullet] Open ",
    StyleBox["Coach", FontSlant -> Italic],
    " to see the basic-strategy recommendation and request a \
Monte-Carlo EV estimate for the current state.\n",
    "\[Bullet] Open ",
    StyleBox["Shoe & card count", FontSlant -> Italic],
    " for the live Hi-Lo running / true count.\n",
    "\[Bullet] Open ",
    StyleBox["Session", FontSlant -> Italic],
    " for a cumulative bankroll plot."}],
"Text"],

(* ---- Section 9: Standalone ---- *)

Cell["9. Standalone use (without the notebook)", "Section"],

Cell[TextData[{
    "The game runs equally well outside this notebook, in any \
Wolfram Front End that supports ",
    StyleBox["DynamicModule", "Input"],
    ". Clone the repository (or just download the two ",
    StyleBox[".wl", "Input"],
    " files from the ",
    StyleBox["Wolfram/", "Input"],
    " folder) and evaluate:"}],
"Text"],

Cell[BoxData[
    "Get[\"/path/to/Blackjack.wl\"]\n\
Get[\"/path/to/BlackjackGame.wl\"]\n\
BlackjackGame[]"],
    "Input", ShowCellLabel -> False],

Cell[TextData[{
    "Or, from a shell (requires ",
    StyleBox["wolframscript", "Input"],
    " and a Wolfram Front End):"}],
"Text"],

Cell[BoxData[
    "wolframscript -file /path/to/BlackjackGame.wl"],
    "Program"],

Cell[TextData[{
    "which opens a notebook window with the game embedded. The ",
    StyleBox["tests.wls", "Input"],
    " file in the same folder runs a 66-assertion suite covering \
deck construction, ace-aware scoring (including a permutation-\
invariance property), bust/blackjack/soft predicates, S17 and H17 \
dealer policy, ",
    StyleBox["PlayDealer", "Input"],
    " termination (random trials), round resolution, double/split \
eligibility, payout math, Hi-Lo count, basic-strategy spot checks, \
and Monte-Carlo EV ordering on two known positions."}],
"Text"],

(* ---- Section 10: References ---- *)

Cell["10. References", "Section"],

Cell[TextData[{
    "\[Bullet] E. Thorp, ",
    StyleBox["Beat the Dealer", FontSlant -> Italic],
    ", Vintage, 1966. The original card-counting book; introduced \
the first ten-count system.\n",
    "\[Bullet] R. Baldwin, W. Cantey, H. Maisel & J. McDermott, \
\"The Optimum Strategy in Blackjack\", ",
    StyleBox["Journal of the American Statistical Association",
             FontSlant -> Italic],
    " ",
    StyleBox["51", FontWeight -> Bold],
    "(275), 429-439 (1956). The basic-strategy table, derived by \
hand at Aberdeen Proving Ground.\n",
    "\[Bullet] P. Griffin, ",
    StyleBox["The Theory of Blackjack", FontSlant -> Italic],
    ", Huntington Press, 6th ed., 1999. The canonical modern \
reference on rule variations and composition-dependent strategy.\n",
    "\[Bullet] J. L. Kelly, \"A New Interpretation of Information \
Rate\", ",
    StyleBox["Bell System Technical Journal", FontSlant -> Italic],
    " ",
    StyleBox["35", FontWeight -> Bold],
    "(4), 917-926 (1956). Optimal betting under a known edge.\n",
    "\[Bullet] Repository (source, tests, math write-up, HTML twin): ",
    ButtonBox["github.com/mthiel74/blackjack",
        BaseStyle  -> "Hyperlink",
        ButtonData -> {URL["https://github.com/mthiel74/blackjack"], None}],
    "."}],
"Text"]

};

nb = Notebook[cells,
    WindowSize    -> {1100, 800},
    WindowMargins -> {{Automatic, 0}, {Automatic, 0}},
    (* Center all Output cells (figures + the live BlackjackGame[] cell) so
       images and interactive elements sit mid-page, while keeping code and
       text cells at their default alignment.                              *)
    StyleDefinitions -> Notebook[{
        Cell[StyleData[StyleDefinitions -> "Default.nb"]],
        Cell[StyleData["Output"],        TextAlignment -> Center],
        Cell[StyleData["Graphics"],      TextAlignment -> Center],
        Cell[StyleData["DisplayFormula"], TextAlignment -> Center]
    }],
    Saveable -> True];

outNb  = FileNameJoin[{hereDir, "blackjack.nb"}];
outPdf = FileNameJoin[{hereDir, "blackjack.pdf"}];

Print["writing notebook -> ", outNb];
Export[outNb, nb];

Print["writing pdf      -> ", outPdf];
Export[outPdf, nb];

Print["done; nb=", FileByteCount[outNb], "  pdf=", FileByteCount[outPdf]];
