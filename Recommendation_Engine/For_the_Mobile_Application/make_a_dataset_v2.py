import pandas as pd
import random
import numpy as np

def generate_grocery_dataset(output_file="grocery_cooccurrence_dataset_v2.csv"):
    # Expanded grocery items with realistic variations
    categories = {
        "dairy": {
            "milk": ["whole", "skim", "2%", "almond", "soy", "lactose-free"],
            "cheese": ["cheddar", "mozzarella", "swiss", "parmesan", "provolone"],
            "yogurt": ["plain", "strawberry", "blueberry", "greek", "low-fat"]
        },
        "bakery": {
            "bread": ["white", "whole wheat", "sourdough", "rye", "multigrain"],
            "bagels": ["plain", "sesame", "everything", "cinnamon"],
            "pastries": ["croissants", "muffins", "donuts", "danishes"]
        },
        "produce": {
            "fruits": ["apples", "bananas", "oranges", "grapes", "pears"],
            "vegetables": ["lettuce", "tomatoes", "cucumbers", "carrots", "broccoli"]
        },
        "meat": {
            "poultry": ["chicken", "turkey", "duck"],
            "beef": ["ground beef", "steak", "roast"],
            "seafood": ["fish", "shrimp", "crab"]
        },
        "pantry": {
            "grains": ["rice", "pasta", "quinoa", "couscous"],
            "canned goods": ["beans", "tomato sauce", "soup"],
            "spices": ["salt", "pepper", "oregano", "cumin"]
        },
        "frozen": {
            "meals": ["pizza", "ice cream", "frozen veggies"],
            "snacks": ["frozen fries", "frozen berries"]
        },
        "beverages": {
            "soft drinks": ["soda", "juice", "sparkling water"],
            "alcohol": ["beer", "wine", "spirits"]
        },
        "snacks": {
            "chips": ["potato chips", "tortilla chips", "pita chips"],
            "sweets": ["chocolate", "candy", "cookies"]
        },
        # Add more categories and items as needed to reach 500 items
        "breakfast": {
            "cereal": ["corn flakes", "oatmeal", "granola"],
            "pancakes": ["buttermilk", "blueberry", "chocolate chip"]
        },
        "condiments": {
            "sauces": ["ketchup", "mustard", "mayonnaise"],
            "dressings": ["ranch", "vinaigrette", "caesar"]
        },
        "baby": {
            "formula": ["infant formula", "toddler formula"],
            "snacks": ["baby food", "puffs"]
        },
        "pet": {
            "dog food": ["dry", "wet"],
            "cat food": ["dry", "wet"]
        },
        "health": {
            "vitamins": ["multivitamin", "vitamin C", "omega-3"],
            "supplements": ["protein powder", "fiber"]
        },
        "household": {
            "cleaning supplies": ["detergent", "bleach", "disinfectant"],
            "paper goods": ["toilet paper", "paper towels"]
        },
        "personal care": {
            "toiletries": ["shampoo", "soap", "toothpaste"],
            "cosmetics": ["foundation", "lipstick"]
        },
        "electronics": {
            "batteries": ["AA", "AAA", "9V"],
            "accessories": ["phone charger", "earbuds"]
        },
        "clothing": {
            "apparel": ["t-shirts", "jeans", "socks"],
            "accessories": ["belts", "hats"]
        },
        "toys": {
            "games": ["board games", "puzzles"],
            "outdoor": ["bicycles", "kites"]
        },
        "furniture": {
            "living room": ["sofa", "coffee table"],
            "bedroom": ["bed", "dresser"]
        },
        "garden": {
            "tools": ["shovel", "rake"],
            "plants": ["flowers", "herbs"]
        },
        "sports": {
            "equipment": ["basketball", "soccer ball"],
            "clothing": ["sneakers", "sportswear"]
        },
        "stationery": {
            "writing": ["pens", "notebooks"],
            "art supplies": ["paints", "brushes"]
        },
        "automotive": {
            "accessories": ["car charger", "seat covers"],
            "maintenance": ["oil", "cleaner"]
        },
        "books": {
            "fiction": ["novels", "short stories"],
            "non-fiction": ["biographies", "self-help"]
        },
        "music": {
            "instruments": ["guitar", "piano"],
            "accessories": ["strings", "sheet music"]
        },
        "movies": {
            "genres": ["action", "comedy", "drama"],
            "formats": ["DVD", "Blu-ray"]
        },
        "games": {
            "video games": ["PS5", "Xbox", "Switch"],
            "board games": ["chess", "monopoly"]
        },
        "healthcare": {
            "medications": ["pain reliever", "cold medicine"],
            "first aid": ["band-aids", "antiseptic"]
        },
        "travel": {
            "luggage": ["suitcase", "backpack"],
            "accessories": ["travel pillow", "adapter"]
        },
        "office": {
            "furniture": ["desk", "chair"],
            "supplies": ["printer", "ink"]
        },
        "fitness": {
            "equipment": ["dumbbells", "yoga mat"],
            "clothing": ["workout gear", "running shoes"]
        },
        "outdoor": {
            "gear": ["tent", "sleeping bag"],
            "clothing": ["hiking boots", "rain jacket"]
        },
        "seasonal": {
            "holiday": ["decorations", "gifts"],
            "summer": ["sunscreen", "pool toys"]
        },
        "party": {
            "supplies": ["balloons", "streamers"],
            "food": ["chips", "dip"]
        },
        "gifts": {
            "for him": ["wallet", "watch"],
            "for her": ["jewelry", "perfume"]
        },
        "crafts": {
            "supplies": ["glue", "scissors"],
            "kits": ["knitting", "painting"]
        },
        "hobbies": {
            "collectibles": ["stamps", "coins"],
            "DIY": ["woodworking", "electronics"]
        },
        "home improvement": {
            "tools": ["hammer", "screwdriver"],
            "materials": ["wood", "paint"]
        },
        "baking": {
            "ingredients": ["flour", "sugar", "yeast"],
            "tools": ["mixer", "baking pans"]
        },
        "cooking": {
            "utensils": ["spatula", "whisk"],
            "appliances": ["blender", "slow cooker"]
        },
        "cleaning": {
            "supplies": ["vacuum", "mop"],
            "tools": ["broom", "dustpan"]
        },
        "gardening": {
            "tools": ["trowel", "pruners"],
            "supplies": ["soil", "fertilizer"]
        },
        "pet care": {
            "food": ["dog food", "cat food"],
            "supplies": ["litter", "toys"]
        },
        "baby care": {
            "diapers": ["disposable", "cloth"],
            "wipes": ["baby wipes", "wet wipes"]
        },
        "school": {
            "supplies": ["backpack", "lunch box"],
            "clothing": ["uniform", "shoes"]
        },
        "office supplies": {
            "paper": ["printer paper", "notebooks"],
            "writing tools": ["pens", "pencils"]
        },
        "electronics accessories": {
            "cables": ["HDMI", "USB"],
            "cases": ["phone case", "laptop sleeve"]
        },
        "home decor": {
            "furniture": ["couch", "table"],
            "accessories": ["vase", "picture frame"]
        },
        "kitchenware": {
            "cookware": ["pots", "pans"],
            "utensils": ["knives", "spoons"]
        },
    }

    # Generate 500 unique grocery items
    grocery_items = []
    for category, subcategories in categories.items():
        for product, varieties in subcategories.items():
            for variety in varieties:
                grocery_items.append(f"{product} {variety}")
    
    # Ensure we have exactly 500 items
    grocery_items = grocery_items[:500]

    # Define common shopping patterns with probabilities
    common_patterns = [
        (["milk whole", "cereal"], 0.8),
        (["bread white", "butter"], 0.7),
        (["pasta", "tomato sauce"], 0.6),
        (["chicken", "rice"], 0.5),
        (["eggs", "bacon"], 0.4),
        (["coffee", "cream"], 0.3),
        (["wine", "cheese cheddar"], 0.6),
        (["chips", "salsa"], 0.5),
        (["cookies", "milk whole"], 0.7),
        (["snacks chips", "soda"], 0.4),
        (["yogurt", "granola"], 0.5),
        (["frozen pizza", "ice cream"], 0.6),
        (["dog food dry", "dog treats"], 0.5),
        (["baby wipes", "diapers disposable"], 0.7),
        (["cleaning supplies detergent", "paper towels"], 0.4),
        (["baking flour", "sugar"], 0.5),
        (["vegetables lettuce", "dressing vinaigrette"], 0.4),
        (["fruits apples", "yogurt"], 0.5),
        (["snacks nuts", "chocolate"], 0.6),
        (["canned beans", "rice"], 0.5),
        (["breakfast cereal", "milk almond"], 0.7),
        (["pet food cat food", "litter"], 0.6),
        (["electronics batteries", "charger"], 0.4),
        (["toiletries shampoo", "soap"], 0.5),
        (["toys board games", "puzzles"], 0.4),
        (["home decor vase", "picture frame"], 0.5),
        (["sports equipment basketball", "sneakers"], 0.6),
        (["travel luggage suitcase", "adapter"], 0.5),
        (["furniture sofa", "coffee table"], 0.4),
        (["garden tools shovel", "plants flowers"], 0.5),
        (["fitness equipment dumbbells", "yoga mat"], 0.6),
        (["seasonal holiday decorations", "gifts"], 0.5),
        (["party supplies balloons", "food chips"], 0.4),
        (["crafts supplies glue", "kits painting"], 0.5),   
        (["hobbies collectibles stamps", "DIY woodworking"], 0.4),
        (["home improvement tools hammer", "materials wood"], 0.5),
        (["baking ingredients flour", "tools mixer"], 0.6),
        (["cooking utensils spatula", "appliances blender"], 0.5),
        (["cleaning supplies vacuum", "tools broom"], 0.4),
        (["gardening tools trowel", "supplies soil"], 0.5),
        (["baby care diapers disposable", "wipes baby wipes"], 0.6),
        (["school supplies backpack", "clothing uniform"], 0.5),
        (["office supplies paper printer paper", "writing tools pens"], 0.4),
        (["electronics accessories cables HDMI", "cases phone case"], 0.5),
        (["home decor furniture couch", "accessories vase"], 0.4),
        (["kitchenware cookware pots", "utensils knives"], 0.5),
        (["snacks popcorn", "nuts"], 0.6),
        (["beverages soda", "juice"], 0.5),
        (["snacks granola bars", "chocolate"], 0.4),
        (["snacks chips", "popcorn"], 0.5),
        (["snacks crackers", "granola bars"], 0.4),
        (["snacks chocolate", "cookies"], 0.5),
        (["snacks nuts", "chips"], 0.4),
        # ... more patterns ...
        
    ]

    # Generate realistic shopping baskets
    def generate_basket():
        basket = []
        # Add a common pattern
        for pattern, prob in common_patterns:
            if random.random() < prob:
                basket.extend(pattern.copy())
        
        # Add complementary items
        for item in basket.copy():
            if "milk" in item and random.random() < 0.6:
                basket.append("cookies")
            if "bread" in item and random.random() < 0.5:
                basket.append("jam strawberry")
            if "pasta" in item and random.random() < 0.5:
                basket.append("cheese mozzarella")
            if "chicken" in item and random.random() < 0.5:
                basket.append("broccoli")
            if "eggs" in item and random.random() < 0.4:
                basket.append("bread whole wheat")
            if "coffee" in item and random.random() < 0.3:
                basket.append("sugar")
            if "wine" in item and random.random() < 0.6:
                basket.append("cheese cheddar") 
            if "chips" in item and random.random() < 0.5:
                basket.append("salsa")
            if "cookies" in item and random.random() < 0.7:
                basket.append("milk whole")
            if "snacks chips" in item and random.random() < 0.4:
                basket.append("soda")
            if "yogurt" in item and random.random() < 0.5:
                basket.append("granola")
            if "frozen pizza" in item and random.random() < 0.6:
                basket.append("ice cream")
            if "dog food dry" in item and random.random() < 0.5:
                basket.append("dog treats")
            if "baby wipes" in item and random.random() < 0.7:
                basket.append("diapers disposable")
            if "cleaning supplies detergent" in item and random.random() < 0.4:
                basket.append("paper towels")
            if "baking flour" in item and random.random() < 0.5:
                basket.append("sugar")
            if "vegetables lettuce" in item and random.random() < 0.4:
                basket.append("dressing vinaigrette")
            if "fruits apples" in item and random.random() < 0.5:
                basket.append("yogurt")
            if "snacks nuts" in item and random.random() < 0.6:
                basket.append("chocolate")
            if "canned beans" in item and random.random() < 0.5:
                basket.append("rice")
            if "breakfast cereal" in item and random.random() < 0.7:
                basket.append("milk almond")
            if "pet food cat food" in item and random.random() < 0.6:
                basket.append("litter")
            if "electronics batteries" in item and random.random() < 0.4:
                basket.append("charger")
            if "toiletries shampoo" in item and random.random() < 0.5:
                basket.append("soap")
            if "toys board games" in item and random.random() < 0.4:
                basket.append("puzzles")
            if "home decor vase" in item and random.random() < 0.5:
                basket.append("picture frame")
            if "sports equipment basketball" in item and random.random() < 0.6:
                basket.append("sneakers")
            if "travel luggage suitcase" in item and random.random() < 0.5:
                basket.append("adapter")
            if "furniture sofa" in item and random.random() < 0.4:
                basket.append("coffee table")
            if "garden tools shovel" in item and random.random() < 0.5:
                basket.append("plants flowers")
            if "fitness equipment dumbbells" in item and random.random() < 0.6:
                basket.append("yoga mat")
            if "seasonal holiday decorations" in item and random.random() < 0.5:
                basket.append("gifts")
            if "party supplies balloons" in item and random.random() < 0.4:
                basket.append("food chips")
            if "crafts supplies glue" in item and random.random() < 0.5:
                basket.append("kits painting")
            if "hobbies collectibles stamps" in item and random.random() < 0.4:
                basket.append("DIY woodworking")
            if "home improvement tools hammer" in item and random.random() < 0.5:
                basket.append("materials wood")
            if "baking ingredients flour" in item and random.random() < 0.6:
                basket.append("tools mixer")
            if "cooking utensils spatula" in item and random.random() < 0.5:
                basket.append("appliances blender")
            if "cleaning supplies vacuum" in item and random.random() < 0.4:
                basket.append("tools broom")
            if "gardening tools trowel" in item and random.random() < 0.5:
                basket.append("supplies soil")
            if "baby care diapers disposable" in item and random.random() < 0.6:
                basket.append("wipes baby wipes")
            if "school supplies backpack" in item and random.random() < 0.5:
                basket.append("clothing uniform")
            if "office supplies paper printer paper" in item and random.random() < 0.4: 
                basket.append("writing tools pens")
            if "electronics accessories cables HDMI" in item and random.random() < 0.5:
                basket.append("cases phone case")
            if "home decor furniture couch" in item and random.random() < 0.4:
                basket.append("accessories vase")
            # ... more complementary rules ...
        
        # Add some random items
        num_random = random.randint(1, 3)
        basket.extend(random.sample(grocery_items, num_random))
        
        return list(set(basket))  # Remove duplicates

    # Generate dataset
    baskets = [generate_basket() for _ in range(10000)]
    
    # Save to CSV
    df = pd.DataFrame({"basket_id": range(len(baskets)), "items": baskets})
    df.to_csv(output_file, index=False)
    print(f"Dataset generated successfully at {output_file}")

if __name__ == "__main__":
    generate_grocery_dataset()