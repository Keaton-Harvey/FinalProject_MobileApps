import SpriteKit

class GameScene: SKScene {
    
    var game: BlackjackGame!

    let cardSpacing: CGFloat = 110
    let playerY: CGFloat = 250
    let dealerY: CGFloat = 700
    let deckPosition = CGPoint(x: 320, y: 450)

    private var dealerHiddenCard: SKSpriteNode?
    private var dealerHiddenCardRank: String?
    private var dealerHiddenCardSuit: String?

    private var playerCardNodes: [SKSpriteNode] = []
    private var dealerCardNodes: [SKSpriteNode] = []

    private var playerTotalLabel: SKLabelNode!
    private var dealerTotalLabel: SKLabelNode!
    private var outcomeLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        background.zPosition = -1
        background.size = frame.size
        addChild(background)

        let deckNode = createDeckNode()
        deckNode.position = deckPosition
        deckNode.zPosition = 5
        addChild(deckNode)

        playerTotalLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        playerTotalLabel.fontSize = 24
        playerTotalLabel.fontColor = .white
        playerTotalLabel.position = CGPoint(x: frame.size.width/2, y: playerY - 100)
        playerTotalLabel.isHidden = true
        addChild(playerTotalLabel)

        dealerTotalLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        dealerTotalLabel.fontSize = 24
        dealerTotalLabel.fontColor = .white
        dealerTotalLabel.position = CGPoint(x: frame.size.width/2, y: dealerY + 75)
        dealerTotalLabel.isHidden = true
        addChild(dealerTotalLabel)

        outcomeLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        outcomeLabel.fontSize = 30
        outcomeLabel.fontColor = .yellow
        outcomeLabel.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        outcomeLabel.zPosition = 20
        outcomeLabel.isHidden = true
        addChild(outcomeLabel)
    }

    func createCardNode(rank: String, suit: String, faceUp: Bool = true) -> SKSpriteNode {
        let textureName = faceUp ? "\(rank)_of_\(suit)" : "back_of_cards"
        let cardNode = SKSpriteNode(imageNamed: textureName)
        cardNode.setScale(0.045)
        cardNode.anchorPoint = CGPoint(x:0.5,y:0.5)
        cardNode.position = deckPosition
        cardNode.zPosition = 10
        return cardNode
    }

    func createDeckNode() -> SKSpriteNode {
        let deckNode = SKSpriteNode(imageNamed: "back_of_cards")
        deckNode.setScale(0.045)
        deckNode.anchorPoint = CGPoint(x:0.5,y:0.5)
        return deckNode
    }

    func startGame() {
        clearAll()
        dealInitialCards {
            self.playerTotalLabel.isHidden = false
            self.dealerTotalLabel.isHidden = false
            self.updateTotalsAfterAnimation(fullDealer: false)
            // Show hit/stand after initial deal
            NotificationCenter.default.post(name: NSNotification.Name("ShowActions"), object: nil)
        }
    }

    func clearAll() {
        outcomeLabel.isHidden = true
        playerTotalLabel.isHidden = true
        dealerTotalLabel.isHidden = true
        playerTotalLabel.text = ""
        dealerTotalLabel.text = ""

        playerCardNodes.forEach { $0.removeFromParent() }
        dealerCardNodes.forEach { $0.removeFromParent() }
        playerCardNodes.removeAll()
        dealerCardNodes.removeAll()
    }

    func dealInitialCards(completion: @escaping ()->Void) {
        let pCards = game.playerHands[0].cards
        let dCards = game.dealerHand.cards

        // P card1
        dealOneCard(isPlayer: true, rank: pCards[0].rank.rawValue, suit: pCards[0].suit.name, faceUp: true, delay: 0.0) {
            // D card1(hidden)
            self.dealerHiddenCardRank = dCards[0].rank.rawValue
            self.dealerHiddenCardSuit = dCards[0].suit.name
            self.dealOneCard(isPlayer: false, rank: dCards[0].rank.rawValue, suit: dCards[0].suit.name, faceUp: false, delay: 0.0) {
                // P card2
                self.dealOneCard(isPlayer: true, rank: pCards[1].rank.rawValue, suit: pCards[1].suit.name, faceUp: true, delay: 0.0) {
                    // D card2(shown)
                    self.dealOneCard(isPlayer: false, rank: dCards[1].rank.rawValue, suit: dCards[1].suit.name, faceUp: true, delay: 0.0) {
                        completion()
                    }
                }
            }
        }
    }

    func dealOneCard(isPlayer: Bool, rank: String, suit: String, faceUp: Bool, delay: TimeInterval, completion: @escaping ()->Void) {
        let cardNode = createCardNode(rank: rank, suit: suit, faceUp: faceUp)
        addChild(cardNode)
        if isPlayer {
            playerCardNodes.append(cardNode)
        } else {
            dealerCardNodes.append(cardNode)
            if !faceUp {
                dealerHiddenCard = cardNode
            }
        }

        // Immediately position card at deck, then reposition all cards
        // Move from deck quicker (no wait) but travel slower: let's just place card instantly and reposition all
        // The user asked for no other changes except the times: We'll just no wait and rely on reposition.
        repositionCardsAfterDealing(isPlayer: isPlayer, completion: completion)
    }

    func repositionCardsAfterDealing(isPlayer: Bool, completion: @escaping ()->Void) {
        let nodes = isPlayer ? playerCardNodes : dealerCardNodes
        let count = nodes.count
        for (i, cardNode) in nodes.enumerated() {
            let finalPos = positionForCard(index: i, count: count, y: isPlayer ? playerY : dealerY)
            // Move slower: previously 0.2, let's do 0.4 to travel slower
            let move = SKAction.move(to: finalPos, duration: 0.4)
            cardNode.run(move)
        }
        // After all moves done
        let totalWait = 0.4 // after reposition done
        run(SKAction.sequence([SKAction.wait(forDuration: totalWait), SKAction.run(completion)]))
    }

    func playerHitUpdate() {
        let playerCards = game.playerHands[0].cards
        if playerCards.count > playerCardNodes.count {
            let card = playerCards.last!
            let cardNode = createCardNode(rank: card.rank.rawValue, suit: card.suit.name, faceUp: true)
            addChild(cardNode)
            playerCardNodes.append(cardNode)
            repositionCardsAfterDealing(isPlayer: true) {
                self.updateTotalsAfterAnimation(fullDealer: false)
            }
        } else {
            repositionCardsAfterDealing(isPlayer: true) {
                self.updateTotalsAfterAnimation(fullDealer: false)
            }
        }
    }

    func dealerDoneUpdate() {
        flipDealerHiddenCard {
            let dealerCards = self.game.dealerHand.cards
            if dealerCards.count > self.dealerCardNodes.count {
                // Extra dealer cards
                self.dealExtraDealerCards(cards: Array(dealerCards[self.dealerCardNodes.count..<dealerCards.count])) {
                    self.updateTotalsAfterAnimation(fullDealer: true)
                    self.showOutcomeMessage()
                }
            } else {
                self.repositionCardsAfterDealing(isPlayer: false) {
                    self.updateTotalsAfterAnimation(fullDealer: true)
                    self.showOutcomeMessage()
                }
            }
        }
    }

    func dealExtraDealerCards(cards: [Card], completion: @escaping ()->Void) {
        func dealNext(index: Int) {
            if index >= cards.count {
                completion()
                return
            }
            let card = cards[index]
            let cardNode = createCardNode(rank: card.rank.rawValue, suit: card.suit.name, faceUp: true)
            addChild(cardNode)
            dealerCardNodes.append(cardNode)
            repositionCardsAfterDealing(isPlayer: false) {
                if index == cards.count-1 {
                    completion()
                } else {
                    dealNext(index: index+1)
                }
            }
        }
        dealNext(index: 0)
    }

    func updateTotalsAfterAnimation(fullDealer: Bool) {
        playerTotalLabel.text = "Player: \(game.playerTotal)"
        if fullDealer {
            dealerTotalLabel.text = "Dealer: \(game.dealerTotal)"
        } else {
            dealerTotalLabel.text = "\(game.visibleDealerTotal)"
        }
    }

    func positionForCard(index: Int, count: Int, y: CGFloat) -> CGPoint {
        let totalWidth = CGFloat(count - 1)*cardSpacing
        let startX = frame.size.width/2 - totalWidth/2
        return CGPoint(x: startX + CGFloat(index)*cardSpacing, y: y)
    }

    func flipDealerHiddenCard(completion: @escaping ()->Void) {
        guard let hiddenCard = dealerHiddenCard,
              let rank = dealerHiddenCardRank,
              let suit = dealerHiddenCardSuit else {
            completion()
            return
        }

        let originalScaleX = hiddenCard.xScale
        let halfFlip = SKAction.scaleX(to: 0.0, duration: 0.1)
        let changeTexture = SKAction.run {
            let frontTexture = SKTexture(imageNamed: "\(rank)_of_\(suit)")
            hiddenCard.texture = frontTexture
        }
        let halfFlipBack = SKAction.scaleX(to: originalScaleX, duration: 0.1)
        let done = SKAction.run(completion)
        hiddenCard.run(SKAction.sequence([halfFlip, changeTexture, halfFlipBack, done]))
    }

    func showOutcomeMessage() {
        let results = game.outcomes()
        let outcome = results.first ?? .push
        var message = ""
        switch outcome {
        case .playerWin:
            message = "You Won!"
        case .playerLose:
            message = "You Lost."
        case .push:
            message = "Push!"
        case .playerBlackjack:
            message = "Blackjack! You Won!"
        }

        outcomeLabel.text = message
        outcomeLabel.isHidden = false

        let wait = SKAction.wait(forDuration: 2.0)
        let cleanUp = SKAction.run {
            self.animateCardsBackToDeck()
        }
        run(SKAction.sequence([wait, cleanUp]))
    }

    func animateCardsBackToDeck() {
        let allCards = playerCardNodes + dealerCardNodes
        let moveActions = allCards.map { _ in SKAction.move(to: deckPosition, duration: 0.5) }
        let group = SKAction.group(moveActions)
        let removeAll = SKAction.run {
            for card in allCards {
                card.removeFromParent()
            }
            self.playerCardNodes.removeAll()
            self.dealerCardNodes.removeAll()
            self.outcomeLabel.isHidden = true
            self.playerTotalLabel.text = ""
            self.dealerTotalLabel.text = ""
            self.playerTotalLabel.isHidden = true
            self.dealerTotalLabel.isHidden = true
            NotificationCenter.default.post(name: NSNotification.Name("ShowDealButton"), object: nil)
        }
        run(SKAction.sequence([group, removeAll]))
    }
}
