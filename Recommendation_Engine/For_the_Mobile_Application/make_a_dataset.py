import pandas as pd
import random
from itertools import combinations

# Generate 500 grocery items across categories
categories = {
    "dairy": ["milk", "cheese", "yogurt", "butter", "cream", "cottage cheese", "sour cream"],
    "bakery": ["bread", "bagels", "croissants", "muffins", "donuts", "cake", "cookies"],
    "produce": ["apples", "bananas", "oranges", "grapes", "lettuce", "tomatoes", "cucumbers"],
    "meat": ["chicken", "beef", "pork", "fish", "shrimp", "bacon", "sausage"],
    "pantry": ["rice", "pasta", "flour", "sugar", "oil", "vinegar", "canned beans"],
    "frozen": ["pizza", "ice cream", "frozen veggies", "frozen fries", "frozen berries"],
    "beverages": ["water", "soda", "juice", "coffee", "tea", "beer", "wine"],
    "snacks": ["chips", "popcorn", "nuts", "crackers", "granola bars", "chocolate"],
    # Add more categories to reach 500 items
}

# Generate all 500 items by expanding each category
grocery_items = []
for category, items in categories.items():
    for i in range(1, 8):
        for item in items:
            grocery_items.append(f"{item} {i}")

# Ensure we have exactly 500 items
grocery_items = grocery_items[:500]

# Define common shopping patterns
common_patterns = [
    ["milk 1", "cereal 1", "bananas 1"],
    ["bread 1", "butter 1", "jam 1"],
    ["pasta 1", "tomato sauce 1", "cheese 1"],
    ["chicken 1", "rice 1", "broccoli 1"],
    ["eggs 1", "bacon 1", "bread 2"],
    ["coffee 1", "cream 1", "sugar 1"],
    ["wine 1", "cheese 2", "crackers 1"],
    # Add more patterns
]

# Generate shopping baskets
def generate_baskets(num_baskets=5000):
    baskets = []
    for _ in range(num_baskets):
        # Start with a random common pattern
        basket = random.choice(common_patterns).copy()
        
        # Add 2-5 more items with category affinity
        for _ in range(random.randint(2, 5)):
            # Choose an existing item's category
            existing_item = random.choice(basket)
            category = existing_item.split()[0]  # Simple category mapping
            
            # Find similar items
            similar_items = [item for item in grocery_items if item.startswith(category)]
            if similar_items:
                new_item = random.choice(similar_items)
                if new_item not in basket:
                    basket.append(new_item)
            else:
                new_item = random.choice(grocery_items)
                if new_item not in basket:
                    basket.append(new_item)
        
        baskets.append(basket)
    return baskets

# Generate and save dataset
shopping_baskets = generate_baskets()
df = pd.DataFrame({"basket_id": range(len(shopping_baskets)), "items": shopping_baskets})
path = "C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/For_the_Mobile_Application/grocery_cooccurrence_dataset.csv"
df.to_csv(path, index=False)

print("Dataset saved as 'grocery_cooccurrence_dataset.csv'")