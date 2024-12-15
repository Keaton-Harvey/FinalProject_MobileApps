//
//  BlackjackGame.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/15/24.
//

// TODO: this is where all game logic for the blackjack game will be. It should be able to be accessed by both practice and challenge view controllers

import Foundation

enum Suit: CaseIterable {
    case spades, hearts, clubs, diamonds
}

extension Suit {
    var name: String {
        switch self {
        case .spades: return "spades"
        case .hearts: return "hearts"
        case .clubs: return "clubs"
        case .diamonds: return "diamonds"
        }
    }
}

enum Rank: String, CaseIterable {
    case ace = "ace"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "jack"
    case queen = "queen"
    case king = "king"

    var value: Int {
        switch self {
        case .ace: return 11
        case .jack, .queen, .king, .ten: return 10
        default:
            return Int(self.rawValue)!
        }
    }
}

struct Card {
    let suit: Suit
    let rank: Rank

    func description() -> String {
        return "\(rank.rawValue) of \(suit)"
    }
}

class Deck {
    private(set) var cards: [Card] = []

    init(numberOfDecks: Int = 1) {
        for _ in 0..<numberOfDecks {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    cards.append(Card(suit: suit, rank: rank))
                }
            }
        }
        shuffle()
    }

    func shuffle() {
        cards.shuffle()
    }

    func dealCard() -> Card? {
        if cards.isEmpty {
            return nil
        }
        return cards.removeLast()
    }

    func resetAndShuffle(numberOfDecks: Int) {
        cards.removeAll()
        for _ in 0..<numberOfDecks {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    cards.append(Card(suit: suit, rank: rank))
                }
            }
        }
        shuffle()
    }
}

class Hand {
    private(set) var cards: [Card] = []
    var isInitialHand: Bool = false

    var isBusted: Bool {
        return total > 21
    }

    var total: Int {
        var total = 0
        var aces = 0
        for card in cards {
            if card.rank == .ace {
                aces += 1
                total += 11
            } else {
                total += card.rank.value
            }
        }

        // Adjust for aces if over 21
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }

    var isSoft: Bool {
        // A hand is soft if it has an ace counted as 11
        // After adjustments, if we lowered aces, we can't be sure easily.
        // Check if adding 10 doesn't bust, meaning we had an ace as 11.
        var total = 0
        var aces = 0
        for card in cards {
            if card.rank == .ace {
                aces += 1
                total += 11
            } else {
                total += card.rank.value
            }
        }
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        // If after this, aces > 0 means at least one ace is counting as 11
        return aces > 0
    }

    func addCard(_ card: Card) {
        cards.append(card)
    }
    
    func removeLastCard() -> Card? {
            return cards.isEmpty ? nil : cards.removeLast()
        }

    func description() -> String {
        return cards.map { "\($0.rank.rawValue) of \($0.suit)" }.joined(separator: ", ")
    }
}

enum GameOutcome {
    case playerWin, playerLose, push, playerBlackjack
}

enum Action {
    case hit, stand, doubleDown, split
}

class BlackjackGame {
    private var deck: Deck
    private(set) var playerHands: [Hand] = []
    private(set) var dealerHand: Hand = Hand()

    let numberOfDecks: Int
    let dealerHitsSoft17: Int

    // Track the current player hand if multiple due to split
    private var currentHandIndex = 0
    private var roundInProgress = false

    init(numberOfDecks: Int = 1, dealerHitsSoft17: Int = 0) {
        self.numberOfDecks = numberOfDecks
        self.dealerHitsSoft17 = dealerHitsSoft17
        self.deck = Deck(numberOfDecks: numberOfDecks)
        startNewRound()
    }

    func startNewRound() {
        deck.resetAndShuffle(numberOfDecks: numberOfDecks)
        playerHands = [Hand()]
        playerHands[0].isInitialHand = true
        dealerHand = Hand()
        dealerHand.isInitialHand = true
        currentHandIndex = 0
        roundInProgress = true

        // Deal initial cards
        if let card1 = deck.dealCard(), let dcard1 = deck.dealCard(),
           let card2 = deck.dealCard(), let dcard2 = deck.dealCard() {
            playerHands[0].addCard(card1)
            dealerHand.addCard(dcard1)
            playerHands[0].addCard(card2)
            dealerHand.addCard(dcard2)
        }

        // Check for player blackjack or dealer blackjack
        // If dealer or player has blackjack, we can end round immediately
        if isBlackjack(hand: playerHands[0]) || isBlackjack(hand: dealerHand) {
            // Immediate outcome
            roundInProgress = false
        }
    }

