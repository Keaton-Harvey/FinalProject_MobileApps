//
//  BetManager.swift
//  FinalProject_MobileApps
//
//  Created by Keaton Harvey on 12/15/24.
//

class BetManager {
    var playerChips: Int
    var currentBet: Int
    
    init(startingChips: Int, initialBet: Int) {
        self.playerChips = startingChips
        self.currentBet = initialBet
    }

    func applyOutcome(_ outcome: GameOutcome) {
        switch outcome {
        case .playerBlackjack:
            // pay 3:2
            playerChips += Int(Double(currentBet) * 1.5)
        case .playerWin:
            // pay 1:1
            playerChips += currentBet
        case .playerLose:
            // lose bet, nothing added
            break
        case .push:
            // get bet back
            break
        }
    }
}
