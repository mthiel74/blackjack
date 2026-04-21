#!/usr/bin/env wolframscript
(* Produce the PNG figures referenced by build_notebook.wls.
   Run with:  wolframscript -file generate_images.wls                       *)

hereDir   = DirectoryName[If[$ScriptCommandLine =!= {}, $InputFileName,
                              NotebookFileName[]]];
packDir   = FileNameJoin[{hereDir, ".."}];
imgDir    = FileNameJoin[{hereDir, "images"}];
If[!DirectoryQ[imgDir], CreateDirectory[imgDir]];

Print["loading core package..."];
Get[FileNameJoin[{packDir, "Blackjack.wl"}]];
Get[FileNameJoin[{packDir, "BlackjackGame.wl"}]];

(* --------------------------------------------------------------------
   Helpers
   -------------------------------------------------------------------- *)

felt    = RGBColor["#1a472a"];
feltMid = RGBColor["#2d5a3f"];
gold    = RGBColor["#ffd700"];
red     = RGBColor["#c41e3a"];

mk[v_, s_] := Blackjack`MakeCard[v, s];

exportPng[name_, expr_, opts___] := Module[{path, img},
    path = FileNameJoin[{imgDir, name}];
    img  = Rasterize[expr, ImageResolution -> 144, opts];
    Export[path, img];
    Print["  wrote ", path, "  (", FileByteCount[path], " bytes)"];
];

(* --------------------------------------------------------------------
   1. Game overview: a static mockup using the same visual primitives
       as the live DynamicModule (rasterising the DynamicModule itself
       in headless mode leaves Dynamic[...] unevaluated).
   -------------------------------------------------------------------- *)
Print["figure: game_overview.png"];

cardGfx      = Global`BlackjackGamePrivate`cardGraphic;
hiddenGfx    = Global`BlackjackGamePrivate`hiddenCardGraphic;
labelBadgeS  = Global`BlackjackGamePrivate`labelBadge;
statBadgeS   = Global`BlackjackGamePrivate`statBadge;
infoBadgeS   = Global`BlackjackGamePrivate`infoBadge;
panelBg      = Global`BlackjackGamePrivate`$panelBg;
badgeBg      = Global`BlackjackGamePrivate`$badgeBg;

(* demo hands *)
dealerDemo = {mk["10", "\[HeartSuit]"], mk["7", "\[SpadeSuit]"]};
playerDemo = {mk["K", "\[DiamondSuit]"], mk["6", "\[SpadeSuit]"]};

btn[label_, bg_, fg_, w_:110] := Framed[
    Style[label, Bold, 13, fg],
    Background -> bg, FrameStyle -> None,
    RoundingRadius -> 6, FrameMargins -> {{0, 0}, {10, 10}},
    ImageSize -> {w, 40}, Alignment -> Center];

chipBtn[label_, bg_] := btn[label, bg, White, 58];

staticGame = Framed[
    Column[{
        Style["\[SpadeSuit] Blackjack \[HeartSuit]", Bold, 32, gold,
              FontFamily -> "Helvetica"],
        Spacer[{0, 6}],

        Framed[Row[{
            infoBadgeS["Bankroll", "$1000.00", RGBColor["#4CAF50"]],
            Spacer[12],
            infoBadgeS["Bet",      "$25.00",   gold],
            Spacer[12],
            infoBadgeS["Last round", "+$37.50", RGBColor["#4CAF50"]]
        }],
        Background -> panelBg, FrameStyle -> None,
        RoundingRadius -> 10, FrameMargins -> 10],

        Spacer[{0, 8}],

        Row[{chipBtn["$5", red], Spacer[6],
             chipBtn["$25", RGBColor["#4CAF50"]], Spacer[6],
             chipBtn["$100", RGBColor["#111111"]], Spacer[14],
             btn["Clear", GrayLevel[0.3], White, 70], Spacer[6],
             btn["All in", GrayLevel[0.3], White, 70]}],

        Spacer[{0, 14}],

        labelBadgeS["Dealer's Hand", "10 + ?"],
        Framed[Row[{cardGfx[dealerDemo[[1]]], Spacer[6], hiddenGfx[]},
                   Spacer[6]],
            Background -> panelBg, FrameStyle -> None,
            RoundingRadius -> 10, FrameMargins -> 10,
            ImageSize -> {All, 138}],

        Spacer[{0, 12}],

        labelBadgeS["Your Hand", 16],
        Framed[Row[{cardGfx[playerDemo[[1]]], Spacer[6],
                    cardGfx[playerDemo[[2]]]}, Spacer[6]],
            Background -> panelBg, FrameStyle -> None,
            RoundingRadius -> 10, FrameMargins -> 10,
            ImageSize -> {All, 138}],

        Spacer[{0, 12}],

        Row[{btn["Hit  (H)",    RGBColor["#4CAF50"], White],
             Spacer[8],
             btn["Stand  (S)",  red, White],
             Spacer[8],
             btn["Double  (D)", RGBColor["#ff8c00"], White],
             Spacer[8],
             btn["Split  (P)",  RGBColor["#8a2be2"], White],
             Spacer[8],
             btn["Deal  (N)",   gold, Black]}],

        Spacer[{0, 14}],

        Row[{statBadgeS["Wins",   12], Spacer[10],
             statBadgeS["Losses",  8], Spacer[10],
             statBadgeS["Pushes",  2]}]

    }, Alignment -> Center, Spacings -> 0.5],
    Background     -> felt,
    FrameStyle     -> Directive[feltMid, Thickness[2]],
    RoundingRadius -> 20,
    FrameMargins   -> 25,
    ImageSize      -> 720
];

UsingFrontEnd[
    exportPng["game_overview.png", staticGame]
];

(* --------------------------------------------------------------------
   2. Card-graphics showcase (pip layouts + face cards + hidden back)
   -------------------------------------------------------------------- *)
Print["figure: cards_showcase.png"];
showcaseCards = {
    mk["A",  "\[SpadeSuit]"],   mk["2",  "\[HeartSuit]"],
    mk["5",  "\[DiamondSuit]"], mk["7",  "\[ClubSuit]"],
    mk["10", "\[SpadeSuit]"],   mk["J",  "\[HeartSuit]"],
    mk["Q",  "\[DiamondSuit]"], mk["K",  "\[ClubSuit]"]
};

UsingFrontEnd[
    exportPng["cards_showcase.png",
        Framed[
            Grid[
                Partition[
                    Append[
                        Global`BlackjackGamePrivate`cardGraphic /@ showcaseCards,
                        Global`BlackjackGamePrivate`hiddenCardGraphic[]
                    ],
                    3
                ],
                Spacings -> {1, 1},
                Alignment -> Center
            ],
            Background     -> felt,
            FrameStyle     -> Directive[feltMid, Thickness[2]],
            RoundingRadius -> 15,
            FrameMargins   -> 25
        ]
    ]
];

(* --------------------------------------------------------------------
   3. Dealer final-total distribution for each upcard
       (classic Markov / exact computation over the infinite-deck model
        with replacement; faithful to the standard table.)
   -------------------------------------------------------------------- *)

(* Infinite-deck rank probabilities *)
rankProbs = <|
    2 -> 1/13, 3 -> 1/13, 4 -> 1/13, 5 -> 1/13, 6 -> 1/13,
    7 -> 1/13, 8 -> 1/13, 9 -> 1/13,
    10 -> 4/13, 11 -> 1/13
|>;

(* dealerDist[{soft?, total}] -> Assoc of {finalTotal -> prob}.
   Dealer stands on all 17s (S17).                                    *)
dealerDist[hand_] := dealerDist[hand] = Module[
    {soft, total, outAssoc},
    {soft, total} = hand;
    If[total >= 17 || total > 21,
        Return[<|If[total > 21, "bust", total] -> 1|>]
    ];
    outAssoc = <||>;
    KeyValueMap[
        Function[{r, p},
            Module[{newTotal, newSoft, branch},
                newTotal = total + r;
                newSoft  = soft || r == 11;
                If[newTotal > 21 && newSoft,
                    newTotal -= 10;
                    newSoft   = False;
                ];
                branch = dealerDist[{newSoft, newTotal}];
                KeyValueMap[
                    (outAssoc[#1] = Lookup[outAssoc, #1, 0] + p * #2) &,
                    branch
                ]
            ]
        ],
        rankProbs
    ];
    outAssoc
];

upcardRanks = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
upcardLbl = <|
    2 -> "2", 3 -> "3", 4 -> "4", 5 -> "5", 6 -> "6",
    7 -> "7", 8 -> "8", 9 -> "9", 10 -> "10", 11 -> "A"
|>;

(* Start with just the upcard known; the hole card averages over all ranks. *)
dealerFromUpcard[u_] := Module[{d = <||>},
    KeyValueMap[
        Function[{h, ph},
            Module[{total = u + h, soft = (u == 11 || h == 11), branch},
                If[total > 21 && soft, total -= 10; soft = False];
                branch = dealerDist[{soft, total}];
                KeyValueMap[(d[#1] = Lookup[d, #1, 0] + ph * #2) &, branch];
            ]
        ],
        rankProbs
    ];
    d
];

distTable = AssociationMap[dealerFromUpcard, upcardRanks];

(* Probability of bust per upcard *)
bustProbs = Lookup[#, "bust", 0] & /@ distTable;

Print["figure: dealer_bust.png"];
UsingFrontEnd[
    exportPng["dealer_bust.png",
        BarChart[
            AssociationMap[N[bustProbs[#], 4] &, upcardRanks],
            ChartLabels -> (upcardLbl[#] & /@ upcardRanks),
            ChartStyle  -> Directive[EdgeForm[White], red],
            Frame       -> True,
            FrameStyle  -> Directive[GrayLevel[0.3]],
            FrameLabel  -> {"dealer upcard",
                            Rotate["P(dealer busts)", Pi/2]},
            LabelStyle  -> {FontSize -> 14, FontFamily -> "Helvetica"},
            PlotRangePadding -> {Automatic, {0, 0.05}},
            ImageSize   -> 650,
            PlotLabel   -> Style["Dealer bust probability by upcard (S17, \[Infinity]-deck)",
                                 Bold, 15]
        ]
    ]
];

(* --------------------------------------------------------------------
   4. Basic strategy chart as an image (Hit/Stand only)
   -------------------------------------------------------------------- *)
Print["figure: basic_strategy.png"];

(* Build a matrix of H/S for each (player total, dealer upcard).
   Use rows = player totals {5..20} for hard totals and {13..20}
   for soft totals, cols = upcards {2..10,A}.                        *)

playerUpcards = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
upcardCards   = mk[upcardLbl[#], "\[SpadeSuit]"] & /@ playerUpcards;

hardTotals = Range[8, 20];
softTotals = Range[13, 20]; (* A2 .. A9 *)

(* Dummy hands for strategy lookup *)
hardHand[t_] := Switch[t,
    8,  {mk["3","\[SpadeSuit]"], mk["5","\[HeartSuit]"]},
    9,  {mk["4","\[SpadeSuit]"], mk["5","\[HeartSuit]"]},
    10, {mk["4","\[SpadeSuit]"], mk["6","\[HeartSuit]"]},
    11, {mk["5","\[SpadeSuit]"], mk["6","\[HeartSuit]"]},
    12, {mk["4","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    13, {mk["5","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    14, {mk["6","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    15, {mk["7","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    16, {mk["8","\[SpadeSuit]"], mk["8","\[HeartSuit]"]}, (* 8+8 is split but we test as hard *)
    17, {mk["9","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    18, {mk["10","\[SpadeSuit]"], mk["8","\[HeartSuit]"]},
    19, {mk["10","\[SpadeSuit]"], mk["9","\[HeartSuit]"]},
    20, {mk["10","\[SpadeSuit]"], mk["10","\[HeartSuit]"]}
];
softHand[t_] := {mk["A","\[SpadeSuit]"], mk[ToString[t - 11], "\[HeartSuit]"]};

decision[hand_, up_] :=
    Blackjack`BasicStrategy[hand, mk[upcardLbl[up], "\[SpadeSuit]"]];

