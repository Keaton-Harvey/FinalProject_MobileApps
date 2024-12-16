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
        
        // Deal Button
        dealButton.setTitle("", for: .normal)  // Remove any title
        dealButton.setImage(UIImage(named: "deal_btn"), for: .normal)
        dealButton.backgroundColor = .clear
        dealButton.configuration = nil
        dealButton.contentHorizontalAlignment = .fill
        dealButton.contentVerticalAlignment = .fill
        dealButton.imageView?.contentMode = .scaleAspectFit
        
        // Hit Button
        hitButton.setTitle("", for: .normal)
        hitButton.setImage(UIImage(named: "hit_btn"), for: .normal)
        hitButton.backgroundColor = .clear
        hitButton.configuration = nil
        hitButton.contentHorizontalAlignment = .fill
        hitButton.contentVerticalAlignment = .fill
        hitButton.imageView?.contentMode = .scaleAspectFit
        
        // Stand Button
        standButton.setTitle("", for: .normal)
        standButton.setImage(UIImage(named: "stand_btn"), for: .normal)
        standButton.backgroundColor = .clear
        standButton.configuration = nil
        standButton.contentHorizontalAlignment = .fill
        standButton.contentVerticalAlignment = .fill
        standButton.imageView?.contentMode = .scaleAspectFit
        
        // Split Button
        splitButton.setTitle("", for: .normal)
        splitButton.setImage(UIImage(named: "split_btn"), for: .normal)
        splitButton.backgroundColor = .clear
        splitButton.configuration = nil
        splitButton.contentHorizontalAlignment = .fill
        splitButton.contentVerticalAlignment = .fill
        splitButton.imageView?.contentMode = .scaleAspectFit
        
        // Double Down Button
        doubleDownButton.setTitle("", for: .normal)
        doubleDownButton.setImage(UIImage(named: "double_down_btn"), for: .normal)
        doubleDownButton.backgroundColor = .clear
        doubleDownButton.configuration = nil
        doubleDownButton.contentHorizontalAlignment = .fill
        doubleDownButton.contentVerticalAlignment = .fill
        doubleDownButton.imageView?.contentMode = .scaleAspectFit
        

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
        // If dealer has 21, auto-stand (end round)
        if game.dealerTotal == 21 {
            game.playerStand()
            moveToNextHandOrFinish()
            return
        }

        // If player got a blackjack immediately, end round and pay out
        if game.playerHands[0].cards.count == 2 && game.isBlackjack(hand: game.playerHands[0]) {
            checkRoundStatus()
            return
        }

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
            var recommendedAction = actionMap[Int(actionCode)]
            
            if recommendedAction == "Double Down" && game.currentHand.cards.count > 2
            {
                recommendedAction = "Hit"
            }

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
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            if self.game.currentHand.isBusted {
                self.scene.showBustedMessage()
                // After bust, move to next hand if any, else end round
                self.moveToNextHandOrFinish()
            } else {
                self.updateActionButtonsForGameState()
            }
        }
    }

    @IBAction func standButtonTapped(_ sender: Any) {
        game.playerStand()
        // After standing, go to next hand or finish
        moveToNextHandOrFinish()
    }

    @IBAction func doubleDownTapped(_ sender: Any) {
        game.playerDoubleDown()
        scene.playerHitUpdate { [weak self] in
            guard let self = self else { return }
            if self.game.currentHand.isBusted {
                self.scene.showBustedMessage()
                // After bust, move to next hand if any, else end round
                self.moveToNextHandOrFinish()
            } else {
                // After double down, move to next hand or finish
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
        } else {
            print("Cannot split.")
        }
    }

    func moveToNextHandOrFinish() {
        if game.currentHandIndexPublic < game.playerHands.count - 1 {
            // Move to next hand
            game.moveToNextHandIfPossible()

            // If next hand only has 1 card, deal second card
            if game.currentHand.cards.count == 1 {
                if let _ = game.dealCardToCurrentHand() {
                    scene.playerHitUpdate {
                        self.updateActionButtonsForGameState()
                        self.checkRoundStatus()
                    }
                    return
                }
            }

            // If we are on the second hand (index 1) and it has 2 cards, force one hit:
            if game.currentHandIndexPublic == 1 && game.currentHand.cards.count == 2 {
                game.playerHit()
                scene.playerHitUpdate {
                    self.updateActionButtonsForGameState()
                    self.checkRoundStatus()
                }
                return
            }

            // If no special conditions, just check status now
            updateActionButtonsForGameState()
            checkRoundStatus()
        } else {
            // No more hands, check round status
            checkRoundStatus()
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
            let currentHand = game.currentHand
            if currentHand.cards.count == 1 {
                if let _ = game.dealCardToCurrentHand() {
                    scene.playerHitUpdate {
                        self.updateActionButtonsForGameState()
                    }
                }
            }
        }
    }
}
