//
//  ChallengeViewController.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/14/24.
//

import UIKit
import SpriteKit
import CoreML

class ChallengeViewController: UIViewController {
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var hitButton: UIButton!
    @IBOutlet weak var standButton: UIButton!
    @IBOutlet weak var doubleDownButton: UIButton!
    @IBOutlet weak var splitButton: UIButton!

    // Changed: chipTrayView is now a UIScrollView to allow scrolling
    @IBOutlet weak var chipTrayView: UIScrollView!

    @IBOutlet weak var betAmountLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!

    var scene: GameScene!
    var game: BlackjackGame!

    var chipValues = [1, 5, 10, 25, 100, 500, 1000, 5000]
    var chipButtons: [UIButton] = []
    var handBets: [Int] = []

    var playerChips: Int {
        get { return UserDefaults.standard.integer(forKey: "chips") }
        set {
            UserDefaults.standard.set(newValue, forKey: "chips")
            updateBalanceLabel()
        }
    }

    var currentBet = 0 {
        didSet {
            updateBetAmountLabel()
        }
    }

    // Stats
    var winRate: Double {
        get { return UserDefaults.standard.double(forKey: "winRate") }
        set { UserDefaults.standard.set(newValue, forKey: "winRate") }
    }
    var totalBlackJacks: Int {
        get { return UserDefaults.standard.integer(forKey: "totalBlackJacks") }
        set { UserDefaults.standard.set(newValue, forKey: "totalBlackJacks") }
    }
    var decisionPercentage: Double {
        get { return UserDefaults.standard.double(forKey: "decisionPercentage") }
        set { UserDefaults.standard.set(newValue, forKey: "decisionPercentage") }
    }
    var averageBetSize: Double {
        get { return UserDefaults.standard.double(forKey: "averageBetSize") }
        set { UserDefaults.standard.set(newValue, forKey: "averageBetSize") }
    }
    var totalMoney: Int {
        get { return UserDefaults.standard.integer(forKey: "totalMoney") }
        set { UserDefaults.standard.set(newValue, forKey: "totalMoney") }
    }
    var reloads: Int {
        get { return UserDefaults.standard.integer(forKey: "reloads") }
        set { UserDefaults.standard.set(newValue, forKey: "reloads") }
    }

    struct PlacedChip {
        let value: Int
        let chipNode: UIImageView
        let originalPosition: CGPoint
    }

    var betChipsStack: [PlacedChip] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if playerChips <= 0 {
            playerChips = 500
            reloads += 1
        }

        let chosenNumberOfDecks = UserDefaults.standard.integer(forKey: "numOfDecks")
        let dealerHitsSoft17 = UserDefaults.standard.integer(forKey: "hitOrStand")

        let decks = (chosenNumberOfDecks > 0) ? chosenNumberOfDecks : 1
        let dh_s17 = dealerHitsSoft17

        game = BlackjackGame(numberOfDecks: decks, dealerHitsSoft17: dh_s17)
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        scene.game = game
        skView.presentScene(scene)

        NotificationCenter.default.addObserver(self, selector: #selector(showDealButton), name: NSNotification.Name("ShowDealButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showActions), name: NSNotification.Name("ShowActions"), object: nil)

        setupChipTray()
        updateChipsAvailability()

        hitButton.isHidden = true
        standButton.isHidden = true
        doubleDownButton.isHidden = true
        splitButton.isHidden = true

        updateBetAmountLabel()
        updateBalanceLabel()
    }

    func setupChipTray() {
        // Arrange all chips horizontally in the scroll view
        let buttonSize: CGFloat = 80
        let spacing: CGFloat = 20
        var xOffset: CGFloat = spacing

        for i in 0..<chipValues.count {
            let chipButton = UIButton(type: .custom)
            chipButton.setImage(UIImage(named: "chip_\(chipValues[i])"), for: .normal)
            chipButton.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipButton.tag = i
            chipButton.frame = CGRect(x: xOffset, y: (chipTrayView.bounds.height - buttonSize) / 2,
                                      width: buttonSize, height: buttonSize)
            chipTrayView.addSubview(chipButton)
            chipButtons.append(chipButton)
            xOffset += buttonSize + spacing
        }

        chipTrayView.contentSize = CGSize(width: xOffset, height: chipTrayView.bounds.height)
        chipTrayView.showsHorizontalScrollIndicator = true
        chipTrayView.isScrollEnabled = true
    }

    @objc func chipTapped(_ sender: UIButton) {
        let chipIndex = sender.tag
        let chipValue = chipValues[chipIndex]
        if playerChips < chipValue {
            return
        }

        // Convert chipButton frame to main view coordinates
        let chipButtonFrameInView = self.view.convert(sender.frame, from: self.chipTrayView)
        placeChipInPot(chipValue: chipValue, fromPosition: chipButtonFrameInView.center)
    }