    func isBlackjack(hand: Hand) -> Bool {
        return hand.isInitialHand && hand.cards.count == 2 && hand.total == 21
    }

    private var currentPlayerHand: Hand {
        return playerHands[currentHandIndex]
    }

    func playerHit() {
        guard roundInProgress else { return }
        guard !currentPlayerHand.isBusted else { return }

        if let card = deck.dealCard() {
            playerHands[currentHandIndex].addCard(card)
        }
    }

    func playerStand() {
        guard roundInProgress else { return }

        // Move to next hand if split, else dealer plays
        currentHandIndex += 1
        if currentHandIndex >= playerHands.count {
            // All player hands done, dealer plays
            dealerPlay()
            roundInProgress = false
        }
    }

    func playerDoubleDown() {
        // Player doubles down: one extra card, then stand
        guard roundInProgress else { return }
        // Just deal one card and then stand
        if let card = deck.dealCard() {
            playerHands[currentHandIndex].addCard(card)
        }
        // Move to next hand or dealer turn
        playerStand()
    }

    func playerCanSplit() -> Bool {
        let hand = currentPlayerHand
        if hand.cards.count == 2 && hand.cards[0].rank.value == hand.cards[1].rank.value {
            return true
        }
        return false
    }

    func playerSplit() {
        guard roundInProgress else { return }
        guard playerCanSplit() else { return }

        let hand = currentPlayerHand
        guard let secondCard = hand.removeLastCard() else { return }

        // New hand formed by splitting is not an initial hand
        let newHand = Hand()
        newHand.addCard(secondCard)
        newHand.isInitialHand = false

        // Current hand also loses its initial-hand status
        // Once we split, the current hand is no longer the original 2-card deal
        playerHands[currentHandIndex].isInitialHand = false

        playerHands.insert(newHand, at: currentHandIndex+1)

        // Deal new cards to each split hand
        if let newCardForFirstHand = deck.dealCard(), let newCardForSecondHand = deck.dealCard() {
            playerHands[currentHandIndex].addCard(newCardForFirstHand)
            playerHands[currentHandIndex+1].addCard(newCardForSecondHand)
            // These hands now each have 2 cards but are not initial, so no blackjack possibility
        }
    }

    private func dealerPlay() {
        // Dealer reveals hidden card and draws until rules are met
        // Dealer must hit until total >=17, or if dealerHitsSoft17=true, dealer hits soft17
        while dealerShouldHit(dealerHand: dealerHand) {
            if let card = deck.dealCard() {
                dealerHand.addCard(card)
            } else {
                break // Deck ran out?
            }
        }
    }

    private func dealerShouldHit(dealerHand: Hand) -> Bool {
        let total = dealerHand.total
        if total < 17 {
            return true
        } else if total == 17 && dealerHand.isSoft && dealerHitsSoft17 == 1 {
            return true
        }
        return false
    }

    // Determine outcome for each player's hand after dealer finishes
    func outcomes() -> [GameOutcome] {
        var results: [GameOutcome] = []
        let dealerTotal = dealerHand.total
        let dealerBust = dealerHand.isBusted

        for hand in playerHands {
            if isBlackjack(hand: hand) && !isBlackjack(hand: dealerHand) {
                // Player blackjack vs non-blackjack dealer -> player wins
                results.append(.playerBlackjack)
            } else if isBlackjack(hand: hand) && isBlackjack(hand: dealerHand) {
                // Both blackjack -> push
                results.append(.push)
            } else if hand.isBusted {
                results.append(.playerLose)
            } else if dealerBust {
                results.append(.playerWin)
            } else {
                let playerTotal = hand.total
                if playerTotal > dealerTotal {
                    results.append(.playerWin)
                } else if playerTotal < dealerTotal {
                    results.append(.playerLose)
                } else {
                    results.append(.push)
                }
            }
        }

        return results
    }

    func roundFinished() -> Bool {
        return !roundInProgress
    }
}
