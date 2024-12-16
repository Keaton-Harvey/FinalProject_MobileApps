//
//  AppEntryViewController.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey and Sam Skanse
//

/*
 This is the viewController where you enter the app and has a lot of different functions such as:
 - stats
 - game settings
 - total chips
 - practice mode and challenge mode navigation buttons
 - some other aesthetic features
 
 */

import UIKit

class AppEntryViewController: UIViewController {

    var popupView: UIView?
    var dimmedView: UIView?

    var amountOfDecks: Double = 1 {
        didSet {
            decks.text = "\(Int(amountOfDecks))"
            UserDefaults.standard.set(amountOfDecks, forKey: "numOfDecks")
            print("decks saved as \(amountOfDecks)")
        }
    }

    @IBOutlet weak var decks: UILabel!
    @IBOutlet weak var hitOrStandOutlet: UISwitch!
    @IBOutlet weak var totalChipsCounter: UILabel!
    @IBOutlet weak var decksStepper: UIStepper!
    @IBOutlet weak var gameconfigView: UIView!
    @IBOutlet weak var chipsView: UIView!
    @IBOutlet weak var chip: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        decksStepper.minimumValue = 1
        decksStepper.maximumValue = 6
        decksStepper.stepValue = 1

        decksStepper.value = amountOfDecks
        decks.text = "\(Int(amountOfDecks))"

        if let backgroundImage = UIImage(named: "BlackJackTable") {
            self.view.layer.contents = backgroundImage.cgImage
            self.view.layer.contentsGravity = .resizeAspectFill
        }

        chip.image = UIImage(named: "chipforintro")
        chip.contentMode = .scaleAspectFill

        addShadowAndBorder(to: gameconfigView)
        addShadowAndBorder(to: chipsView)

        hitOrStandOutlet.isOn = false
        UserDefaults.standard.set(0.0, forKey: "hitOrStand")

        let isChipsDefined = UserDefaults.standard.object(forKey: "chips") != nil
        if !isChipsDefined {
            UserDefaults.standard.set(500, forKey: "chips")
        }

        let savedChips = UserDefaults.standard.double(forKey: "chips")
        totalChipsCounter.text = "Total chips: $\(Int(savedChips))"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        totalChipsCounter.text = "Total chips: $\(Int(UserDefaults.standard.double(forKey: "chips")))"
    }

    @IBAction func hitOrStand(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(1.0, forKey: "hitOrStand")
            print("dealer hits on soft 17")
        } else {
            UserDefaults.standard.set(0.0, forKey: "hitOrStand")
            print("dealer stands on soft 17")
        }
    }

    @IBAction func changeDecks(_ sender: UIStepper) {
        amountOfDecks = sender.value
    }

    func addShadowAndBorder(to view: UIView,
                            shadowColor: UIColor = .black,
                            shadowOpacity: Float = 0.5,
                            shadowOffset: CGSize = CGSize(width: 3, height: 3),
                            shadowRadius: CGFloat = 4,
                            borderColor: UIColor = .systemYellow,
                            borderWidth: CGFloat = 2) {
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowRadius = shadowRadius
        view.layer.masksToBounds = false
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = borderWidth
    }

    @IBAction func statsButtonClicked(_ sender: Any) {
        let dimmedView = UIView(frame: self.view.bounds)
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.tag = 999
        self.view.addSubview(dimmedView)
        self.dimmedView = dimmedView

        let popupWidth: CGFloat = 300
        let popupHeight: CGFloat = 280
        let popupView = UIView(frame: CGRect(x: (self.view.frame.width - popupWidth) / 2,
                                             y: (self.view.frame.height - popupHeight) / 2,
                                             width: popupWidth,
                                             height: popupHeight))

        let popupBackgroundImageView = UIImageView(frame: CGRect(
            x: -195,
            y: -195,
            width: popupView.bounds.width + 400,
            height: popupView.bounds.height + 400
        ))
        popupBackgroundImageView.image = UIImage(named: "bluechip")
        popupBackgroundImageView.contentMode = .scaleAspectFill
        popupBackgroundImageView.clipsToBounds = false
        popupView.addSubview(popupBackgroundImageView)

        popupView.layer.cornerRadius = 10
        popupView.clipsToBounds = false
        self.view.addSubview(popupView)
        self.popupView = popupView

        let titleLabel = createTitleLabel(withText: "Statistics")
        titleLabel.frame = CGRect(x: 10, y: 10, width: popupWidth - 20, height: 30)
        titleLabel.textColor = .white
        popupView.addSubview(titleLabel)

        let winArray = (UserDefaults.standard.array(forKey: "winArray") as? [Int]) ?? []
        let decisionArray = (UserDefaults.standard.array(forKey: "decisionArray") as? [Int]) ?? []
        let betArray = (UserDefaults.standard.array(forKey: "betArray") as? [Int]) ?? []

        let winRateText: String
        if winArray.count > 0 {
            let winRate = (Double(winArray.reduce(0, +)) / Double(winArray.count)) * 100.0
            winRateText = String(format: "Win rate: %.2f%%", winRate)
        } else {
            winRateText = "Win rate: None"
        }

        let decisionText: String
        if decisionArray.count > 0 {
            let decisionPercent = (Double(decisionArray.reduce(0, +)) / Double(decisionArray.count)) * 100.0
            decisionText = String(format: "Correct decision percentage: %.2f%%", decisionPercent)
        } else {
            decisionText = "Correct decision percentage: None"
        }

        let averageBetText: String
        if betArray.count > 0 {
            let avgBet = Double(betArray.reduce(0, +)) / Double(betArray.count)
            averageBetText = String(format: "Average bet size: %.2f", avgBet)
        } else {
            averageBetText = "Average bet size: None"
        }

        let totalMoney = UserDefaults.standard.integer(forKey: "totalMoney")
        let totalMoneyText: String
        if totalMoney < 0 {
            totalMoneyText = "Total money lost: $\(abs(totalMoney))"
        } else {
            totalMoneyText = "Total money won: $\(totalMoney)"
        }

        let totalBlackJacks = UserDefaults.standard.integer(forKey: "totalBlackJacks")
        let blackjacksText = "Total BlackJacks: \(totalBlackJacks)"

        let reloads = UserDefaults.standard.integer(forKey: "reloads")
        let reloadsText = "Number of reloads: \(reloads)"

        let labelsText = [
            winRateText,
            blackjacksText,
            decisionText,
            averageBetText,
            totalMoneyText,
            reloadsText
        ]

        var yOffset: CGFloat = 50
        let labelHeight: CGFloat = 30
        for (i, text) in labelsText.enumerated() {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14)
            if i != 4 {
                label.textColor = .white
            } else {
                // For totalMoney we already decided color:
                if totalMoney < 0 {
                    label.textColor = .red
                } else {
                    label.textColor = .green
                }
            }
            label.text = text
            label.frame = CGRect(x: 10, y: yOffset, width: popupWidth - 20, height: labelHeight)
            popupView.addSubview(label)
            yOffset += labelHeight + 10
        }

        let closeButton = UIButton(frame: CGRect(x: popupWidth - 50, y: 10, width: 40, height: 40))
        closeButton.setImage(UIImage(named: "Closebutton"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        popupView.addSubview(closeButton)
    }

    @objc func dismissPopup() {
        popupView?.removeFromSuperview()
        dimmedView?.removeFromSuperview()
    }

    private func createTitleLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        return label
    }
}
