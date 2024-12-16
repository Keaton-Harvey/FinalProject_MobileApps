//
//  TrainingViewController.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/14/24.
//


import UIKit
import SpriteKit
import CoreML

class TrainingViewController: UIViewController {

    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var doubleDownButton: UIButton!
    @IBOutlet weak var splitButton: UIButton!
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var hitButton: UIButton!
    @IBOutlet weak var standButton: UIButton!

    var scene: GameScene!
    var game: BlackjackGame!
    var pipelineModel: BlackJackPipeline?

    override func viewDidLoad() {
        super.viewDidLoad()

        hintButton.isHidden = true
        doubleDownButton.isHidden = true
        splitButton.isHidden = true
        hitButton.isHidden = true
        standButton.isHidden = true

        let chosenNumberOfDecks = UserDefaults.standard.integer(forKey: "numOfDecks")
        let dealerHitsSoft17 = UserDefaults.standard.integer(forKey: "hitOrStand")

        let decks = (chosenNumberOfDecks > 0) ? chosenNumberOfDecks : 1
        let dh_s17 = dealerHitsSoft17

        game = BlackjackGame(numberOfDecks: decks, dealerHitsSoft17: dh_s17)

        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        scene.game = game
        skView.presentScene(scene)

        pipelineModel = try? BlackJackPipeline(configuration: MLModelConfiguration())

        NotificationCenter.default.addObserver(self, selector: #selector(showDealButton), name: NSNotification.Name("ShowDealButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showActions), name: NSNotification.Name("ShowActions"), object: nil)
    }

    @objc func showDealButton() {
        dealButton.isHidden = false
        hintButton.isHidden = true
        doubleDownButton.isHidden = true
        splitButton.isHidden = true
        hitButton.isHidden = true
        standButton.isHidden = true
    }

    @objc func showActions() {
        // Called after initial deal completed
        hitButton.isHidden = false
        standButton.isHidden = false
        updateActionButtonsForGameState()

        handleBetweenHandsTransitionIfNeeded()
    }

    func updateActionButtonsForGameState() {
        doubleDownButton.isHidden = !game.currentHandCanDoubleDown()
        splitButton.isHidden = !game.playerCanSplit()
    }

    @IBAction func dealButtonTapped(_ sender: Any) {
        dealButton.isHidden = true
        game.startNewRound()
        scene.startGame()
        hintButton.isHidden = false
        // After initial deal finishes, showActions will be called by scene notification
    }

    @IBAction func hintButtonTapped(_ sender: Any) {
        guard let model = pipelineModel else {
            print("Pipeline model not loaded.")
            return
        }

        let playerTotal = Double(game.currentHand.total)
        let dealerCardValue = Double(game.dealerHand.cards[1].rank == .ace ? 11 : game.dealerHand.cards[1].rank.value)
        let isSoft = game.currentHand.isSoft ? 1.0 : 0.0
        let numDecks = Double(game.numberOfDecks)
        let dealerHitsSoft = Double(game.dealerHitsSoft17)
        let canSplit = game.playerCanSplit() ? 1.0 : 0.0
        let pairRankEncoded = 0.0

        let input = BlackJackPipelineInput(
            player_total: playerTotal,
            dealer_upcard: dealerCardValue,
            is_soft: isSoft,
            num_decks: numDecks,
            dealer_hits_soft_17: dealerHitsSoft,
            can_split: canSplit,
            pair_rank_encoded: pairRankEncoded
        )

        if let prediction = try? model.prediction(input: input) {
            let actionCode = prediction.action_code
            let bustProb = prediction.BustProbabilityIfHit
            let improveProb = prediction.ImproveHandWithoutBustingIfHit
            let dealerBeatProb = prediction.IfStandOddsDealersSecondCardMakesThemBeatUs

            let actionMap = ["Hit","Stand","Double Down","Split"]
            let recommendedAction = actionMap[Int(actionCode)]

            let hintMessage = """
            Recommended Action: \(recommendedAction)
            Bust Probability if Hit: \(String(format: "%.2f", bustProb * 100))%
            Improve Probability if Hit: \(String(format: "%.2f", improveProb * 100))%
            Dealer Beats If Stand: \(String(format: "%.2f", dealerBeatProb * 100))%
            """

            let alert = UIAlertController(title: "Hint", message: hintMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            print("Failed to get prediction from pipeline model.")
        }
    }

    @IBAction func hitButtonTapped(_ sender: Any) {
        game.playerHit()
        // Show the updated hand (new card)
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            // After UI updated
            if self.game.currentHand.isBusted {
                self.scene.showBustedMessage()
                self.checkRoundStatus() // round ended
            } else {
                self.updateActionButtonsForGameState()
            }
        }
    }

    @IBAction func standButtonTapped(_ sender: Any) {
        game.playerStand()
        // Transition if needed
        handleBetweenHandsTransitionIfNeeded()
        // After transitions, check round status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkRoundStatus()
        }
    }

    @IBAction func doubleDownTapped(_ sender: Any) {
        game.playerDoubleDown()
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            if self.game.currentHand.isBusted {
                // Show bust after card displayed
                self.scene.showBustedMessage()
                self.checkRoundStatus()
            } else {
                self.handleBetweenHandsTransitionIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkRoundStatus()
                }
            }
        }
    }

    @IBAction func splitTapped(_ sender: Any) {
        if game.playerCanSplit() {
            game.playerSplit()
            // Reposition player hands to reflect the split before dealing the next card:
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
        } else {
            print("Cannot split.")
        }
    }

    func checkRoundStatus() {
        if game.roundFinished() {
            scene.dealerDoneUpdate()
        } else {
            updateActionButtonsForGameState()
        }
    }

    func handleBetweenHandsTransitionIfNeeded() {
        let handCount = game.playerHands.count
        if handCount > 1 {
            // If current hand needs its second card:
            let currentHand = game.currentHand
            if currentHand.cards.count == 1 {
                if let _ = game.dealCardToCurrentHand() {
                    scene.playerHitUpdate {
                        // After dealing second card to next hand
                        self.updateActionButtonsForGameState()
                    }
                }
            }
        }
    }
}
