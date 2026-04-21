(* ::Package:: *)

(* ::Title:: *)
(*Blackjack - Core Game Logic*)

(* ::Text:: *)
(*A Wolfram Language translation of the browser-based Blackjack game.*)
(*This package provides the pure game mechanics: deck/shoe creation, drawing,*)
(*hand-value computation, soft/bust detection, round resolution, Hi-Lo card*)
(*counting, a simplified basic-strategy oracle, and Monte-Carlo EV estimation.*)
(*The interactive GUI lives in BlackjackGame.wl.*)

BeginPackage["Blackjack`"];

Suits::usage            = "Suits is the list of suit glyphs {\"\[SpadeSuit]\", \"\[HeartSuit]\", \"\[DiamondSuit]\", \"\[ClubSuit]\"}.";
Ranks::usage            = "Ranks is the list of rank labels from Ace through King.";
MakeCard::usage         = "MakeCard[value, suit] constructs a card association.";
CardValue::usage        = "CardValue[card] returns the rank of a card.";
CardSuit::usage         = "CardSuit[card] returns the suit of a card.";
IsRedSuit::usage        = "IsRedSuit[card] is True for hearts and diamonds.";
RankPoints::usage       = "RankPoints[rank] gives the base point value of a rank (Ace -> 11).";
CreateDeck::usage       = "CreateDeck[] returns a freshly shuffled 52-card deck.";
CreateShoe::usage       = "CreateShoe[n] returns a freshly shuffled n-deck shoe (n >= 1).";
DrawCard::usage         = "DrawCard[deck] returns {card, remainingDeck}. If deck is empty, a new shuffled deck is used.";
NeedsReshuffle::usage   = "NeedsReshuffle[deck, fullShoeSize, penetration] is True when the deck has been dealt past the cut-card.";
HandScore::usage        = "HandScore[hand] returns the optimal Blackjack score for a hand (aces count as 1 or 11).";
IsSoft::usage           = "IsSoft[hand] is True if the hand contains an ace counting as 11 without busting.";
IsBlackjack::usage      = "IsBlackjack[hand] is True if hand is a natural 21 on exactly two cards.";
IsBust::usage           = "IsBust[hand] is True if the hand exceeds 21.";
DealerShouldHit::usage  = "DealerShouldHit[hand, hitSoft17] is True while the dealer must draw. Set hitSoft17 True for H17 house rule.";
PlayDealer::usage       = "PlayDealer[dealerHand, deck, hitSoft17] draws until the dealer stands or busts. Returns {finalHand, remainingDeck}.";
ResolveRound::usage     = "ResolveRound[playerHand, dealerHand] returns {result, message} where result is \"win\", \"lose\", or \"push\".";
DealInitial::usage      = "DealInitial[deck] deals two cards each to player and dealer. Returns {playerHand, dealerHand, remainingDeck}.";
HiLoValue::usage        = "HiLoValue[card] gives the Hi-Lo running-count contribution of a card (+1 for 2-6, 0 for 7-9, -1 for 10-A).";
HiLoCount::usage        = "HiLoCount[cards] sums HiLoValue over a list of cards.";
TrueCount::usage        = "TrueCount[runningCount, cardsRemaining] converts a running count into the true count per 52-card deck.";
BasicStrategy::usage    = "BasicStrategy[playerHand, dealerUpcard] returns \"H\" or \"S\" under Hit/Stand-only basic strategy (no double, no split).";
EstimateEV::usage       = "EstimateEV[playerHand, dealerUpcard, action, unseenDeck] Monte-Carlo-estimates the EV of \"Hit\" or \"Stand\" from the current state. Options: \"HitSoft17\", \"Trials\".";
Payout::usage           = "Payout[result, bet, isBlackjack] returns the net bankroll change. A winning natural blackjack pays 3:2 when isBlackjack is True; other wins pay 1:1.";

Begin["`Private`"];

(* --- Card representation ------------------------------------------------- *)

Suits = {"\[SpadeSuit]", "\[HeartSuit]", "\[DiamondSuit]", "\[ClubSuit]"};
Ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"};

MakeCard[value_String, suit_String] := <|"value" -> value, "suit" -> suit|>;

CardValue[card_Association] := card["value"];
CardSuit [card_Association] := card["suit"];

IsRedSuit[card_Association] :=
    MemberQ[{"\[HeartSuit]", "\[DiamondSuit]"}, card["suit"]];

