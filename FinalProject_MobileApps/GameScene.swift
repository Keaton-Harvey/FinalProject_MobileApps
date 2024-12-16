//
//  GameScene.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/15/24.
//


/*
 Sets up all the game scene logic with cards, decks, and using logic from blackjack
 game to make it more fluid
 */

import SpriteKit

class GameScene: SKScene {

    var game: BlackjackGame!

    let cardSpacing: CGFloat = 80
    let playerY: CGFloat = 250
    let dealerY: CGFloat = 700
    let deckPosition = CGPoint(x: 320, y: 450)

    var maxCardsPerRow = 4
    let lineSpacing: CGFloat = 100

    private var dealerHiddenCard: SKSpriteNode?
    private var dealerHiddenCardRank: String?
    private var dealerHiddenCardSuit: String?

    private var playerHandsNodes: [[SKSpriteNode]] = [[]]
    private var dealerCardNodes: [SKSpriteNode] = []

    private var playerTotalLabels: [SKLabelNode] = []
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

        dealerTotalLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        dealerTotalLabel.fontSize = 24
        dealerTotalLabel.fontColor = .white
        dealerTotalLabel.position = CGPoint(x: frame.size.width/2, y: dealerY + 75)
        dealerTotalLabel.isHidden = true
        addChild(dealerTotalLabel)

        outcomeLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        outcomeLabel.fontSize = 30
        outcomeLabel.fontColor = .white
        outcomeLabel.lineBreakMode = .byWordWrapping
        outcomeLabel.preferredMaxLayoutWidth = frame.size.width * 0.8
        outcomeLabel.numberOfLines = 2
        outcomeLabel.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2 + 100)
        outcomeLabel.zPosition = 20
        outcomeLabel.isHidden = true
        addChild(outcomeLabel)
    }

    func createCardNode(rank: String, suit: String, faceUp: Bool = true) -> SKSpriteNode {
        let textureName = faceUp ? "\(rank)_of_\(suit)" : "back_of_cards"
        let cardNode = SKSpriteNode(imageNamed: textureName)
        cardNode.setScale(0.04)
        cardNode.anchorPoint = CGPoint(x:0.5,y:0.5)
        cardNode.position = deckPosition
        cardNode.zPosition = 10
        return cardNode
    }

    func createDeckNode() -> SKSpriteNode {
        let deckNode = SKSpriteNode(imageNamed: "back_of_cards")
        deckNode.setScale(0.04)
        deckNode.anchorPoint = CGPoint(x:0.5,y:0.5)
        return deckNode
    }

    func startGame() {
        clearAll()
        playerHandsNodes = [[]]
        dealInitialCards {
            self.createOrUpdatePlayerLabels()
            self.dealerTotalLabel.isHidden = false
            self.updateTotalsAfterAnimation(false)
            NotificationCenter.default.post(name: NSNotification.Name("ShowActions"), object: nil)
        }
    }

    func clearAll() {
        outcomeLabel.isHidden = true
        dealerTotalLabel.isHidden = true
        dealerTotalLabel.text = ""

        for lbl in playerTotalLabels {
            lbl.removeFromParent()
        }
        playerTotalLabels.removeAll()

        for handNodes in playerHandsNodes {
            for card in handNodes {
                card.removeFromParent()
            }
        }
        playerHandsNodes.removeAll()
        playerHandsNodes = [[]]

        dealerCardNodes.forEach { $0.removeFromParent() }
        dealerCardNodes.removeAll()
        dealerHiddenCard = nil
        dealerHiddenCardRank = nil
        dealerHiddenCardSuit = nil
    }

    func dealInitialCards(completion: @escaping ()->Void) {
        let pHand = game.playerHands[0].cards
        let dHand = game.dealerHand.cards

        guard pHand.count == 2, dHand.count == 2 else {
            completion()
            return
        }

        dealOneCardToPlayerHand(handIndex: 0, rank: pHand[0].rank.rawValue, suit: pHand[0].suit.name, faceUp: true) {
            self.dealOneCardToDealer(rank: dHand[0].rank.rawValue, suit: dHand[0].suit.name, faceUp: false) {
                self.dealOneCardToPlayerHand(handIndex: 0, rank: pHand[1].rank.rawValue, suit: pHand[1].suit.name, faceUp: true) {
                    self.dealOneCardToDealer(rank: dHand[1].rank.rawValue, suit: dHand[1].suit.name, faceUp: true) {
                        completion()
                    }
                }
            }
        }
    }

    func dealOneCardToPlayerHand(handIndex: Int, rank: String, suit: String, faceUp: Bool, completion: @escaping ()->Void) {
        let cardNode = createCardNode(rank: rank, suit: suit, faceUp: faceUp)
        addChild(cardNode)
        if handIndex >= playerHandsNodes.count {
            playerHandsNodes.append([])
        }
        playerHandsNodes[handIndex].append(cardNode)
        repositionPlayerHands(completion: completion)
    }

    func dealOneCardToDealer(rank: String, suit: String, faceUp: Bool, completion: @escaping ()->Void) {
        let cardNode = createCardNode(rank: rank, suit: suit, faceUp: faceUp)
        addChild(cardNode)
        dealerCardNodes.append(cardNode)

        if !faceUp && dealerHiddenCard == nil {
            dealerHiddenCard = cardNode
            dealerHiddenCardRank = rank
            dealerHiddenCardSuit = suit
        }

        repositionDealer(completion: completion)
    }

    func playerHitUpdate(completion: @escaping ()->Void) {
        let currentHandIndex = game.currentHandIndexPublic
        let playerCards = game.playerHands[currentHandIndex].cards
        let nodes = playerHandsNodes[currentHandIndex]

        if playerCards.count > nodes.count {
            let card = playerCards.last!
            let cardNode = createCardNode(rank: card.rank.rawValue, suit: card.suit.name, faceUp: true)
            addChild(cardNode)
            playerHandsNodes[currentHandIndex].append(cardNode)
            repositionPlayerHands {
                self.updateTotalsAfterAnimation(false)
                completion()
            }
        } else {
            repositionPlayerHands {
                self.updateTotalsAfterAnimation(false)
                completion()
            }
        }
    }

    func handleSplitVisual() {
        if game.playerHands.count == 2 && playerHandsNodes.count == 1 {
            let firstHandNodes = playerHandsNodes[0]
            if firstHandNodes.count >= 2 {
                let secondCardNode = firstHandNodes[1]
                playerHandsNodes[0].remove(at: 1)
                playerHandsNodes.append([secondCardNode])
            }
        }

        if game.playerHands.count > 1 {
            maxCardsPerRow = 2
        } else {
            maxCardsPerRow = 4
        }

        createOrUpdatePlayerLabels()
    }

    func createOrUpdatePlayerLabels() {
        for lbl in playerTotalLabels {
            lbl.removeFromParent()
        }
        playerTotalLabels.removeAll()

        let handCount = game.playerHands.count
        for hIndex in 0..<handCount {
            let label = SKLabelNode(fontNamed: "Arial-BoldMT")
            label.fontSize = 24
            label.fontColor = .white
            label.isHidden = false

            let centerX: CGFloat
            if handCount == 1 {
                centerX = frame.size.width/2
            } else {
                let offsetX: CGFloat = 100
                centerX = (hIndex == 0) ? (frame.size.width/2 - offsetX) : (frame.size.width/2 + offsetX)
            }

            label.position = CGPoint(x: centerX, y: playerY - 100)
            addChild(label)
            playerTotalLabels.append(label)
        }
    }

    func repositionPlayerHands(completion: @escaping ()->Void) {
        handleSplitVisual()

        let handCount = game.playerHands.count
        var actions: [SKAction] = []

        for (hIndex, handNodes) in playerHandsNodes.enumerated() {
            let centerX: CGFloat
            if handCount == 1 {
                centerX = frame.size.width/2
            } else {
                let offsetX: CGFloat = 100
                centerX = (hIndex == 0) ? (frame.size.width/2 - offsetX) : (frame.size.width/2 + offsetX)
            }

            let count = handNodes.count
            let rows = (count - 1) / maxCardsPerRow + 1
            for (i, cardNode) in handNodes.enumerated() {
                let rowIndex = i / maxCardsPerRow
                let indexInRow = i % maxCardsPerRow
                let yPos = playerY + CGFloat(rowIndex)*lineSpacing
                let rowCount = (rowIndex == rows-1) ? (count - rowIndex*maxCardsPerRow) : maxCardsPerRow
                let totalWidth = CGFloat(rowCount - 1)*cardSpacing
                let startX = centerX - totalWidth/2
                let finalPos = CGPoint(x: startX + CGFloat(indexInRow)*cardSpacing, y: yPos)
                let move = SKAction.move(to: finalPos, duration: 0.4)
                actions.append(SKAction.run {
                    cardNode.run(move)
                })
            }
        }

        let totalWait = 0.4
        run(SKAction.sequence([
            SKAction.group(actions),
            SKAction.wait(forDuration: totalWait),
            SKAction.run {
                completion()
            }
        ]))
    }

    func repositionDealer(completion: @escaping ()->Void) {
        let count = dealerCardNodes.count
        let dealerMaxCardsPerRow = 4
        let rows = (count - 1) / dealerMaxCardsPerRow + 1
        var actions: [SKAction] = []
        for (i, cardNode) in dealerCardNodes.enumerated() {
            let rowIndex = i / dealerMaxCardsPerRow
            let indexInRow = i % dealerMaxCardsPerRow
            let yPos = dealerY - CGFloat(rowIndex)*lineSpacing
            let rowCount = (rowIndex == rows-1) ? (count - rowIndex*dealerMaxCardsPerRow) : dealerMaxCardsPerRow
            let totalWidth = CGFloat(rowCount - 1)*cardSpacing
            let startX = frame.size.width/2 - totalWidth/2
            let move = SKAction.move(to: CGPoint(x: startX + CGFloat(indexInRow)*cardSpacing, y: yPos), duration: 0.4)
            actions.append(SKAction.run {
                cardNode.run(move)
            })
        }
        let totalWait = 0.4
        run(SKAction.sequence([SKAction.group(actions),
                               SKAction.wait(forDuration: totalWait),
                               SKAction.run(completion)]))
    }

    func dealerDoneUpdate() {
        flipDealerHiddenCard {
            let dealerCards = self.game.dealerHand.cards
            if dealerCards.count > self.dealerCardNodes.count {
                self.dealExtraDealerCards(cards: Array(dealerCards[self.dealerCardNodes.count..<dealerCards.count])) {
                    self.updateTotalsAfterAnimation(true)
                    self.showOutcomeMessage()
                }
            } else {
                self.repositionDealer {
                    self.updateTotalsAfterAnimation(true)
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
            let cardNode = self.createCardNode(rank: card.rank.rawValue, suit: card.suit.name, faceUp: true)
            self.addChild(cardNode)
            self.dealerCardNodes.append(cardNode)
            self.repositionDealer {
                if index == cards.count-1 {
                    completion()
                } else {
                    dealNext(index: index+1)
                }
            }
        }
        dealNext(index: 0)
    }

    func updateTotalsAfterAnimation(_ fullDealer: Bool) {
        for (i, hand) in game.playerHands.enumerated() {
            if i < playerTotalLabels.count {
                playerTotalLabels[i].text = "Player: \(hand.total)"
            }
        }

        if fullDealer {
            dealerTotalLabel.text = "Dealer: \(game.dealerTotal)"
        } else {
            dealerTotalLabel.text = "Dealer: \(game.visibleDealerTotal)"
        }
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
        if game.playerHands.count > 1 {
            var message = ""
            for (i, outcome) in results.enumerated() {
                let handNum = i+1
                let outcomeText: String
                switch outcome {
                case .playerWin:
                    outcomeText = "Hand \(handNum): You Won!"
                case .playerLose:
                    outcomeText = "Hand \(handNum): You Lost."
                case .push:
                    outcomeText = "Hand \(handNum): Push!"
                case .playerBlackjack:
                    outcomeText = "Hand \(handNum): Blackjack! You Won!"
                }
                message += outcomeText + "\n\n"
            }
            outcomeLabel.text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
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
        }

        outcomeLabel.isHidden = false

        let wait = SKAction.wait(forDuration: 2.0)
        let cleanUp = SKAction.run {
            self.animateCardsBackToDeck()
        }
        run(SKAction.sequence([wait, cleanUp]))
    }

    func showBustedMessage() {
        outcomeLabel.text = "You Busted!"
        outcomeLabel.isHidden = false
        let wait = SKAction.wait(forDuration: 2.0)
        let cleanUp = SKAction.run {
            self.animateCardsBackToDeck()
        }
        run(SKAction.sequence([wait, cleanUp]))
    }

    func animateCardsBackToDeck() {
        let allPlayerCards = playerHandsNodes.flatMap { $0 }
        let allCards = allPlayerCards + dealerCardNodes

        if allCards.isEmpty {
            for lbl in self.playerTotalLabels {
                lbl.removeFromParent()
            }
            self.playerTotalLabels.removeAll()
            self.dealerTotalLabel.text = ""
            self.dealerTotalLabel.isHidden = true
            NotificationCenter.default.post(name: NSNotification.Name("ShowDealButton"), object: nil)
            return
        }

        let moveActions = allCards.map { _ in SKAction.move(to: deckPosition, duration: 0.5) }
        let group = SKAction.group(moveActions)
        let removeAll = SKAction.run {
            for card in allCards {
                card.removeFromParent()
            }
            self.playerHandsNodes.removeAll()
            self.playerHandsNodes = [[]]
            self.dealerCardNodes.removeAll()
            self.outcomeLabel.isHidden = true
            for lbl in self.playerTotalLabels {
                lbl.removeFromParent()
            }
            self.playerTotalLabels.removeAll()
            self.dealerTotalLabel.text = ""
            self.dealerTotalLabel.isHidden = true
            NotificationCenter.default.post(name: NSNotification.Name("ShowDealButton"), object: nil)
        }
        run(SKAction.sequence([group, removeAll]))
    }
}