    func placeChipInPot(chipValue: Int, fromPosition: CGPoint) {
        currentBet += chipValue
        playerChips -= chipValue

        let chipImageView = UIImageView(image: UIImage(named: "chip_\(chipValue)"))
        chipImageView.frame = CGRect(x: fromPosition.x - 40, y: fromPosition.y - 40, width: 80, height: 80)
        view.addSubview(chipImageView)

        UIView.animate(withDuration: 0.5) {
            chipImageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        } completion: { _ in
            let placedChip = PlacedChip(value: chipValue, chipNode: chipImageView, originalPosition: fromPosition)
            self.betChipsStack.append(placedChip)
        }

        updateChipsAvailability()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.view)
        let centerPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        let radius: CGFloat = 50.0
        if distance(from: location, to: centerPoint) < radius {
            removeLastChipFromPot()
        }
    }

    func removeLastChipFromPot() {
        guard let lastChip = betChipsStack.popLast() else { return }
        let chipValue = lastChip.value

        currentBet -= chipValue
        playerChips += chipValue

        UIView.animate(withDuration: 0.5, animations: {
            lastChip.chipNode.center = lastChip.originalPosition
        }, completion: { _ in
            lastChip.chipNode.removeFromSuperview()
        })

        updateChipsAvailability()
    }

    func updateChipsAvailability() {
        for (i, chipButton) in chipButtons.enumerated() {
            let chipValue = chipValues[i]
            if playerChips < chipValue {
                chipButton.alpha = 0.5
                chipButton.isUserInteractionEnabled = false
            } else {
                chipButton.alpha = 1.0
                chipButton.isUserInteractionEnabled = true
            }
        }
    }

    @objc func showDealButton() {
        dealButton.isHidden = false
        hitButton.isHidden = true
        standButton.isHidden = true
        doubleDownButton.isHidden = true
        splitButton.isHidden = true
    }

    @objc func showActions() {
        hitButton.isHidden = false
        standButton.isHidden = false
        updateActionButtonsForGameState()
    }

    func updateActionButtonsForGameState() {
        doubleDownButton.isHidden = !game.currentHandCanDoubleDown() || playerChips < currentBet
        splitButton.isHidden = !game.playerCanSplit()
    }
    
    func moveToNextHandOrFinish() {
        // If current hand is done (busted or stand), move on:
        if game.currentHandIndexPublic < game.playerHands.count - 1 {
            // Move to next hand
            game.moveToNextHandIfPossible()
            // Deal second card if needed:
            if self.game.currentHand.cards.count == 1 {
                if let _ = self.game.dealCardToCurrentHand() {
                    self.scene.playerHitUpdate {
                        self.updateActionButtonsForGameState()
                    }
                }
            }
            self.updateActionButtonsForGameState()
        } else {
            // No more hands, dealer plays
            checkRoundStatus()
        }
    }

    @IBAction func dealButtonTapped(_ sender: Any) {
        if currentBet <= 0 { return }
        dealButton.isHidden = true
        // Assign initial bets array
        handBets = [currentBet]
        game.startNewRound()
        scene.startGame()
    }

    @IBAction func hitButtonTapped(_ sender: Any) {
            game.playerHit()
            scene.playerHitUpdate { [weak self] in
                guard let self = self else { return }
                if self.game.currentHand.isBusted {
                    // Hand busts. Move to next hand if any:
                    self.moveToNextHandOrFinish()
                } else {
                    self.updateActionButtonsForGameState()
                }
            }
        }

    @IBAction func standButtonTapped(_ sender: Any) {
        game.playerStand()
        moveToNextHandOrFinish()
    }

    @IBAction func doubleDownTapped(_ sender: Any) {
        if playerChips >= handBets[game.currentHandIndexPublic] {
            playerChips -= handBets[game.currentHandIndexPublic]
            handBets[game.currentHandIndexPublic] *= 2
        } else {
            return
        }
        
        game.playerDoubleDown()
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            if self.game.currentHand.isBusted {
                self.moveToNextHandOrFinish()
            } else {
                self.moveToNextHandOrFinish()
            }
        }
    }

    @IBAction func splitTapped(_ sender: Any) {
        if game.playerCanSplit() {
            game.playerSplit()
            scene.repositionPlayerHands { [weak self] in
                guard let self = self else { return }
                if self.game.playerHands.count == 2 && self.game.currentHand.cards.count == 1 {
                    if let _ = self.game.dealCardToCurrentHand() {
                        self.scene.playerHitUpdate {
                            self.updateActionButtonsForGameState()
                        }
                    } else {
                        self.updateActionButtonsForGameState()
                    }
                } else {
                    self.updateActionButtonsForGameState()
                }
            }
        }
    }

    func checkRoundStatus() {
            if game.roundFinished() {
                scene.dealerDoneUpdate()
                let results = game.outcomes()
                var netWinLoss = 0
                for (i, outcome) in results.enumerated() {
                    let betForThisHand = handBets[i]
                    netWinLoss += applyOutcome(outcome: outcome, bet: betForThisHand)
                }
                totalMoney += netWinLoss
                currentBet = 0
                handBets.removeAll()
                // ... clear chips from pot etc.
            } else {
                updateActionButtonsForGameState()
            }
        }

    func applyOutcome(outcome: GameOutcome, bet: Int) -> Int {
        switch outcome {
        case .playerBlackjack:
            let winnings = Int(Double(bet) * 2.5)
            let netGain = winnings - bet
            playerChips += winnings
            return netGain
        case .playerWin:
            let winnings = bet * 2
            let netGain = bet
            playerChips += winnings
            return netGain
        case .playerLose:
            return -bet
        case .push:
            playerChips += bet
            return 0
        }
    }

    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }

    func updateBetAmountLabel() {
        betAmountLabel.text = "Bet: $\(currentBet)"
    }

    func updateBalanceLabel() {
        balanceLabel.text = "Balance: $\(playerChips)"
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