(* --- Rank points (lookup table; safer than ToExpression) ----------------- *)

rankPointsTable = <|
    "A"  -> 11,
    "2"  -> 2,  "3" -> 3,  "4" -> 4,  "5" -> 5,  "6" -> 6,
    "7"  -> 7,  "8" -> 8,  "9" -> 9,  "10" -> 10,
    "J"  -> 10, "Q" -> 10, "K" -> 10
|>;

RankPoints[rank_String] := rankPointsTable[rank];

(* --- Deck / shoe --------------------------------------------------------- *)

CreateShoe[nDecks_Integer:1] /; nDecks >= 1 :=
    RandomSample @ Flatten[
        Table[MakeCard[v, s], {nDecks}, {s, Suits}, {v, Ranks}],
        2
    ];

CreateDeck[] := CreateShoe[1];

DrawCard[{}]        := DrawCard[CreateDeck[]];
DrawCard[deck_List] := {First[deck], Rest[deck]};

NeedsReshuffle[deck_List, fullShoeSize_Integer, penetration_:0.75] :=
    Length[deck] < fullShoeSize * (1 - penetration);

(* --- Scoring / predicates ------------------------------------------------ *)

HandScore[hand_List] :=
    Module[{score, aces},
        score = Total[rankPointsTable[#["value"]] & /@ hand];
        aces  = Count[hand, c_Association /; c["value"] === "A"];
        While[score > 21 && aces > 0,
            score -= 10;
            aces--;
        ];
        score
    ];

IsSoft[hand_List] :=
    Module[{numAces, hardTotal},
        numAces = Count[hand, c_Association /; c["value"] === "A"];
        If[numAces === 0, Return[False]];
        hardTotal = Total[rankPointsTable[#["value"]] & /@ hand] - 10 * numAces;
        HandScore[hand] =!= hardTotal
    ];

IsBlackjack[hand_List] := Length[hand] === 2 && HandScore[hand] === 21;
IsBust     [hand_List] := HandScore[hand] > 21;

(* --- Dealer policy ------------------------------------------------------- *)

DealerShouldHit[hand_List, hitSoft17_:False] :=
    Module[{s = HandScore[hand]},
        s < 17 || (TrueQ[hitSoft17] && s === 17 && IsSoft[hand])
    ];

PlayDealer[dealerHand_List, deck_List, hitSoft17_:False] :=
    Module[{hand = dealerHand, d = deck, card},
        While[DealerShouldHit[hand, hitSoft17],
            {card, d} = DrawCard[d];
            AppendTo[hand, card];
        ];
        {hand, d}
    ];

(* --- Round resolution ---------------------------------------------------- *)

ResolveRound[playerHand_List, dealerHand_List] :=
    Module[{p = HandScore[playerHand], d = HandScore[dealerHand]},
        Which[
            IsBust[playerHand],                                           {"lose", "Bust! You lose!"},
            IsBust[dealerHand],                                           {"win",  "Dealer busts! You win!"},
            IsBlackjack[playerHand] && IsBlackjack[dealerHand],           {"push", "Both have Blackjack! Push!"},
            IsBlackjack[playerHand],                                      {"win",  "Blackjack! You win!"},
            IsBlackjack[dealerHand],                                      {"lose", "Dealer has Blackjack! You lose!"},
            p > d,                                                        {"win",  "You win!"},
            d > p,                                                        {"lose", "Dealer wins!"},
            True,                                                         {"push", "Push! It's a tie!"}
        ]
    ];

(* --- Initial deal -------------------------------------------------------- *)

DealInitial[deck_List] :=
    Module[{d = deck, p = {}, dh = {}, c},
        Do[
            {c, d} = DrawCard[d]; AppendTo[p,  c];
            {c, d} = DrawCard[d]; AppendTo[dh, c];
            ,
            {2}
        ];
        {p, dh, d}
    ];

(* --- Hi-Lo card counting ------------------------------------------------- *)

HiLoValue[rank_String] :=
    Which[
        MemberQ[{"2", "3", "4", "5", "6"}, rank], +1,
        MemberQ[{"7", "8", "9"},            rank],  0,
        True,                                      -1
    ];
HiLoValue[card_Association] := HiLoValue[card["value"]];

HiLoCount[cards_List] := Total[HiLoValue /@ cards];

TrueCount[runningCount_, cardsRemaining_] :=
    If[cardsRemaining > 0,
        N[runningCount / (cardsRemaining / 52)],
        0.
    ];

(* --- Basic strategy (Hit / Stand only) ----------------------------------- *)

(* This is a Hit/Stand-only reduction of Wizard-of-Odds basic strategy:
   double-down and split are unavailable in the game, so "D" collapses to
   "H" and "P" is inapplicable.                                            *)

BasicStrategy[playerHand_List, dealerUpcard_Association] :=
    Module[{score = HandScore[playerHand], soft = IsSoft[playerHand], up},
        up = rankPointsTable[dealerUpcard["value"]]; (* A -> 11 *)
        Which[
            (* Hard 17+ : stand *)
            !soft && score >= 17,              "S",
            (* Soft 19+ : stand *)
            soft && score >= 19,               "S",
            (* Soft 18 : stand vs 2-8, hit vs 9-A *)
            soft && score === 18,              If[MemberQ[{2, 3, 4, 5, 6, 7, 8}, up], "S", "H"],
            (* Soft 13-17 : always hit (no double available) *)
            soft,                              "H",
            (* Hard 4-11 : always hit *)
            score <= 11,                       "H",
            (* Hard 12 : stand vs 4-6 *)
            score === 12,                      If[MemberQ[{4, 5, 6}, up], "S", "H"],
            (* Hard 13-16 : stand vs 2-6 *)
            13 <= score <= 16,                 If[MemberQ[{2, 3, 4, 5, 6}, up], "S", "H"],
            True,                              "H"
        ]
    ];

(* --- Monte-Carlo EV ------------------------------------------------------ *)

Options[EstimateEV] = {"HitSoft17" -> False, "Trials" -> 2000};

EstimateEV[playerHand_List, dealerUpcard_Association, "Stand", unseen_List, OptionsPattern[]] :=
    Module[{hitSoft17 = OptionValue["HitSoft17"], nTrials = OptionValue["Trials"],
            total = 0, sample, hole, rest, dh},
        If[Length[unseen] < 1, Return[0.]];
        Do[
            sample         = RandomSample[unseen];
            {hole, rest}   = {First[sample], Rest[sample]};
            dh             = First @ PlayDealer[{dealerUpcard, hole}, rest, hitSoft17];
            total         += outcomeValue[playerHand, dh];
            ,
            {nTrials}
        ];
        N[total / nTrials]
    ];

EstimateEV[playerHand_List, dealerUpcard_Association, "Hit", unseen_List, OptionsPattern[]] :=
    Module[{hitSoft17 = OptionValue["HitSoft17"], nTrials = OptionValue["Trials"],
            total = 0, sample, rest, newCard, newHand, hole, rest2, dh},
        If[Length[unseen] < 2, Return[0.]];
        Do[
            sample           = RandomSample[unseen];
            {newCard, rest}  = {First[sample], Rest[sample]};
            newHand          = Append[playerHand, newCard];
            (* follow basic strategy after the mandatory first hit *)
            While[
                !IsBust[newHand] && HandScore[newHand] < 21 &&
                  BasicStrategy[newHand, dealerUpcard] === "H" &&
                  Length[rest] > 1,
                {newCard, rest} = DrawCard[rest];
                newHand         = Append[newHand, newCard];
            ];
            If[IsBust[newHand],
                total += -1
                ,
                {hole, rest2} = DrawCard[rest];
                dh            = First @ PlayDealer[{dealerUpcard, hole}, rest2, hitSoft17];
                total        += outcomeValue[newHand, dh];
            ];
            ,
            {nTrials}
        ];
        N[total / nTrials]
    ];

outcomeValue[playerHand_List, dealerHand_List] :=
    Which[
        IsBust[playerHand],                         -1,
        IsBust[dealerHand],                         +1,
        HandScore[playerHand] > HandScore[dealerHand], +1,
        HandScore[playerHand] < HandScore[dealerHand], -1,
        True,                                          0
    ];

(* --- Payout ------------------------------------------------------------- *)

Payout[result_String, bet_?NumericQ, isBlackjack_:False] :=
    Switch[result,
        "win",  If[TrueQ[isBlackjack], 1.5 * bet, 1. * bet],
        "lose", -1. * bet,
        "push",  0.,
        _,       0.
    ];

End[];
EndPackage[];
