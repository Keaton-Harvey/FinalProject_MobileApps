//
//  AppEntryViewController.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/14/24.
//

import UIKit


// TODO: this will be the initial page in the app. Here the user can view their stats, configure game settings, view their current chips, and click to play in challenge or training mode
/*
 On settings: hit or stand on soft 17 (dealer), how many decks
 
 Front:
 Win rate
 correct decision per
 average bet size
 total money lost over time
 
 
 
 */


class AppEntryViewController: UIViewController {
    
    var popupView: UIView?
    var dimmedView: UIView?

    
    var amountOfDecks: Double = 1 {
        didSet {
            // Update the label whenever the value changes
            decks.text = "\(Int(amountOfDecks))"
            
            // Persist the value in UserDefaults
            UserDefaults.standard.set(amountOfDecks, forKey: "numOfDecks")
            print("decks saved as \(amountOfDecks)")
        }
    }

    
  
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        decksStepper.minimumValue = 1
        decksStepper.maximumValue = 6
        decksStepper.stepValue = 1
        
        decksStepper.value = amountOfDecks
        decks.text = "\(Int(amountOfDecks))"
        
        
        hitOrStandOutlet.isOn = false
        UserDefaults.standard.set(0.0, forKey: "hitOrStand")
        
        let isChipsDefined = UserDefaults.standard.object(forKey: "chips") != nil
        
        if !isChipsDefined {
            // Set the default chips value to 2500
            UserDefaults.standard.set(2500, forKey: "chips")
        }
        
        // Retrieve the current chips value and display it
        let savedChips = UserDefaults.standard.double(forKey: "chips")
        totalChipsCounter.text = "Total chips: $\(Int(savedChips))"
        
    }
    @IBOutlet weak var decks: UILabel!
    
    @IBOutlet weak var hitOrStandOutlet: UISwitch!
    
    @IBAction func hitOrStand(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(1.0, forKey: "hitOrStand")
            print("dealer hits on soft 17")
        } else {
            UserDefaults.standard.set(0.0, forKey: "hitOrStand")
            print("dealer stands on soft 17")
        }
    }
    
    
    @IBOutlet weak var totalChipsCounter: UILabel!
    
    @IBOutlet weak var decksStepper: UIStepper!
    
    @IBAction func changeDecks(_ sender: UIStepper) {
        amountOfDecks = sender.value
    }
    
    
    @IBAction func statsButtonClicked(_ sender: Any) {
        // Create a dimmed background view
        let dimmedView = UIView(frame: self.view.bounds)
                dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                dimmedView.tag = 999 // Assign a tag to identify and remove it later
                self.view.addSubview(dimmedView)
                self.dimmedView = dimmedView

                // Create the popup view
                let popupWidth: CGFloat = 300
                let popupHeight: CGFloat = 280
                let popupView = UIView(frame: CGRect(x: (self.view.frame.width - popupWidth) / 2,
                                                     y: (self.view.frame.height - popupHeight) / 2,
                                                     width: popupWidth,
                                                     height: popupHeight))
                popupView.backgroundColor = .white
                popupView.layer.cornerRadius = 10
                popupView.clipsToBounds = true
                self.view.addSubview(popupView)
                self.popupView = popupView

                // Add the title label
                let titleLabel = createTitleLabel(withText: "User Lifetime Stats")
                titleLabel.frame = CGRect(x: 10, y: 10, width: popupWidth - 20, height: 30)
                popupView.addSubview(titleLabel)

                // Add the stat labels with proper spacing
                let labels = [
                    createLabel(withText: "Win rate: 65%"),
                    createLabel(withText: "Correct decision percentage: 80%"),
                    createLabel(withText: "Average bet size: $50"),
                    createLabel(withText: "Total money lost: $150", textColor: .red)
                ]

                // Layout the labels inside the popup
                var yOffset: CGFloat = 50 // Start below the title label
                let labelHeight: CGFloat = 30
                for label in labels {
                    label.frame = CGRect(x: 10, y: yOffset, width: popupWidth - 20, height: labelHeight)
                    popupView.addSubview(label)
                    yOffset += labelHeight + 10 // Add spacing between labels
                }

                // Add a close button to the popup
                let closeButton = UIButton(frame: CGRect(x: popupWidth - 40, y: 10, width: 30, height: 30))
                closeButton.setTitle("X", for: .normal)
                closeButton.setTitleColor(.black, for: .normal)
                closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
                popupView.addSubview(closeButton)
            }

            @objc func dismissPopup() {
                // Remove the popup and dimmed background
                popupView?.removeFromSuperview()
                dimmedView?.removeFromSuperview()
            }

            private func createLabel(withText text: String, textColor: UIColor = .black) -> UILabel {
                let label = UILabel()
                label.text = text
                label.textColor = textColor
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 14)
                return label
            }

            private func createTitleLabel(withText text: String) -> UILabel {
                let label = UILabel()
                label.text = text
                label.textColor = .black
                label.textAlignment = .center
                label.font = UIFont.boldSystemFont(ofSize: 18) // Larger, bold font
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
