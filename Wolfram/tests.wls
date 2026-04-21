#!/usr/bin/env wolframscript
(* ::Package:: *)

(* Core-package tests for Blackjack`.                                       *)
(* Run with:  wolframscript -file tests.wls                                 *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "Blackjack.wl"}]];

SetAttributes[assert, HoldFirst];
assert[expr_, label_String] :=
    If[TrueQ[expr],
        Print["  ok  ", label],
        (Print["  FAIL ", label, ":  ", HoldForm[expr]]; $failed = True)
    ];

$failed = False;

mk[v_, s_:"\[SpadeSuit]"] := Blackjack`MakeCard[v, s];

Print["Blackjack core tests"];
Print["=================================="];

(* ===== Deck / shoe ====================================================== *)
Print["--- deck ---"];
Module[{deck = Blackjack`CreateDeck[]},
    assert[Length[deck] === 52,                                                   "deck has 52 cards"];
    assert[Length[DeleteDuplicates[deck]] === 52,                                 "deck has no duplicates"];
    assert[Sort[DeleteDuplicates[#["suit"] & /@ deck]] === Sort[Blackjack`Suits], "deck contains all 4 suits"];
];
Module[{shoe = Blackjack`CreateShoe[6]},
    assert[Length[shoe] === 6 * 52,                                               "6-deck shoe has 312 cards"];
    assert[Count[shoe, c_ /; c["value"] === "A"] === 6 * 4,                       "6-deck shoe has 24 aces"];
];
assert[Blackjack`NeedsReshuffle[Range[10], 52, 0.75],                             "reshuffle when deep into shoe"];
assert[!Blackjack`NeedsReshuffle[Range[40], 52, 0.75],                            "no reshuffle when shallow"];

(* ===== Scoring ========================================================== *)
Print["--- scoring ---"];
assert[Blackjack`HandScore[{mk["A"], mk["K"]}] === 21,                            "A + K = 21"];
assert[Blackjack`HandScore[{mk["A"], mk["A"]}] === 12,                            "A + A = 12"];
assert[Blackjack`HandScore[{mk["A"], mk["9"], mk["3"]}] === 13,                   "A + 9 + 3 = 13 (ace demotes)"];
assert[Blackjack`HandScore[{mk["10"], mk["5"], mk["Q"]}] === 25,                  "10 + 5 + Q = 25 (bust)"];
assert[Blackjack`HandScore[{mk["J"], mk["Q"], mk["K"]}] === 30,                   "J + Q + K = 30"];
assert[Blackjack`HandScore[{mk["A"], mk["A"], mk["9"]}] === 21,                   "A + A + 9 = 21"];

(* Property: HandScore is invariant under permutation *)
Module[{h = RandomSample[Join[{mk["A"], mk["A"]}, mk /@ {"5", "6", "7", "8"}]],
        pass = True, s1, s2},
    s1 = Blackjack`HandScore[h];
    Do[
        s2 = Blackjack`HandScore[RandomSample[h]];
        If[s2 =!= s1, pass = False],
        {30}
    ];
    assert[pass, "HandScore invariant under permutation"];
];

(* ===== Soft / bust / blackjack ========================================== *)
Print["--- predicates ---"];
assert[Blackjack`IsSoft[{mk["A"], mk["6"]}],                                      "A + 6 is soft 17"];
assert[!Blackjack`IsSoft[{mk["A"], mk["6"], mk["Q"]}],                            "A + 6 + Q is hard 17"];
assert[Blackjack`IsSoft[{mk["A"], mk["A"], mk["5"]}],                             "A + A + 5 is soft 17"];
assert[!Blackjack`IsSoft[{mk["10"], mk["7"]}],                                    "10 + 7 is not soft"];
assert[Blackjack`IsBlackjack[{mk["A"], mk["K"]}],                                 "A + K is blackjack"];
assert[!Blackjack`IsBlackjack[{mk["A"], mk["5"], mk["5"]}],                       "A + 5 + 5 is 21 but not blackjack"];
assert[Blackjack`IsBust[{mk["10"], mk["K"], mk["5"]}],                            "25 is a bust"];
assert[!Blackjack`IsBust[{mk["A"], mk["K"]}],                                     "21 is not a bust"];

(* ===== Dealer policy ===================================================== *)
Print["--- dealer policy ---"];
assert[Blackjack`DealerShouldHit[{mk["5"], mk["9"]}],                             "dealer hits on 14"];
assert[!Blackjack`DealerShouldHit[{mk["10"], mk["7"]}],                           "dealer stands on hard 17 (S17)"];
assert[!Blackjack`DealerShouldHit[{mk["A"], mk["6"]}, False],                     "S17: dealer stands on soft 17"];
assert[Blackjack`DealerShouldHit[{mk["A"], mk["6"]}, True],                       "H17: dealer hits soft 17"];
assert[!Blackjack`DealerShouldHit[{mk["A"], mk["7"]}, True],                      "H17: dealer stands on soft 18"];

(* Property: PlayDealer terminates at >=17 or bust *)
Module[{pass = True, h, d},
    Do[
        {h, d} = Blackjack`PlayDealer[{mk["2"], mk["3"]}, Blackjack`CreateShoe[2]];
        If[!(Blackjack`HandScore[h] >= 17 || Blackjack`IsBust[h]), pass = False]
        ,
        {40}
    ];
    assert[pass, "PlayDealer always ends at >=17 or bust (40 trials)"];
];

(* ===== Round resolution ================================================== *)
Print["--- round resolution ---"];
assert[First[Blackjack`ResolveRound[{mk["A"], mk["K"]},  {mk["10"], mk["8"]}]] === "win",
                                                                                  "natural blackjack wins"];
assert[First[Blackjack`ResolveRound[{mk["10"], mk["8"]}, {mk["A"], mk["K"]}]] === "lose",
                                                                                  "dealer blackjack loses"];
assert[First[Blackjack`ResolveRound[{mk["10"], mk["9"]}, {mk["10"], mk["9"]}]] === "push",
                                                                                  "equal scores push"];
assert[First[Blackjack`ResolveRound[{mk["10"], mk["5"], mk["8"]}, {mk["10"], mk["7"]}]] === "lose",
                                                                                  "player bust loses"];
assert[First[Blackjack`ResolveRound[{mk["10"], mk["9"]}, {mk["10"], mk["5"], mk["8"]}]] === "win",
                                                                                  "dealer bust wins"];

(* ===== Hi-Lo count ======================================================= *)
Print["--- hi-lo ---"];
assert[Blackjack`HiLoValue[mk["2"]] === +1,                                        "2 counts as +1"];
assert[Blackjack`HiLoValue[mk["6"]] === +1,                                        "6 counts as +1"];
assert[Blackjack`HiLoValue[mk["7"]] ===  0,                                        "7 counts as 0"];
assert[Blackjack`HiLoValue[mk["9"]] ===  0,                                        "9 counts as 0"];
assert[Blackjack`HiLoValue[mk["10"]] === -1,                                       "10 counts as -1"];
assert[Blackjack`HiLoValue[mk["A"]] === -1,                                        "A counts as -1"];
assert[Blackjack`HiLoCount[{mk["2"], mk["3"], mk["10"], mk["A"], mk["8"]}] === 0,  "mixed hand sums correctly"];

(* Sum of Hi-Lo values over a full 52-card deck is 0 (5 low+5 high per suit) *)
assert[Blackjack`HiLoCount[Blackjack`CreateDeck[]] === 0,                          "HiLo over full deck is 0"];

(* TrueCount scaling *)
assert[Abs[Blackjack`TrueCount[6, 104] - 3.] < 1*^-9,                              "true count: +6 running with 2 decks left -> +3"];

(* ===== Basic strategy ==================================================== *)
Print["--- basic strategy ---"];
assert[Blackjack`BasicStrategy[{mk["10"], mk["7"]}, mk["10"]] === "S",             "hard 17 vs 10: stand"];
assert[Blackjack`BasicStrategy[{mk["10"], mk["6"]}, mk["10"]] === "H",             "hard 16 vs 10: hit"];
assert[Blackjack`BasicStrategy[{mk["10"], mk["6"]}, mk["6"]]  === "S",             "hard 16 vs 6: stand"];
assert[Blackjack`BasicStrategy[{mk["10"], mk["2"]}, mk["5"]]  === "S",             "hard 12 vs 5: stand"];
assert[Blackjack`BasicStrategy[{mk["10"], mk["2"]}, mk["3"]]  === "H",             "hard 12 vs 3: hit"];
assert[Blackjack`BasicStrategy[{mk["A"], mk["7"]},  mk["2"]]  === "S",             "soft 18 vs 2: stand"];
assert[Blackjack`BasicStrategy[{mk["A"], mk["7"]},  mk["9"]]  === "H",             "soft 18 vs 9: hit"];
assert[Blackjack`BasicStrategy[{mk["A"], mk["8"]},  mk["10"]] === "S",             "soft 19 vs 10: stand"];
assert[Blackjack`BasicStrategy[{mk["A"], mk["6"]},  mk["5"]]  === "H",             "soft 17 vs 5: hit"];
assert[Blackjack`BasicStrategy[{mk["5"], mk["5"]},  mk["10"]] === "H",             "10 vs 10: hit"];

(* ===== Payout ============================================================ *)
Print["--- payout ---"];
assert[Blackjack`Payout["win",  10]        ===  10.,                               "regular win pays 1:1"];
assert[Blackjack`Payout["win",  10, True]  ===  15.,                               "natural blackjack pays 3:2"];
assert[Blackjack`Payout["lose", 10]        === -10.,                               "loss returns -bet"];
assert[Blackjack`Payout["push", 10]        ===   0.,                               "push returns 0"];
assert[Blackjack`Payout["push", 10, True]  ===   0.,                               "push with BJ flag still 0"];
assert[Blackjack`Payout["win",  0]         ===   0.,                               "zero-bet win pays 0"];

(* ===== EV sanity checks ================================================== *)
Print["--- EV sanity (stochastic, thresholds chosen with margin) ---"];

(* Helper: build an unseen pool by removing visible cards, matching what
   the UI does at runtime.                                               *)
removeOne[lst_, item_] := With[{pos = FirstPosition[lst, item, Missing[]]},
    If[MissingQ[pos], lst, Delete[lst, First[pos]]]
];
unseenFor[playerHand_, dealerUpcard_, shoe_] :=
    Fold[removeOne, shoe, Append[playerHand, dealerUpcard]];

Module[{ev, unseen},
    (* Stand on 20 vs dealer 6: very strong EV (~ +0.7). *)
    unseen = unseenFor[{mk["K"], mk["Q"]}, mk["6"], Blackjack`CreateShoe[6]];
    ev = Blackjack`EstimateEV[{mk["K"], mk["Q"]}, mk["6"],
                              "Stand", unseen, "Trials" -> 1500];
    assert[ev > 0.55,                                                              "EV(stand 20 vs 6) > 0.55"];
];

Module[{evHit, evStand, unseen},
    (* Hard 10 vs dealer 10: hitting wildly beats standing.
       EV(stand) ~ -0.76, EV(hit) ~ -0.25, so the signal is enormous.  *)
    unseen  = unseenFor[{mk["6"], mk["4"]}, mk["10"], Blackjack`CreateShoe[6]];
    evHit   = Blackjack`EstimateEV[{mk["6"], mk["4"]}, mk["10"],
                                   "Hit",   unseen, "Trials" -> 1500];
    evStand = Blackjack`EstimateEV[{mk["6"], mk["4"]}, mk["10"],
                                   "Stand", unseen, "Trials" -> 1500];
    assert[evHit > evStand + 0.2,                                                   "hit beats stand on hard 10 vs 10"];
];

Print["=================================="];
If[TrueQ[$failed],
    (Print["TESTS FAILED"]; Exit[1]),
    Print["All tests passed."]
];