cellColor["H"] := RGBColor["#e25252"];
cellColor["S"] := RGBColor["#5aa87b"];
cellColor[_]   := GrayLevel[0.9];

cellBox[txt_, col_] :=
    Graphics[{
        col, Rectangle[{0, 0}, {1, 1}],
        White, Text[Style[txt, Bold, 16, FontFamily -> "Helvetica"],
                    {0.5, 0.5}]
    }, ImageSize -> 40, PlotRange -> {{0, 1}, {0, 1}},
       AspectRatio -> 1];

headerBox[t_, bg_:GrayLevel[0.2]] :=
    Graphics[{
        bg, Rectangle[{0, 0}, {1, 1}],
        White, Text[Style[t, Bold, 14, FontFamily -> "Helvetica"],
                    {0.5, 0.5}]
    }, ImageSize -> 40, PlotRange -> {{0, 1}, {0, 1}},
       AspectRatio -> 1];

labelBox[t_] :=
    Graphics[{
        GrayLevel[0.15], Rectangle[{0, 0}, {1, 1}],
        gold, Text[Style[t, Bold, 13, FontFamily -> "Helvetica"],
                    {0.5, 0.5}]
    }, ImageSize -> {60, 40}, PlotRange -> {{0, 1}, {0, 1}}];

hardGrid = Prepend[
    Table[
        Prepend[
            Table[cellBox[decision[hardHand[t], u], cellColor[decision[hardHand[t], u]]],
                  {u, playerUpcards}],
            labelBox["Hard " <> ToString[t]]
        ],
        {t, hardTotals}
    ],
    Prepend[headerBox[upcardLbl[#]] & /@ playerUpcards,
            labelBox["player \\ up"]]
];

softGrid = Prepend[
    Table[
        Prepend[
            Table[cellBox[decision[softHand[t], u], cellColor[decision[softHand[t], u]]],
                  {u, playerUpcards}],
            labelBox["Soft " <> ToString[t] <> " (A" <>
                    ToString[t - 11] <> ")"]
        ],
        {t, softTotals}
    ],
    Prepend[headerBox[upcardLbl[#]] & /@ playerUpcards,
            labelBox["player \\ up"]]
];

chart = Column[{
    Style["Basic strategy (Hit / Stand only)", Bold, 20, FontFamily -> "Helvetica"],
    Spacer[{0, 12}],
    Style["Hard totals", Bold, 15, FontFamily -> "Helvetica"],
    Grid[hardGrid, Spacings -> {0.1, 0.1}, Alignment -> Center],
    Spacer[{0, 16}],
    Style["Soft totals", Bold, 15, FontFamily -> "Helvetica"],
    Grid[softGrid, Spacings -> {0.1, 0.1}, Alignment -> Center],
    Spacer[{0, 10}],
    Row[{
        Graphics[{cellColor["H"], Rectangle[{0,0},{1,1}]},
                 ImageSize -> 16, AspectRatio -> 1],
        Style["  Hit    ", 12, FontFamily -> "Helvetica"],
        Graphics[{cellColor["S"], Rectangle[{0,0},{1,1}]},
                 ImageSize -> 16, AspectRatio -> 1],
        Style["  Stand", 12, FontFamily -> "Helvetica"]
    }]
}, Alignment -> Center];

UsingFrontEnd[
    exportPng["basic_strategy.png",
        Framed[chart, Background -> White, FrameStyle -> GrayLevel[0.5],
               FrameMargins -> 20]
    ]
];

(* --------------------------------------------------------------------
   5. House-edge heatmap: EV(stand) - EV(hit) for each (total, upcard)
   -------------------------------------------------------------------- *)
Print["figure: ev_heatmap.png  (this runs Monte-Carlo, ~30 s)"];

(* Use the package's EstimateEV for a qualitative view; 500 trials
   is enough for a heatmap. *)

unseenShoe = Blackjack`CreateShoe[6];

hitMinusStand[t_, up_, soft_] := Module[
    {hand, upCard, unseen, eh, es},
    hand   = If[soft, softHand[t], hardHand[t]];
    upCard = mk[upcardLbl[up], "\[SpadeSuit]"];
    unseen = Fold[
        Function[{L, c}, With[{pos = FirstPosition[L, c, Missing[]]},
            If[MissingQ[pos], L, Delete[L, First[pos]]]]],
        unseenShoe, Append[hand, upCard]];
    eh = Blackjack`EstimateEV[hand, upCard, "Hit",   unseen, "Trials" -> 500];
    es = Blackjack`EstimateEV[hand, upCard, "Stand", unseen, "Trials" -> 500];
    eh - es
];

hardMatrix = Table[
    hitMinusStand[t, up, False],
    {t, {12, 13, 14, 15, 16, 17, 18, 19, 20}},
    {up, playerUpcards}
];

UsingFrontEnd[
    exportPng["ev_heatmap.png",
        Labeled[
            MatrixPlot[hardMatrix,
                ColorFunction -> "TemperatureMap",
                FrameTicks -> {
                    {Table[{i, ToString[{12,13,14,15,16,17,18,19,20}[[i]]]},
                        {i, 9}], None},
                    {Table[{i, upcardLbl[playerUpcards[[i]]]},
                        {i, Length[playerUpcards]}], None}
                },
                PlotLegends -> Automatic,
                ImageSize -> 600,
                PlotLabel -> Style[
                    "EV(Hit) - EV(Stand)   (red: hit; blue: stand)",
                    Bold, 14]
            ],
            {"hard total", "dealer upcard"},
            {Left, Bottom}
        ]
    ]
];

Print[""];
Print["done — ", Length @ FileNames["*.png", imgDir], " PNG(s) in ", imgDir];
