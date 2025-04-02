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
    "cleaning": ["detergent", "soap", "toilet paper", "paper towels", "trash bags"],
    "personal_care": ["shampoo", "toothpaste", "deodorant", "lotion", "razors"],
    "baby": ["diapers", "baby wipes", "baby food", "formula", "baby lotion"],
    "pet": ["dog food", "cat food", "pet treats", "litter", "pet toys"],
    "health": ["vitamins", "pain relievers", "band-aids", "first aid kit", "cold medicine"],
    "international": ["salsa", "soy sauce", "curry paste", "tortillas", "rice noodles"],
    "seasonings": ["salt", "pepper", "spices", "herbs", "sauces"],
    "condiments": ["ketchup", "mustard", "mayonnaise", "hot sauce", "salad dressing"],
    "breakfast": ["cereal", "oatmeal", "pancake mix", "syrup", "granola"],
    "desserts": ["cake mix", "brownie mix", "pudding", "cookies", "ice cream toppings"],
    "canned_goods": ["soup", "vegetables", "fruit", "tuna", "chili"],
    "baking": ["baking soda", "baking powder", "yeast", "chocolate chips", "vanilla extract"],
    "spices": ["cinnamon", "nutmeg", "paprika", "cumin", "oregano"],
    "oils": ["olive oil", "canola oil", "vegetable oil", "sesame oil", "coconut oil"],
    "grains": ["quinoa", "barley", "bulgur", "couscous", "farro"],
    "nuts": ["almonds", "walnuts", "pecans", "cashews", "pistachios"],
    "dried_fruits": ["raisins", "cranberries", "apricots", "dates", "figs"],
    "sauces": ["barbecue sauce", "teriyaki sauce", "hot sauce", "soy sauce", "pasta sauce"],
    "jams": ["strawberry jam", "blueberry jam", "peach jam", "apricot jam", "grape jelly"],
    "syrups": ["maple syrup", "agave syrup", "corn syrup", "chocolate syrup", "honey"],
    "spreads": ["peanut butter", "almond butter", "hazelnut spread", "cream cheese", "hummus"],
    "frozen_meals": ["frozen dinners", "microwave meals", "frozen burritos", "frozen lasagna", "frozen stir fry"],
    "instant_foods": ["instant noodles", "instant rice", "instant oatmeal", "instant soup", "instant mashed potatoes"],
    "packaged_foods": ["snack packs", "meal kits", "microwave popcorn", "instant pudding", "instant rice"],
    "ready_to_eat": ["pre-cooked chicken", "pre-cooked rice", "pre-cooked pasta", "pre-cooked veggies", "pre-cooked meals"],
    "cooking_kits": ["soup kits", "stir fry kits", "taco kits", "pizza kits", "salad kits"],
    "meal_prep": ["meal prep containers", "meal prep bags", "meal prep kits", "meal prep tools", "meal prep recipes"],
    "snack_kits": ["snack packs", "snack boxes", "snack bags", "snack trays", "snack baskets"],
    "party_supplies": ["party plates", "party cups", "party napkins", "party decorations", "party favors"],
    "holiday_supplies": ["holiday decorations", "holiday lights", "holiday gifts", "holiday cards", "holiday wrapping paper"],
    "seasonal_items": ["seasonal decorations", "seasonal gifts", "seasonal foods", "seasonal clothing", "seasonal supplies"],
    "gift_items": ["gift cards", "gift wrap", "gift bags", "gift baskets", "gift tags"],
    "home_goods": ["candles", "picture frames", "home decor", "kitchen gadgets", "storage containers"],
    "office_supplies": ["notebooks", "pens", "pencils", "paper clips", "staplers"],
    "electronics": ["batteries", "chargers", "cables", "headphones", "phone cases"],
    "toys": ["action figures", "dolls", "puzzles", "board games", "stuffed animals"],
    "games": ["video games", "board games", "card games", "puzzles", "outdoor games"],
    "sports": ["soccer ball", "basketball", "tennis racket", "baseball glove", "golf clubs"],
    "outdoor": ["camping gear", "hiking gear", "fishing gear", "bicycles", "skateboards"],
    "clothing": ["t-shirts", "jeans", "jackets", "sweaters", "shoes"],
    "accessories": ["hats", "belts", "scarves", "gloves", "sunglasses"],
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
name_and_path_to_save = "C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/For_the_Mobile_Application/grocery_cooccurrence_dataset.csv"
df.to_csv(name_and_path_to_save, index=False)

print("Dataset saved as 'grocery_cooccurrence_dataset.csv'")