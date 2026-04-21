(* ::Package:: *)

(* ::Title:: *)
(*Blackjack - Interactive GUI*)

(* ::Text:: *)
(*A DynamicModule front end for the Blackjack` core package.*)
(**)
(*Features:*)
(*  - Hit / Stand / New Game with keyboard shortcuts H / S / N*)
(*  - Animated dealer draw (visible card-by-card reveal)*)
(*  - Configurable dealer rule (S17 vs H17)*)
(*  - Multi-deck shoe (1 / 2 / 4 / 6 / 8) with cut-card reshuffle*)
(*  - Session statistics with reset*)
(*  - Basic-strategy hint*)
(*  - Monte-Carlo expected-value estimate for Hit vs Stand*)
(*  - Hi-Lo running count and true count*)
(*  - Cumulative session plot*)
(**)
(*Usage (notebook):*)
(*    Get["BlackjackGame.wl"]*)
(*    BlackjackGame[]*)

Get[FileNameJoin[{DirectoryName[$InputFileName], "Blackjack.wl"}]];

BlackjackGame::usage =
    "BlackjackGame[] returns a DynamicModule that plays Blackjack interactively.";

Begin["`BlackjackGamePrivate`"];

(* --- palette ------------------------------------------------------------- *)

$felt       = RGBColor["#1a472a"];
$feltMid    = RGBColor["#2d5a3f"];
$panelBg    = RGBColor["#0d2818"]; (* darker than felt for inner containers *)
$badgeBg    = RGBColor["#16391f"]; (* slightly lifted for small badges    *)
$gold       = RGBColor["#ffd700"];
$cardBack1  = RGBColor["#1a3a8a"];
$cardBack2  = RGBColor["#2a4a9a"];
$redSuit    = RGBColor["#c41e3a"];
$winColor   = RGBColor["#4CAF50"];
$loseColor  = RGBColor["#f44336"];
$pushColor  = RGBColor["#2196F3"];
$infoColor  = RGBColor["#e0e0e0"];

(* --- card graphics ------------------------------------------------------- *)

(* Pip positions in normalized card coordinates {0..1, 0..1.5} for the
   non-corner face region. Layouts follow the standard playing-card
   conventions (Bicycle / casino decks).                                *)
$pipPositions = <|
    "2"  -> {{0.5, 1.15}, {0.5, 0.35}},
    "3"  -> {{0.5, 1.15}, {0.5, 0.75}, {0.5, 0.35}},
    "4"  -> {{0.3, 1.10}, {0.7, 1.10}, {0.3, 0.40}, {0.7, 0.40}},
    "5"  -> {{0.3, 1.10}, {0.7, 1.10}, {0.5, 0.75}, {0.3, 0.40}, {0.7, 0.40}},
    "6"  -> {{0.3, 1.15}, {0.7, 1.15}, {0.3, 0.75}, {0.7, 0.75},
             {0.3, 0.35}, {0.7, 0.35}},
    "7"  -> {{0.3, 1.15}, {0.7, 1.15}, {0.5, 0.95},
             {0.3, 0.75}, {0.7, 0.75}, {0.3, 0.35}, {0.7, 0.35}},
    "8"  -> {{0.3, 1.18}, {0.7, 1.18}, {0.5, 0.98},
             {0.3, 0.75}, {0.7, 0.75}, {0.5, 0.53},
             {0.3, 0.32}, {0.7, 0.32}},
    "9"  -> {{0.3, 1.18}, {0.7, 1.18}, {0.3, 0.95}, {0.7, 0.95},
             {0.5, 0.75},
             {0.3, 0.55}, {0.7, 0.55}, {0.3, 0.32}, {0.7, 0.32}},
    "10" -> {{0.3, 1.20}, {0.7, 1.20}, {0.5, 1.02},
             {0.3, 0.88}, {0.7, 0.88}, {0.3, 0.62}, {0.7, 0.62},
             {0.5, 0.48}, {0.3, 0.30}, {0.7, 0.30}}
|>;

(* Size constants tuned for ImageSize -> {65, 98}.                      *)
$cornerRankSize = 11;
$cornerSuitSize = 10;
$pipFontSize    = 12;
$aceFontSize    = 34;
$faceRankSize   = 28;
$faceSuitSize   = 15;

cardFaceLayout[rank_String, suit_String, col_] :=
    Which[
        rank === "A",
            {col,
             Text[Style[suit,
                        FontSize   -> $aceFontSize,
                        FontWeight -> Bold],
                  {0.5, 0.75}]},
        MemberQ[{"J", "Q", "K"}, rank],
            {(* soft suit tinge behind the letter *)
             Lighter[col, 0.7],
             Rectangle[{0.2, 0.28}, {0.8, 1.22}, RoundingRadius -> 0.05],
             col,
             (* big ornate letter *)
             Text[Style[rank,
                        FontWeight -> Bold,
                        FontSize   -> $faceRankSize,
                        FontFamily -> "Times"],
                  {0.5, 0.82}],
             (* small suit below *)
             Text[Style[suit,
                        FontWeight -> Bold,
                        FontSize   -> $faceSuitSize],
                  {0.5, 0.50}]},
        True,
            {col,
             Sequence @@ (
                 Text[Style[suit,
                            FontWeight -> Bold,
                            FontSize   -> $pipFontSize], #] & /@
                 $pipPositions[rank]
             )}
    ];

cardGraphic[card_Association] :=
    Module[{rank, suit, col},
        rank = card["value"];
        suit = card["suit"];
        col  = If[IsRedSuit[card], $redSuit, Black];
        Graphics[
            {
                (* card paper *)
                EdgeForm[Directive[GrayLevel[0.35], Thickness[0.005]]],
                FaceForm[White],
                Rectangle[{0, 0}, {1, 1.5}, RoundingRadius -> 0.08],

                (* top-left rank + suit *)
                col,
                Text[Style[rank,
                           FontWeight -> Bold,
                           FontSize   -> $cornerRankSize], {0.14, 1.40}],
                Text[Style[suit,
                           FontSize   -> $cornerSuitSize], {0.14, 1.25}],

                (* bottom-right rank + suit (rotated 180) *)
                Rotate[Text[Style[rank,
                                  FontWeight -> Bold,
                                  FontSize   -> $cornerRankSize], {0.86, 0.10}],
                       Pi, {0.86, 0.10}],
                Rotate[Text[Style[suit,
                                  FontSize   -> $cornerSuitSize], {0.86, 0.25}],
                       Pi, {0.86, 0.25}],

                (* face *)
                cardFaceLayout[rank, suit, col]
            },
            ImageSize   -> {65, 98},
            PlotRange   -> {{0, 1}, {0, 1.5}},
            AspectRatio -> 1.5
        ]
    ];

hiddenCardGraphic[] :=
    Graphics[
        {
            EdgeForm[Directive[GrayLevel[0.35], Thickness[0.005]]],
            FaceForm[LinearGradientFilling[{$cardBack1, $cardBack2, $cardBack1}]],
            Rectangle[{0, 0}, {1, 1.5}, RoundingRadius -> 0.08],

            (* crosshatch pattern *)
            Opacity[0.18], White, Thickness[0.006],
            Table[Line[{{-0.1,  0.1 + 0.13 i}, {1.1, -0.5 + 0.13 i}}], {i, 0, 14}],
            Table[Line[{{-0.1, -0.5 + 0.13 i}, {1.1,  0.1 + 0.13 i}}], {i, 0, 14}],
            Opacity[1],

            (* central medallion *)
            GrayLevel[1, 0.35],
            Disk[{0.5, 0.75}, {0.22, 0.22}],
            GrayLevel[1, 0.8],
            Text[Style["\[SpadeSuit]\[HeartSuit]",
                       FontSize -> 16, FontWeight -> Bold],
                 {0.5, 0.75}]
        },
        ImageSize   -> {65, 98},
        PlotRange   -> {{0, 1}, {0, 1.5}},
        AspectRatio -> 1.5
    ];

cardRow[cards_List, hiddenIndices_List:{}] :=
    If[cards === {},
        Spacer[{0, 90}],
        Row[
            MapIndexed[
                If[MemberQ[hiddenIndices, First[#2]],
                   hiddenCardGraphic[],
                   cardGraphic[#1]
                ] &,
                cards
            ],
            Spacer[6]
        ]
    ];

(* --- small UI primitives ------------------------------------------------- *)

messageStyle["win"]  := Directive[Bold, 22, $winColor];
messageStyle["lose"] := Directive[Bold, 22, $loseColor];
messageStyle["push"] := Directive[Bold, 22, $pushColor];
messageStyle[_]      := Directive[Bold, 22, $gold];

visibleDealerScore[{}] := 0;
visibleDealerScore[{firstCard_, ___}] :=
    ToString[RankPoints[firstCard["value"]]] <> " + ?";

labelBadge[text_, score_] :=
    Row[{
        Style[text, White, 14],
        Spacer[8],
        Framed[
            Style[ToString[score], Bold, 14, White],
            Background     -> GrayLevel[1, 0.2],
            RoundingRadius -> 10,
            FrameStyle     -> None,
            FrameMargins   -> {{8, 8}, {2, 2}}
        ]
    }];

statBadge[label_, value_] :=
    Framed[
        Row[{
            Style[label <> ": ", White, 13],
            Style[ToString[value], Bold, 13, $gold]
        }],
        Background     -> $badgeBg,
        RoundingRadius -> 8,
        FrameStyle     -> Directive[$feltMid, Thickness[0.8]],
        FrameMargins   -> {{10, 10}, {6, 6}}
    ];

infoBadge[label_, value_, color_:Automatic] :=
    Framed[
        Column[{
            Style[label, White, 11],
            Style[value, Bold, 16,
                If[color === Automatic, $gold, color]]
        }, Alignment -> Center, Spacings -> 0.3],
        Background     -> $badgeBg,
        RoundingRadius -> 8,
        FrameStyle     -> Directive[$feltMid, Thickness[0.8]],
        FrameMargins   -> {{12, 12}, {6, 6}},
        ImageSize      -> {120, 60}
    ];

sectionLabel[text_] :=
    Style[text, Bold, 13, $gold, FontFamily -> "Helvetica"];

(* --- formatted action labels --------------------------------------------- *)

actionLong["H"] := "Hit";
actionLong["S"] := "Stand";
actionLong[_]   := "-";

(* --- main controller ----------------------------------------------------- *)

BlackjackGame[] :=
    DynamicModule[
        {
            (* core state *)
            deck, playerHand = {}, dealerHand = {},
            gameOver = False, message = "", result = "",
            revealDealer = False,

            (* session stats (history stores signed dollar changes) *)
            wins = 0, losses = 0, pushes = 0, history = {},

            (* bankroll & bet *)
            startingBank = 1000., bankroll = 1000., currentBet = 10.,
            roundBet = 10., lastPayout = 0.,
            minBet = 5., maxBet = 500.,

            (* configuration *)
            nDecks = 1, hitSoft17 = False, penetration = 0.75,
            evTrials = 600, dealerPace = 0.45,

            (* shoe / counting state *)
            shoeSize = 52, historicalCount = 0,

            (* coach cache *)
            evHit = None, evStand = None, evStale = True,

            (* helper function symbols -- declared here so their DownValues
               share the DynamicModule's persistent dynamic context and
               survive across FE button clicks. *)
            finish, startRound, doHit, doStand, doReset, doRebuy,
            reshuffleIfNeeded, absorbRound, unseenCards,
            displayCount, recomputeEV, sessionPlot,
            onDecksChange, onSoft17Change, addChip, clearBet, maxOutBet,
            chipButton
        },

        (* --- reshuffle logic ---------------------------------------------- *)
        reshuffleIfNeeded[] := If[
            NeedsReshuffle[deck, shoeSize, penetration],
            deck            = CreateShoe[nDecks];
            shoeSize        = nDecks * 52;
            historicalCount = 0;
        ];

        absorbRound[] := (
            historicalCount += HiLoCount[playerHand] + HiLoCount[dealerHand];
        );

        (* --- unseen = actual remaining deck + dealer's hidden hole card --- *)
        unseenCards[] :=
            If[!revealDealer && Length[dealerHand] >= 2,
                Join[deck, {dealerHand[[2]]}],
                deck
            ];

        displayCount[] :=
            historicalCount + HiLoCount[playerHand] +
                If[revealDealer || gameOver,
                    HiLoCount[dealerHand],
                    HiLoCount[Take[dealerHand, UpTo[1]]]
                ];

        (* --- round flow --------------------------------------------------- *)

        finish[res_String, msg_String] := Module[{isBJ, payout, richMsg},
            gameOver     = True;
            revealDealer = True;
            result       = res;

            (* 3:2 payout only on a natural (two-card) player blackjack *)
            isBJ   = (res === "win" && IsBlackjack[playerHand]);
            payout = Payout[res, roundBet, isBJ];
            bankroll   += payout;
            lastPayout  = payout;

            richMsg = msg <> "   (" <>
                      Which[payout > 0, "+$", payout < 0, "-$", True, "$"] <>
                      ToString[NumberForm[Abs[payout], {Infinity, 2}]] <> ")";
            message = richMsg;

            Switch[res,
                "win",  wins++,
                "lose", losses++,
                "push", pushes++
            ];
            AppendTo[history, payout];
            evStale = True;
        ];

        startRound[] := Module[{p, dh, d, pScore, dScore, effBet},
            If[Length[playerHand] > 0 || Length[dealerHand] > 0, absorbRound[]];
            reshuffleIfNeeded[];

            (* Lock in the bet for this round. Bet is clamped to available
               bankroll in case the player went negative on the last round. *)
            effBet = Clip[currentBet, {Min[minBet, bankroll], Max[bankroll, minBet]}];
            If[effBet > bankroll, effBet = bankroll];
            If[effBet < minBet,   effBet = Min[minBet, bankroll]];
            currentBet = effBet;
            roundBet   = effBet;
            lastPayout = 0.;

            gameOver     = False;
            revealDealer = False;
            result       = "";
            message      = "";
            evStale      = True;

            {p, dh, d}   = DealInitial[deck];
            playerHand   = p;
            dealerHand   = dh;
            deck         = d;

            pScore = HandScore[playerHand];
            dScore = HandScore[dealerHand];

            Which[
                pScore === 21 && dScore === 21, finish["push", "Both have Blackjack! Push!"],
                pScore === 21,                  finish["win",  "Blackjack! You win!"],
                dScore === 21,                  finish["lose", "Dealer has Blackjack! You lose!"]
            ];
        ];

        doHit[] := If[!gameOver,
            Module[{card, score},
                {card, deck} = DrawCard[deck];
                AppendTo[playerHand, card];
                evStale = True;
                score = HandScore[playerHand];
                Which[
                    score > 21,   finish["lose", "Bust! You lose!"],
                    score === 21, doStand[]
                ];
            ]
        ];

        doStand[] := If[!gameOver,
            Module[{res, msg, card},
                revealDealer = True;
                Pause[dealerPace];
                While[DealerShouldHit[dealerHand, hitSoft17],
                    {card, deck} = DrawCard[deck];
                    AppendTo[dealerHand, card];
                    Pause[dealerPace];
                ];
                {res, msg} = ResolveRound[playerHand, dealerHand];
                finish[res, msg];
            ]
        ];

        doReset[] := (
            wins = 0; losses = 0; pushes = 0;
            history    = {};
            bankroll   = startingBank;
            currentBet = minBet * 2;
            lastPayout = 0.;
        );

        doRebuy[] := (
            bankroll  += startingBank;
            currentBet = Min[currentBet, bankroll];
        );

        (* --- bet controls ------------------------------------------------- *)

        addChip[v_] := (
            currentBet = Clip[currentBet + v,
                              {minBet, Min[bankroll, maxBet]}];
        );

        clearBet[] := (
            currentBet = Min[minBet, bankroll];
        );

        maxOutBet[] := (
            currentBet = Min[bankroll, maxBet];
        );

        chipButton[label_, value_, bgColor_, fg_:White] :=
            Button[
                Style[label, Bold, 13, fg],
                addChip[value],
                Enabled    -> Dynamic[gameOver && currentBet < Min[bankroll, maxBet]],
                Background -> bgColor,
                BaseStyle  -> {Bold, 12, fg},
                ImageSize  -> {60, 38},
                Method     -> "Queued"
            ];

        (* --- config change handlers --------------------------------------- *)

        onDecksChange[n_] := (
            nDecks          = n;
            shoeSize        = nDecks * 52;
            historicalCount = 0;
            deck            = CreateShoe[nDecks];
            playerHand      = {};
            dealerHand      = {};
            evStale         = True;
            startRound[];  (* deal a fresh round from the new shoe *)
        );

        onSoft17Change[b_] := (
            hitSoft17 = b;
            evStale   = True;
        );

        (* --- EV computation ----------------------------------------------- *)

        recomputeEV[] := If[
            Length[playerHand] >= 2 && Length[dealerHand] >= 1 && !gameOver,
            Module[{unseen = unseenCards[]},
                evHit = EstimateEV[playerHand, dealerHand[[1]], "Hit",
                                   unseen,
                                   "HitSoft17" -> hitSoft17,
                                   "Trials"    -> evTrials];
                evStand = EstimateEV[playerHand, dealerHand[[1]], "Stand",
                                     unseen,
                                     "HitSoft17" -> hitSoft17,
                                     "Trials"    -> evTrials];
                evStale = False;
            ]
        ];

        (* --- session plot ------------------------------------------------- *)

        sessionPlot[] :=
            If[Length[history] > 0,
                ListStepPlot[Prepend[Accumulate[history], 0],
                    PlotStyle           -> Directive[Thickness[0.008], $gold],
                    Frame               -> True,
                    FrameStyle          -> Directive[White, Thin],
                    Background          -> $felt,
                    GridLines           -> Automatic,
                    GridLinesStyle      -> Directive[GrayLevel[1, 0.15]],
                    ImageSize           -> {420, 160},
                    PlotRangePadding    -> Scaled[0.05],
                    FrameLabel          -> {Style["round", White, 10],
                                            Style["cumulative $", White, 10]},
                    FrameTicksStyle     -> White,
                    AspectRatio         -> 0.38
                ],
                Pane[
                    Style["Play a hand to populate the plot.", Italic, $infoColor, 12],
                    {420, 160}, Alignment -> Center
                ]
            ];

        (* --- initial setup ------------------------------------------------ *)
        deck     = CreateShoe[nDecks];
        shoeSize = nDecks * 52;
        startRound[];

        (* --- layout ------------------------------------------------------- *)
        EventHandler[
            Panel[
                Column[{

                    Style["\[SpadeSuit] Blackjack \[HeartSuit]", Bold, 32, $gold,
                          FontFamily -> "Helvetica"],

                    Spacer[{0, 6}],

                    (* --- Options ---------------------------------------- *)
                    OpenerView[{
                        sectionLabel["Options"],
                        Panel[
                            Grid[{
                                {Style["Decks in shoe:", White, 12],
                                 PopupMenu[
                                     Dynamic[nDecks, onDecksChange],
                                     {1, 2, 4, 6, 8}
                                 ]},
                                {Style["Dealer hits soft 17 (H17):", White, 12],
                                 Checkbox[Dynamic[hitSoft17, onSoft17Change]]},
                                {Style["Cut-card penetration:", White, 12],
                                 Row[{
                                     Slider[Dynamic[penetration], {0.50, 0.95, 0.05},
                                            ImageSize -> 150],
                                     Spacer[8],
                                     Dynamic @ Style[
                                         ToString[Round[100 penetration]] <> " %",
                                         White, 12]
                                 }]},
                                {Style["Dealer draw pause (s):", White, 12],
                                 Row[{
                                     Slider[Dynamic[dealerPace], {0., 1.2, 0.05},
                                            ImageSize -> 150],
                                     Spacer[8],
                                     Dynamic @ Style[
                                         ToString[NumberForm[dealerPace, {2,2}]] <> " s",
                                         White, 12]
                                 }]},
                                {Style["Monte-Carlo trials:", White, 12],
                                 Row[{
                                     Slider[Dynamic[evTrials], {100, 3000, 100},
                                            ImageSize -> 150],
                                     Spacer[8],
                                     Dynamic @ Style[ToString[evTrials], White, 12]
                                 }]}
                            },
                            Alignment -> {{Right, Left}},
                            Spacings  -> {2, 0.8}],
                            Background     -> $panelBg,
                            FrameStyle     -> None,
                            RoundingRadius -> 10,
                            FrameMargins   -> 10
                        ]
                    }, False],

                    Spacer[{0, 10}],

                    (* --- Bankroll / bet ---------------------------------- *)
                    Panel[
                        Column[{
                            Row[{
                                Dynamic @ infoBadge["Bankroll",
                                    "$" <> ToString[NumberForm[bankroll, {Infinity, 2}]],
                                    If[bankroll >= startingBank, $winColor,
                                       If[bankroll < minBet, $loseColor, $gold]]
                                ],
                                Spacer[12],
                                Dynamic @ infoBadge["Bet",
                                    "$" <> ToString[NumberForm[currentBet, {Infinity, 2}]],
                                    $gold
                                ],
                                Spacer[12],
                                Dynamic @ infoBadge["Last round",
                                    If[lastPayout == 0.,
                                        "-",
                                        (If[lastPayout > 0, "+$", "-$"]) <>
                                        ToString[NumberForm[Abs[lastPayout], {Infinity, 2}]]
                                    ],
                                    Which[
                                        lastPayout > 0, $winColor,
                                        lastPayout < 0, $loseColor,
                                        True,           White
                                    ]
                                ]
                            }, Alignment -> Center],

                            Spacer[{0, 8}],

                            Row[{
                                chipButton["$5",    5,   $loseColor],
                                Spacer[6],
                                chipButton["$25",   25,  $winColor],
                                Spacer[6],
                                chipButton["$100",  100, RGBColor["#111111"]],
                                Spacer[14],
                                Button[
                                    Style["Clear", Bold, 12, White],
                                    clearBet[],
                                    Enabled    -> Dynamic[gameOver && currentBet > minBet],
                                    Background -> GrayLevel[0.3],
                                    BaseStyle  -> {Bold, 12, White},
                                    ImageSize  -> {70, 34},
                                    Method     -> "Queued"
                                ],
                                Spacer[6],
                                Button[
                                    Style["All in", Bold, 12, White],
                                    maxOutBet[],
                                    Enabled    -> Dynamic[gameOver && bankroll > minBet],
                                    Background -> GrayLevel[0.3],
                                    BaseStyle  -> {Bold, 12, White},
                                    ImageSize  -> {70, 34},
                                    Method     -> "Queued"
                                ],
                                Spacer[14],
                                Dynamic @ Button[
                                    Style["Rebuy +$" <>
                                          ToString[NumberForm[startingBank, {Infinity, 0}]],
                                          Bold, 12, Black],
                                    doRebuy[],
                                    Enabled    -> Dynamic[gameOver && bankroll < minBet],
                                    Background -> $gold,
                                    BaseStyle  -> {Bold, 12, Black},
                                    ImageSize  -> {130, 34},
                                    Method     -> "Queued"
                                ]
                            }, Alignment -> Center]
                        }, Alignment -> Center],
                        Background     -> $panelBg,
                        FrameStyle     -> None,
                        RoundingRadius -> 10,
                        FrameMargins   -> 10,
                        ImageSize      -> {660, All}
                    ],

                    Spacer[{0, 10}],

                    (* --- Dealer area ------------------------------------ *)
                    Dynamic[
                        labelBadge["Dealer's Hand",
                            If[revealDealer || gameOver,
                                HandScore[dealerHand],
                                visibleDealerScore[dealerHand]
                            ]
                        ]
                    ],
                    Framed[
                        Dynamic @ cardRow[dealerHand,
                            If[revealDealer || gameOver, {}, {2}]
                        ],
                        Background     -> $panelBg,
                        FrameStyle     -> None,
                        RoundingRadius -> 10,
                        FrameMargins   -> 10,
                        ImageSize      -> {All, 110}
                    ],

                    Spacer[{0, 12}],

                    (* --- Player area ------------------------------------ *)
                    Dynamic @ labelBadge["Your Hand", HandScore[playerHand]],
                    Framed[
                        Dynamic @ cardRow[playerHand],
                        Background     -> $panelBg,
                        FrameStyle     -> None,
                        RoundingRadius -> 10,
                        FrameMargins   -> 10,
                        ImageSize      -> {All, 110}
                    ],

                    Spacer[{0, 8}],

                    (* --- Result message --------------------------------- *)
                    Dynamic @ Pane[
                        Style[message, messageStyle[result]],
                        {600, 35},
                        Alignment -> Center
                    ],

                    (* --- Controls --------------------------------------- *)
                    Row[{
                        Button["Hit  (H)",
                            doHit[],
                            Enabled    -> Dynamic[!gameOver],
                            Background -> $winColor,
                            BaseStyle  -> {White, Bold, 14},
                            ImageSize  -> {130, 40},
                            Method     -> "Queued"
                        ],
                        Spacer[10],
                        Button["Stand  (S)",
                            doStand[],
                            Enabled    -> Dynamic[!gameOver],
                            Background -> $loseColor,
                            BaseStyle  -> {White, Bold, 14},
                            ImageSize  -> {130, 40},
                            Method     -> "Queued"
                        ],
                        Spacer[10],
                        Button["Deal  (N)",
                            startRound[],
                            Enabled    -> Dynamic[gameOver && bankroll >= minBet],
                            Background -> $gold,
                            BaseStyle  -> {Black, Bold, 14},
                            ImageSize  -> {150, 40},
                            Method     -> "Queued"
                        ]
                    }, Alignment -> Center],

                    Spacer[{0, 14}],

                    (* --- Stats + reset ---------------------------------- *)
                    Row[{
                        Dynamic @ statBadge["Wins",   wins],
                        Spacer[12],
                        Dynamic @ statBadge["Losses", losses],
                        Spacer[12],
                        Dynamic @ statBadge["Pushes", pushes],
                        Spacer[18],
                        Button["Reset stats",
                            doReset[],
                            Background -> GrayLevel[0.3],
                            BaseStyle  -> {White, Bold, 11},
                            ImageSize  -> {110, 28},
                            Method     -> "Queued"
                        ]
                    }, Alignment -> Center],

                    Spacer[{0, 14}],

                    (* --- Coach (basic strategy + EV) -------------------- *)
                    OpenerView[{
                        sectionLabel["Coach"],
                        Panel[
                            Column[{
                                Dynamic[
                                    Row[{
                                        infoBadge["Basic strategy",
                                            If[!gameOver && Length[playerHand] >= 2 && Length[dealerHand] >= 1,
                                                actionLong @ BasicStrategy[playerHand, dealerHand[[1]]],
                                                "-"
                                            ]
                                        ],
                                        Spacer[10],
                                        infoBadge["EV Hit",
                                            If[evHit === None, "-",
                                               ToString[NumberForm[evHit, {3, 3}]]],
                                            If[evHit =!= None && evStand =!= None && evHit >= evStand,
                                                $gold, White]
                                        ],
                                        Spacer[10],
                                        infoBadge["EV Stand",
                                            If[evStand === None, "-",
                                               ToString[NumberForm[evStand, {3, 3}]]],
                                            If[evHit =!= None && evStand =!= None && evStand > evHit,
                                                $gold, White]
                                        ]
                                    }]
                                ],
                                Spacer[{0, 8}],
                                Row[{
                                    Button["Estimate EV",
                                        recomputeEV[],
                                        Enabled    -> Dynamic[!gameOver &&
                                                              Length[playerHand] >= 2 &&
                                                              Length[dealerHand] >= 1],
                                        Background -> GrayLevel[0.35],
                                        BaseStyle  -> {White, Bold, 12},
                                        ImageSize  -> {140, 30},
                                        Method     -> "Queued"
                                    ],
                                    Spacer[10],
                                    Dynamic @ Style[
                                        If[evStale, "(stale — click to refresh)", "(up to date)"],
                                        Italic, $infoColor, 11
                                    ]
                                }, Alignment -> Center],
                                Spacer[{0, 4}],
                                Style[
                                    "EVs are per-unit Monte-Carlo estimates; higher is better.",
                                    Italic, $infoColor, 10
                                ]
                            }, Alignment -> Center],
                            Background     -> $panelBg,
                            FrameStyle     -> None,
                            RoundingRadius -> 10,
                            FrameMargins   -> 10
                        ]
                    }, False],

                    Spacer[{0, 6}],

                    (* --- Shoe / Hi-Lo ----------------------------------- *)
                    OpenerView[{
                        sectionLabel["Shoe & card count"],
                        Panel[
                            Dynamic @ Row[{
                                infoBadge["Running", displayCount[]],
                                Spacer[10],
                                infoBadge["True",
                                    ToString @ NumberForm[
                                        TrueCount[displayCount[], Length[deck]],
                                        {3, 2}
                                    ]
                                ],
                                Spacer[10],
                                infoBadge["Cards left",
                                    ToString[Length[deck]] <> " / " <> ToString[shoeSize]
                                ],
                                Spacer[10],
                                infoBadge["Penetration",
                                    ToString[
                                        Round[
                                            100 (1 - Length[deck] / shoeSize)
                                        ]
                                    ] <> " %"
                                ]
                            }],
                            Background     -> $panelBg,
                            FrameStyle     -> None,
                            RoundingRadius -> 10,
                            FrameMargins   -> 10
                        ]
                    }, False],

                    Spacer[{0, 6}],

                    (* --- Session plot ----------------------------------- *)
                    OpenerView[{
                        sectionLabel["Session"],
                        Panel[
                            Column[{
                                Dynamic @ sessionPlot[],
                                Spacer[{0, 4}],
                                Dynamic @ Style[
                                    "Rounds played: " <> ToString[Length[history]] <>
                                    "    Net: " <>
                                    (If[Total[history] >= 0, "+$", "-$"]) <>
                                    ToString[NumberForm[Abs[Total[history]], {Infinity, 2}]],
                                    $infoColor, 12
                                ]
                            }, Alignment -> Center],
                            Background     -> $panelBg,
                            FrameStyle     -> None,
                            RoundingRadius -> 10,
                            FrameMargins   -> 10
                        ]
                    }, False]

                }, Alignment -> Center, Spacings -> 0.5],

                Background     -> $felt,
                FrameStyle     -> Directive[$feltMid, Thickness[2]],
                RoundingRadius -> 20,
                FrameMargins   -> 25,
                ImageSize      -> 720
            ],
            {
                "KeyDown" :> Switch[
                    ToLowerCase[CurrentValue["EventKey"]],
                    "h", doHit[],
                    "s", doStand[],
                    "n", startRound[]
                ]
            },
            PassEventsDown -> True
        ]
    ];

End[];

(* ::Section:: *)
(*Auto-launch when executed as a script*)

If[
    $FrontEnd === Null
      && ListQ[$ScriptCommandLine]
      && Length[$ScriptCommandLine] > 0
      && StringQ[$InputFileName]
      && FileBaseName[$InputFileName] === "BlackjackGame",
    UsingFrontEnd @ CreateDocument[
        ExpressionCell[BlackjackGame[], "Output"],
        WindowTitle -> "Blackjack"
    ]
];
