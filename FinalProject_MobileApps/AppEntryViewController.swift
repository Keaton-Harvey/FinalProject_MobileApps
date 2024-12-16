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
        
        if let backgroundImage = UIImage(named: "BlackJackTable") {
                self.view.layer.contents = backgroundImage.cgImage
                self.view.layer.contentsGravity = .resizeAspectFill // Adjust scaling (similar to contentMode)
            }
        
        chip.image = UIImage(named: "chipforintro") // Replace with your asset name
            chip.contentMode = .scaleAspectFill // Adjust content mode
        

        addShadowAndBorder(to: gameconfigView)
        addShadowAndBorder(to: chipsView)
        
        
        hitOrStandOutlet.isOn = false
        UserDefaults.standard.set(0.0, forKey: "hitOrStand")
        
        let isChipsDefined = UserDefaults.standard.object(forKey: "chips") != nil
        
        if !isChipsDefined {
            // Set the default chips value to 2500
            UserDefaults.standard.set(500, forKey: "chips")
        }
        
        // Retrieve the current chips value and display it
        let savedChips = UserDefaults.standard.double(forKey: "chips")
        totalChipsCounter.text = "Total chips: $\(Int(savedChips))"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        totalChipsCounter.text = "Total chips: $\(Int(UserDefaults.standard.double(forKey: "chips")))"
        
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
    
    @IBOutlet weak var gameconfigView: UIView!
    
    @IBOutlet weak var chipsView: UIView!
    
    @IBOutlet weak var chip: UIImageView!
    
    func addShadowAndBorder(to view: UIView,
                            shadowColor: UIColor = .black,
                            shadowOpacity: Float = 0.5,
                            shadowOffset: CGSize = CGSize(width: 3, height: 3),
                            shadowRadius: CGFloat = 4,
                            borderColor: UIColor = .systemYellow,
                            borderWidth: CGFloat = 2) {
        // Add shadow
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowRadius = shadowRadius
        view.layer.masksToBounds = false // Ensure shadow is visible outside the view

        // Add border
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = borderWidth
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
            
            // Add an UIImageView for the background
            let popupBackgroundImageView = UIImageView(frame: CGRect(
                x: -195, // Shift the image slightly to the left to center it
                y: -195, // Shift the image slightly upward to center it
                width: popupView.bounds.width + 400, // Increase width
                height: popupView.bounds.height + 400 // Increase height
                ))
            popupBackgroundImageView.image = UIImage(named: "bluechip") // Replace with your image asset name
            popupBackgroundImageView.contentMode = .scaleAspectFill // Adjust the scaling to fit the view
            popupBackgroundImageView.clipsToBounds = false
            popupView.addSubview(popupBackgroundImageView) // Add the image view first
            
            // Set up the popup view properties
            popupView.layer.cornerRadius = 10
            popupView.clipsToBounds = false
            self.view.addSubview(popupView)
            self.popupView = popupView

            // Add the title label
        let titleLabel = createTitleLabel(withText: "Statistics")
            titleLabel.frame = CGRect(x: 10, y: 10, width: popupWidth - 20, height: 30)
            titleLabel.textColor = .white
            popupView.addSubview(titleLabel)

            // Add the stat labels with proper spacing
        let labels = [
            createLabel(forKey: "winRate", defaultValue: "Win rate: None"),
            createLabel(forKey: "totalBlackJacks", defaultValue: "Total BlackJacks: None"),
            createLabel(forKey: "decisionPercentage", defaultValue: "Correct decision percentage: None"),
            createLabel(forKey: "averageBetSize", defaultValue: "Average bet size: None"),
            createLabel(forKey: "totalMoney", defaultValue: "Total money lost/won: None"),
            createLabel(forKey: "reloads", defaultValue: "Number of reloads: None")
        ]

            // Layout the labels inside the popup
            var yOffset: CGFloat = 50 // Start below the title label
            let labelHeight: CGFloat = 30
            var i = 0
            for label in labels {
    
                label.frame = CGRect(x: 10, y: yOffset, width: popupWidth - 20, height: labelHeight)
                if i != 4 {
                    label.textColor = .white
                }
                i += 1
                popupView.addSubview(label)
                yOffset += labelHeight + 10 // Add spacing between labels
            }

            // Add a close button to the popup
            let closeButton = UIButton(frame: CGRect(x: popupWidth - 50, y: 10, width: 40, height: 40))
            closeButton.setImage(UIImage(named: "Closebutton"), for: .normal) // Replace "closeIcon" with your asset name
            closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
            popupView.addSubview(closeButton)

        }

        @objc func dismissPopup() {
            // Remove the popup and dimmed background
            popupView?.removeFromSuperview()
            dimmedView?.removeFromSuperview()
        }
    
    private func createLabel(forKey key: String, defaultValue: String, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = textColor
        
        // Retrieve the value from UserDefaults
        let value = UserDefaults.standard.string(forKey: key) ?? defaultValue
        
        // Check if this is the "totalMoney" key to dynamically adjust the text color
        if key == "totalMoney" {
                // Extract the numerical value for money
                if let moneyString = UserDefaults.standard.string(forKey: key),
                   let money = Double(moneyString.replacingOccurrences(of: "$", with: "")) {
                    if money < 0 {
                        label.text = "Total money lost: $\(abs(money))"
                        label.textColor = .red // Red for negative values
                    } else {
                        label.text = "Total money won: $\(money)"
                        label.textColor = .green // Green for positive values
                    }
                    return label
                }
            }
        
        // Assign the value to the label text
        if value == defaultValue{
            label.text = defaultValue
        } else {
            label.text = String(defaultValue.dropLast(4)) + value
        }
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
