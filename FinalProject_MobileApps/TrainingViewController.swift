import UIKit
import SpriteKit
import CoreML

class TrainingViewController: UIViewController {

    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var doubleDownButton: UIButton!
    @IBOutlet weak var splitButton: UIButton!
    @IBOutlet weak var dealButton: UIButton!

    // Assume we have hitButton and standButton outlets:
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
        // Hide hit/stand until hand dealt
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
        // After initial deal
        hitButton.isHidden = false
        standButton.isHidden = false
        updateActionButtonsForGameState()
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
        // Actions (hit/stand) will appear after initial deal completes and ShowActions notification
    }

    @IBAction func hintButtonTapped(_ sender: Any) {
        guard let model = pipelineModel else {
            print("Pipeline model not loaded.")
            return
        }

        let playerTotal = Double(game.playerHands[0].total)
        let dealerCardValue = Double(game.dealerHand.cards[1].rank == .ace ? 11 : game.dealerHand.cards[1].rank.value)
        let isSoft = game.playerHands[0].isSoft ? 1.0 : 0.0
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
            Bust if you hit: \(String(format: "%.2f", bustProb * 100))%
            Improve hand if you hit: \(String(format: "%.2f", improveProb * 100))%
            Dealer's hidden card beats your stand: \(String(format: "%.2f", dealerBeatProb * 100))%
            """

            let alert = UIAlertController(title: "Hint: \(recommendedAction)", message: hintMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            print("Failed to get prediction from pipeline model.")
        }
    }

    @IBAction func hitButtonTapped(_ sender: Any) {
        game.playerHit()
        scene.playerHitUpdate()
        updateActionButtonsForGameState()
    }

    @IBAction func standButtonTapped(_ sender: Any) {
        game.playerStand()
        if game.roundFinished() {
            scene.dealerDoneUpdate()
        } else {
            scene.playerHitUpdate()
        }
        updateActionButtonsForGameState()
    }

    @IBAction func doubleDownTapped(_ sender: Any) {
        if game.currentHandCanDoubleDown() {
            game.playerDoubleDown()
            scene.playerHitUpdate()
            if game.roundFinished() {
                scene.dealerDoneUpdate()
            } else {
                scene.playerHitUpdate()
            }
        } else {
            print("Cannot double down now.")
        }
        updateActionButtonsForGameState()
    }

    @IBAction func splitTapped(_ sender: Any) {
        if game.playerCanSplit() {
            game.playerSplit()
            scene.playerHitUpdate()
        } else {
            print("Cannot split.")
        }
        updateActionButtonsForGameState()
    }
}
