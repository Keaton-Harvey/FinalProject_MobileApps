import pandas as pd

# Define pair ranks and their totals/is_soft
pair_info = [
    ('A', 12, 1),   # A,A treated as total 12, is_soft=1
    ('2', 4, 0),    # 2,2 = total 4
    ('3', 6, 0),    # 3,3 = total 6
    ('4', 8, 0),    # 4,4 = total 8
    ('5', 10, 0),   # 5,5 = total 10
    ('6', 12, 0),   # 6,6 = total 12
    ('7', 14, 0),   # 7,7 = total 14
    ('8', 16, 0),   # 8,8 = total 16
    ('9', 18, 0),   # 9,9 = total 18
    ('10', 20, 0)   # 10,10 (includes J/Q/K as 10) = total 20
]

def basic_strategy(player_total, dealer_upcard_value, is_soft, can_split, pair_rank):
    dealer_card = dealer_upcard_value

    # If can_split, use pair splitting logic first
    # Original logic snippet for splitting:
    # (Adapted from original code provided earlier)
    if can_split == 1:
        # pair_rank can be 'A', '2', '3', ..., '10'
        split_decisions = {
            'A': 'Split',
            '8': 'Split',
            '10': 'Stand',
            '9': 'Split' if dealer_card not in [7, 10, 11] else 'Stand',
            '7': 'Split' if dealer_card in range(2, 8) else 'Hit',
            '6': 'Split' if dealer_card in range(2, 7) else 'Hit',
            '5': 'Double Down' if dealer_card in range(2, 10) else 'Hit',
            '4': 'Split' if dealer_card in [5, 6] else 'Hit',
            '3': 'Split' if dealer_card in range(2, 8) else 'Hit',
            '2': 'Split' if dealer_card in range(2, 8) else 'Hit',
        }

        # If pair rank isn't in split decisions (unlikely, but just in case), default to 'Hit'
        if pair_rank in split_decisions:
            return split_decisions[pair_rank]
        else:
            # fallback to normal logic if something is off
            # (Should not happen if pair_rank is one of known pairs)
            pass

    # If not splitting or after considering split decisions:
    if is_soft == 1:
        if player_total >= 19:
            return 'Stand'
        elif player_total == 18:
            if dealer_card in range(2, 9):
                return 'Stand'
            else:
                return 'Hit'
        elif player_total == 17:
            if dealer_card in range(3, 7):
                return 'Double Down'
            else:
                return 'Hit'
        elif player_total in [15, 16]:
            if dealer_card in range(4, 7):
                return 'Double Down'
            else:
                return 'Hit'
        elif player_total in [13, 14]:
            if dealer_card in range(5, 7):
                return 'Double Down'
            else:
                return 'Hit'
        else:
            return 'Hit'
    else:
        # Hard totals
        if player_total >= 17:
            return 'Stand'
        elif player_total == 16 or player_total == 15:
            if dealer_card in range(2, 7):
                return 'Stand'
            else:
                return 'Hit'
        elif player_total == 14 or player_total == 13:
            if dealer_card in range(2, 7):
                return 'Stand'
            else:
                return 'Hit'
        elif player_total == 12:
            if dealer_card in range(4, 7):
                return 'Stand'
            else:
                return 'Hit'
        elif player_total == 11:
            return 'Double Down'
        elif player_total == 10:
            if dealer_card in range(2, 10):
                return 'Double Down'
            else:
                return 'Hit'
        elif player_total == 9:
            if dealer_card in range(3, 7):
                return 'Double Down'
            else:
                return 'Hit'
        else:
            return 'Hit'

if __name__ == "__main__":
    game_data = []

    # Enumerate all states for can_split=0 (no pair scenario)
    # player_total: 4 to 21
    # dealer_upcard: 2 to 11
    # is_soft: 0 or 1
    # num_decks: 1 to 6
    # dealer_hits_soft_17: 0 or 1
    # can_split: 0
    # pair_rank: None (or empty)

    # loop 20 times for more data
    for _ in range(20):
        for player_total in range(4, 22):
            for dealer_upcard in range(2, 12):
                for is_soft in [0, 1]:
                    for num_decks in range(1, 7):
                        for dealer_hits_soft_17 in [0, 1]:
                            can_split = 0
                            pair_rank = None
                            action = basic_strategy(player_total, dealer_upcard, is_soft, can_split, pair_rank)
                            game_data.append({
                                'player_total': player_total,
                                'dealer_upcard': dealer_upcard,
                                'is_soft': is_soft,
                                'num_decks': num_decks,
                                'dealer_hits_soft_17': dealer_hits_soft_17,
                                'can_split': can_split,
                                'pair_rank': '0' if pair_rank is None else pair_rank,
                                'best_action': action
                            })

        # Enumerate all states for can_split=1 (pair scenarios)
        # For each pair, we know player_total and is_soft from pair_info.
        # We vary dealer_upcard, num_decks, dealer_hits_soft_17 as before.
        # is_soft is determined by the pair (Aces have is_soft=1, others 0).
        # player_total is determined by the pair.
        # pair_rank is from pair_info.

        for (p_rank, p_total, p_soft) in pair_info:
            for dealer_upcard in range(2, 12):
                for num_decks in range(1, 7):
                    for dealer_hits_soft_17 in [0, 1]:
                        can_split = 1
                        # p_total and p_soft from the pair info
                        action = basic_strategy(p_total, dealer_upcard, p_soft, can_split, p_rank)
                        game_data.append({
                            'player_total': p_total,
                            'dealer_upcard': dealer_upcard,
                            'is_soft': p_soft,
                            'num_decks': num_decks,
                            'dealer_hits_soft_17': dealer_hits_soft_17,
                            'can_split': can_split,
                            'pair_rank': p_rank,
                            'best_action': action
                        })

    df = pd.DataFrame(game_data)
    df.to_csv('perfect_blackjack_sim_data.csv', index=False)