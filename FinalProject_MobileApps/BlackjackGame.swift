//
//  BlackjackGame.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/15/24.
//


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
        return cards.isEmpty ? nil : cards.removeLast()
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
    var hasActed: Bool = false

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
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }

    var isSoft: Bool {
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
        return aces > 0
    }

    func addCard(_ card: Card) {
        cards.append(card)
    }

    func removeLastCard() -> Card? {
        return cards.isEmpty ? nil : cards.removeLast()
    }
}

enum GameOutcome {
    case playerWin, playerLose, push, playerBlackjack
}

class BlackjackGame {
    private var deck: Deck
    private var currentHandIndex = 0
    private var roundInProgress = false
    private var hasSplit = false

    let numberOfDecks: Int
    let dealerHitsSoft17: Int

    private(set) var playerHands: [Hand] = []
    private(set) var dealerHand: Hand = Hand()

    init(numberOfDecks: Int = 1, dealerHitsSoft17: Int = 0) {
        self.numberOfDecks = numberOfDecks
        self.dealerHitsSoft17 = dealerHitsSoft17
        self.deck = Deck(numberOfDecks: numberOfDecks)
    }

    func startNewRound() {
        deck.resetAndShuffle(numberOfDecks: numberOfDecks)
        playerHands = [Hand()]
        playerHands[0].isInitialHand = true
        playerHands[0].hasActed = false
        dealerHand = Hand()
        dealerHand.isInitialHand = true
        dealerHand.hasActed = false
        currentHandIndex = 0
        roundInProgress = true
        hasSplit = false

        if let p1 = deck.dealCard(),
           let d1 = deck.dealCard(),
           let p2 = deck.dealCard(),
           let d2 = deck.dealCard() {
            playerHands[0].addCard(p1)
            dealerHand.addCard(d1)
            playerHands[0].addCard(p2)
            dealerHand.addCard(d2)
        }

        if isBlackjack(hand: dealerHand) || isBlackjack(hand: playerHands[0]) {
            roundInProgress = false
        }
    }

    func isBlackjack(hand: Hand) -> Bool {
        return hand.isInitialHand && hand.cards.count == 2 && hand.total == 21
    }

    private var currentPlayerHand: Hand {
        return playerHands[currentHandIndex]
    }

    var currentHand: Hand {
        return currentPlayerHand
    }

    var currentHandIndexPublic: Int {
        return currentHandIndex
    }

    func currentHandCanDoubleDown() -> Bool {
        return roundInProgress && !currentPlayerHand.hasActed && currentPlayerHand.cards.count == 2
    }

    func currentHandCanHit() -> Bool {
        return roundInProgress && !currentPlayerHand.isBusted
    }

    func currentHandCanStand() -> Bool {
        return roundInProgress
    }

    func playerHit() {
        guard roundInProgress else { return }
        if let card = deck.dealCard() {
            currentPlayerHand.addCard(card)
        }

        // Check if the player busted after hitting
        if currentPlayerHand.isBusted {
            if hasSplit {
                // If we have multiple hands (split)
                if currentHandIndex < playerHands.count - 1 {
                    // Move to the next hand instead of ending the round
                    currentHandIndex += 1
                } else {
                    // Last hand has busted, dealer plays and round ends
                    dealerPlay()
                    roundInProgress = false
                }
            } else {
                // No split, so bust ends the entire round immediately
                roundInProgress = false
            }
            return
        }

        // If not busted, nothing else special happens here.
        // The player can continue hitting or choose another action.
    }

    func playerStand() {
        guard roundInProgress else { return }

        if currentHandIndex < playerHands.count - 1 {
            currentHandIndex += 1
        } else {
            dealerPlay()
            roundInProgress = false
        }
    }

    func playerDoubleDown() {
        guard roundInProgress else { return }
        guard currentHandCanDoubleDown() else { return }

        if let card = deck.dealCard() {
            currentPlayerHand.addCard(card)
        }
        currentPlayerHand.hasActed = true

        // Check if the player busted
        if currentPlayerHand.isBusted {
            if hasSplit {
                // If we have split hands
                if currentHandIndex < playerHands.count - 1 {
                    // Move to the next hand instead of ending the round
                    currentHandIndex += 1
                } else {
                    // This was the last hand, so dealer plays and end the round
                    dealerPlay()
                    roundInProgress = false
                }
            } else {
                // No split, round ends immediately on bust
                roundInProgress = false
            }
            return
        }

        // If not busted, proceed as normal
        if currentHandIndex < playerHands.count - 1 {
            currentHandIndex += 1
        } else {
            dealerPlay()
            roundInProgress = false
        }
    }

    func playerCanSplit() -> Bool {
        if hasSplit { return false }
        let hand = currentPlayerHand
        if hand.cards.count == 2 && hand.cards[0].rank.value == hand.cards[1].rank.value {
            return true
        }
        return false
    }

    func playerSplit() {
        guard roundInProgress else { return }
        guard playerCanSplit() else { return }

        hasSplit = true
        let hand = currentPlayerHand
        guard let secondCard = hand.removeLastCard() else { return }

        let newHand = Hand()
        newHand.addCard(secondCard)
        newHand.isInitialHand = false
        newHand.hasActed = false

        playerHands[currentHandIndex].isInitialHand = false
        playerHands[currentHandIndex].hasActed = false

        playerHands.insert(newHand, at: currentHandIndex+1)
    }

    private func dealerPlay() {
        while dealerShouldHit(dealerHand: dealerHand) {
            if let card = deck.dealCard() {
                dealerHand.addCard(card)
            } else {
                break
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

    func outcomes() -> [GameOutcome] {
        let dealerTotal = dealerHand.total
        let dealerBust = dealerHand.isBusted
        var results: [GameOutcome] = []

        for hand in playerHands {
            if isBlackjack(hand: hand) && !isBlackjack(hand: dealerHand) {
                results.append(.playerBlackjack)
            } else if isBlackjack(hand: hand) && isBlackjack(hand: dealerHand) {
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

    func dealCardToCurrentHand() -> Card? {
        guard roundInProgress else { return nil }
        if let card = deck.dealCard() {
            currentPlayerHand.addCard(card)
            if currentPlayerHand.isBusted {
                roundInProgress = false
            }
            return card
        }
        return nil
    }

    var playerTotal: Int {
        return currentPlayerHand.total
    }

    var visibleDealerTotal: Int {
        if dealerHand.cards.count >= 2 {
            let card = dealerHand.cards[1]
            return card.rank == .ace ? 11 : card.rank.value
        }
        return dealerHand.total
    }

    var dealerTotal: Int {
        return dealerHand.total
    }
}

extension BlackjackGame {
    func moveToNextHandIfPossible() {
        if currentHandIndexPublic < playerHands.count - 1 {
            currentHandIndex += 1
        } else {
            dealerPlay()
            roundInProgress = false
        }
    }
}
