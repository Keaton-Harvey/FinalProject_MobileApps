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
    @IBOutlet weak var chipTrayView: UIScrollView!
    @IBOutlet weak var betAmountLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!

    var scene: GameScene!
    var game: BlackjackGame!

    var chipValues = [1, 5, 10, 25, 100, 500, 1000, 5000]
    var chipButtons: [UIButton] = []

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

    var handBets: [Int] = []
    var betChipsStack: [PlacedChip] = []

    var bettingOpen = true

    // Arrays to store stats over time
    // Win: 1 for win, 0 for lose/push
    // Decisions: 1 for correct, 0 for incorrect
    // Bets: store each round's initial bet
    var winArray: [Int] = []
    var decisionArray: [Int] = []
    var betArray: [Int] = []
    
    // Total money as a running total
    var totalMoney: Int {
        get { return UserDefaults.standard.integer(forKey: "totalMoney") }
        set { UserDefaults.standard.set(newValue, forKey: "totalMoney") }
    }
    
    var totalBlackJacks = UserDefaults.standard.integer(forKey: "totalBlackJacks")

    var pipelineModel: BlackJackPipeline?

    struct PlacedChip {
        let value: Int
        let chipNode: UIImageView
        let originalPosition: CGPoint
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load arrays from UserDefaults or start empty
        if let wArr = UserDefaults.standard.array(forKey: "winArray") as? [Int] {
            winArray = wArr
        }
        if let dArr = UserDefaults.standard.array(forKey: "decisionArray") as? [Int] {
            decisionArray = dArr
        }
        if let bArr = UserDefaults.standard.array(forKey: "betArray") as? [Int] {
            betArray = bArr
        }

        if playerChips <= 0 {
            playerChips = 500
            let reloads = UserDefaults.standard.integer(forKey: "reloads")
            UserDefaults.standard.set(reloads + 1, forKey: "reloads")
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

        pipelineModel = try? BlackJackPipeline(configuration: MLModelConfiguration())
    }

    func setupChipTray() {
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
        guard bettingOpen else { return }
        let chipIndex = sender.tag
        let chipValue = chipValues[chipIndex]
        if playerChips < chipValue {
            return
        }

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
        guard bettingOpen else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.view)
        let centerPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        let radius: CGFloat = 50.0
        if distance(from: location, to: centerPoint) < radius {
            removeLastChipFromPot()
        }
    }

    func removeLastChipFromPot() {
        guard bettingOpen else { return }
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
        doubleDownButton.isHidden = !game.currentHandCanDoubleDown() || playerChips < currentBetForCurrentHand()
        splitButton.isHidden = !game.playerCanSplit()
    }

    func currentBetForCurrentHand() -> Int {
        if game.currentHandIndexPublic < handBets.count {
            return handBets[game.currentHandIndexPublic]
        }
        return currentBet // fallback
    }

    @IBAction func dealButtonTapped(_ sender: Any) {
        if currentBet <= 0 {
            return
        }
        bettingOpen = false
        dealButton.isHidden = true
        handBets = [currentBet]

        // Add this round's bet to betArray
        betArray.append(currentBet)
        UserDefaults.standard.set(betArray, forKey: "betArray")

        game.startNewRound()
        scene.startGame()
    }

    @IBAction func hitButtonTapped(_ sender: Any) {
        let userAction = 0 // Hit
        checkDecisionCorrectness(userAction: userAction)

        game.playerHit()
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            if self.game.currentHand.isBusted {
                self.moveToNextHandOrFinish()
            } else {
                self.updateActionButtonsForGameState()
            }
        }
    }

    @IBAction func standButtonTapped(_ sender: Any) {
        let userAction = 1 // Stand
        checkDecisionCorrectness(userAction: userAction)

        game.playerStand()
        moveToNextHandOrFinish()
    }

    @IBAction func doubleDownTapped(_ sender: Any) {
        let userAction = 2 // Double Down
        checkDecisionCorrectness(userAction: userAction)

        let extraBet = handBets[game.currentHandIndexPublic]
        if playerChips >= extraBet {
            playerChips -= extraBet
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
        let userAction = 3 // Split
        checkDecisionCorrectness(userAction: userAction)

        if game.playerCanSplit() {
            let originalBetForThisHand = handBets[game.currentHandIndexPublic]
            if playerChips < originalBetForThisHand {
                return
            }
            playerChips -= originalBetForThisHand
            handBets.insert(originalBetForThisHand, at: game.currentHandIndexPublic+1)

            game.playerSplit()
            scene.repositionPlayerHands { [weak self] in
                guard let self = self else { return }
                // Splitting creates an additional hand, we do not record anything special for win rate yet
                // We'll do that after the round. Just move on.
                if self.game.playerHands.count > 1 && self.game.currentHand.cards.count == 1 {
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

    func moveToNextHandOrFinish() {
        if game.currentHandIndexPublic < game.playerHands.count - 1 {
            game.moveToNextHandIfPossible()
            if self.game.currentHand.cards.count == 1 {
                if let _ = self.game.dealCardToCurrentHand() {
                    self.scene.playerHitUpdate {
                        self.updateActionButtonsForGameState()
                    }
                }
            }
            self.updateActionButtonsForGameState()
        } else {
            checkRoundStatus()
        }
        updateChipsAvailability()
    }

    func checkRoundStatus() {
        if game.roundFinished() {
            scene.dealerDoneUpdate()
            let results = game.outcomes()
            var netWinLoss = 0
            for outcome in results {
                let betForThisHand = handBets.removeFirst()
                let diff = applyOutcome(outcome: outcome, bet: betForThisHand)
                netWinLoss += diff
                // Win=1, Lose=0, Push=0 in winArray
                if outcome == .playerWin || outcome == .playerBlackjack {
                    winArray.append(1)
                } else {
                    // lose or push = 0
                    winArray.append(0)
                }
                // Update totalBlackJacks if blackjack
                if outcome == .playerBlackjack {
                    totalBlackJacks += 1
                    UserDefaults.standard.set(totalBlackJacks, forKey: "totalBlackJacks")
                }
            }

            totalMoney += netWinLoss
            UserDefaults.standard.set(totalMoney, forKey: "totalMoney")

            // Save updated arrays
            UserDefaults.standard.set(winArray, forKey: "winArray")
            UserDefaults.standard.set(decisionArray, forKey: "decisionArray")
            UserDefaults.standard.set(betArray, forKey: "betArray")

            currentBet = 0

            // Remove pot chips visually
            for placed in betChipsStack {
                placed.chipNode.removeFromSuperview()
            }
            betChipsStack.removeAll()

            bettingOpen = true
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
        betAmountLabel.text = "Bet: \(currentBet)"
    }

    func updateBalanceLabel() {
        balanceLabel.text = "Balance: \(playerChips)"
    }

    // Check correctness of decision:
    // userAction: 0=Hit,1=Stand,2=Double Down,3=Split
    func checkDecisionCorrectness(userAction: Int) {
        guard let model = pipelineModel else { return }

        let playerHand = game.currentHand
        let playerTotal = Double(playerHand.total)

        let dealerUpValue: Double
        if game.dealerHand.cards.count >= 2 {
            let dCard = game.dealerHand.cards[1]
            dealerUpValue = dCard.rank == .ace ? 11.0 : Double(dCard.rank.value)
        } else {
            dealerUpValue = Double(game.visibleDealerTotal)
        }

        let isSoft = playerHand.isSoft ? 1.0 : 0.0
        let numDecks = Double(game.numberOfDecks)
        let dealerHitsSoft = Double(game.dealerHitsSoft17)
        let canSplit = game.playerCanSplit() ? 1.0 : 0.0
        let pairRankEncoded = 0.0

        let input = BlackJackPipelineInput(
            player_total: playerTotal,
            dealer_upcard: dealerUpValue,
            is_soft: isSoft,
            num_decks: numDecks,
            dealer_hits_soft_17: dealerHitsSoft,
            can_split: canSplit,
            pair_rank_encoded: pairRankEncoded
        )

        if let prediction = try? model.prediction(input: input) {
            let actionCode = prediction.action_code
            // If user's chosen action matches model's recommended action:
            let correct = (Int(actionCode) == userAction) ? 1 : 0
            decisionArray.append(correct)
            UserDefaults.standard.set(decisionArray, forKey: "decisionArray")
        }
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
