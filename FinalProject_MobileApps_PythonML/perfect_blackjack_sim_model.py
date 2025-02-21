import pandas as pd
import coremltools as ct
import matplotlib.pyplot as plt
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix, ConfusionMatrixDisplay
from sklearn.tree import DecisionTreeClassifier

# Load the perfect dataset
data = pd.read_csv("perfect_blackjack_sim_data.csv")

# Map actions to classes
action_map = {"Hit":0, "Stand":1, "Double Down":2, "Split":3}
data['action_label'] = data['best_action'].map(action_map)

# Encode pair_rank:
# We have '0', 'A', '2', '3', ..., '9', '10'
pair_rank_map = {
    '0': 0,
    'A': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9,
    '10': 10
}
data['pair_rank_encoded'] = data['pair_rank'].map(pair_rank_map)

# Prepare features and target
# Replace 'pair_rank' with 'pair_rank_encoded'
X = data[['player_total', 'dealer_upcard', 'is_soft', 'num_decks', 'dealer_hits_soft_17', 'can_split', 'pair_rank_encoded']]
y = data['action_label']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Random Forest Classifier
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)
rf_predictions = model.predict(X_test)
rf_accuracy = accuracy_score(y_test, rf_predictions)
print("Random Forest Accuracy:", rf_accuracy)

# Decision Tree Classifier
dt = DecisionTreeClassifier(criterion='entropy', max_depth=None, random_state=42)
dt.fit(X_train, y_train)
dt_predictions = dt.predict(X_test)
dt_accuracy = accuracy_score(y_test, dt_predictions)
print("Decision Tree Accuracy:", dt_accuracy)