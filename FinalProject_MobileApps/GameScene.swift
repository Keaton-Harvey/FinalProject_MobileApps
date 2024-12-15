//
//  GameScene.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/15/24.
//

import SpriteKit

class GameScene: SKScene {
    
    var game: BlackjackGame!  // Reference to the game logic

    let playerCardStart = CGPoint(x: 100, y: 150)
    let dealerCardStart = CGPoint(x: 100, y: 450)
    let deckPosition = CGPoint(x: 300, y: 300)

    private var dealerHiddenCard: SKSpriteNode?
    private var dealerHiddenCardRank: String?
    private var dealerHiddenCardSuit: String?

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.zPosition = -1
        background.size = frame.size
        addChild(background)
    }

    func createCardNode(rank: String, suit: String, faceUp: Bool = true) -> SKSpriteNode {
        let textureName = faceUp ? "\(rank)_of_\(suit)" : "back_of_cards"
        let cardNode = SKSpriteNode(imageNamed: textureName)
        cardNode.setScale(0.5)
        return cardNode
    }

    func dealCard(to position: CGPoint, rank: String, suit: String, faceUp: Bool = true, delay: TimeInterval = 0.0) {
        let cardNode = createCardNode(rank: rank, suit: suit, faceUp: faceUp)
        cardNode.position = deckPosition
        cardNode.zPosition = 10
        addChild(cardNode)

        let wait = SKAction.wait(forDuration: delay)
        let move = SKAction.move(to: position, duration: 0.5)
        let sequence = SKAction.sequence([wait, move])
        cardNode.run(sequence)

        if !faceUp {
            // Store hidden dealer card to flip later
            dealerHiddenCard = cardNode
            dealerHiddenCardRank = rank
            dealerHiddenCardSuit = suit
        }
    }

    func dealInitialHands() {
        // Deal the player's initial cards
        let playerCards = game.playerHands[0].cards
        for (i, card) in playerCards.enumerated() {
            let pos = CGPoint(x: playerCardStart.x + CGFloat(i)*30, y: playerCardStart.y)
            dealCard(to: pos, rank: card.rank.rawValue, suit: card.suit.name, faceUp: true, delay: Double(i)*0.5)
        }

        // Deal the dealer's initial cards
        let dealerCards = game.dealerHand.cards
        for (i, card) in dealerCards.enumerated() {
            let pos = CGPoint(x: dealerCardStart.x + CGFloat(i)*30, y: dealerCardStart.y)
            let faceUp = (i == 1) ? false : true
            dealCard(to: pos, rank: card.rank.rawValue, suit: card.suit.name, faceUp: faceUp, delay: Double(i+2)*0.5)

            if i == 1 && !faceUp {
                // Store dealer hidden card info
                dealerHiddenCardRank = card.rank.rawValue
                dealerHiddenCardSuit = card.suit.name
            }
        }
    }

    func flipDealerHiddenCard() {
        guard let hiddenCard = dealerHiddenCard,
              let rank = dealerHiddenCardRank,
              let suit = dealerHiddenCardSuit else {
            return
        }

        let halfFlip = SKAction.scaleX(to: 0.0, duration: 0.2)
        let changeTexture = SKAction.run {
            let frontTexture = SKTexture(imageNamed: "\(rank)_of_\(suit)")
            hiddenCard.texture = frontTexture
        }
        let halfFlipBack = SKAction.scaleX(to: hiddenCard.xScale * 1.0, duration: 0.2)

        let flipSequence = SKAction.sequence([halfFlip, changeTexture, halfFlipBack])
        hiddenCard.run(flipSequence)
    }

    func startGame() {
        dealInitialHands()
    }
}
