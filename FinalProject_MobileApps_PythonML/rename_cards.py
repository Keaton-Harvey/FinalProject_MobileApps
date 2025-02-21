import os

# Path to the folder containing the PNG files
path = "/Users/keaton/Desktop/SMU/Fall 24/MASL/Final Project/FinalProject_MobileApps_PythonPart/FinalProject_MobileApps_PythonPart/Card pngs"

# Define the ranks and suits in the order you want:
ranks = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
suits = ["spades", "hearts", "clubs", "diamonds"]

# Get all .png files in the directory (excluding any hidden/system files)
files = [f for f in os.listdir(path) if f.lower().endswith('.png')]

# Sort the files so they are in a known, consistent order.
# If they're already named in numeric sequence (e.g. 1.png to 53.png) or alphabetically sorted,
# sorting them by filename might give the correct card order.
# Adjust if needed (e.g. if they follow a different pattern).
files.sort()

# Ensure we have exactly 53 files
if len(files) != 53:
    raise ValueError("There should be exactly 53 PNG files (52 fronts + 1 back). Found: {}".format(len(files)))

# Rename the first 52 cards
for i in range(52):
    # Determine the suit and rank index from the card number
    suit_index = i // 13
    rank_index = i % 13
    
    # Construct the new filename
    new_name = f"{ranks[rank_index]}_of_{suits[suit_index]}.png"
    
    old_path = os.path.join(path, files[i])
    new_path = os.path.join(path, new_name)
    
    # Rename the file
    os.rename(old_path, new_path)

# The last (53rd) is the card back
old_path = os.path.join(path, files[52])
new_path = os.path.join(path, "back_of_cards.png")
os.rename(old_path, new_path)

print("Renaming complete.")