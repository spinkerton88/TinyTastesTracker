import os
import shutil

ASSETS_DIR = "TinyTastesTracker/Assets.xcassets"

# List of foods to revert (The ones from the failed batch)
foods_to_delete = [
    # PROTEINS
    "food_chicken", "food_turkey", "food_beef", "food_pork", "food_lamb",
    "food_salmon", "food_tuna", "food_cod", "food_tilapia", "food_shrimp",
    "food_egg", "food_tofu", "food_black_beans", "food_lentils", "food_chickpeas",
    "food_kidney_beans", "food_pinto_beans", "food_peanut_butter", "food_almond_butter", "food_hummus",
    # GRAINS
    "food_oatmeal", "food_rice", "food_quinoa", "food_barley", "food_couscous",
    "food_pasta", "food_bread", "food_crackers", "food_tortilla", "food_cheerios",
    "food_millet", "food_buckwheat", "food_polenta", "food_farro", "food_bulgur",
    # DAIRY
    "food_yogurt", "food_cheese", "food_cottage_cheese", "food_cream_cheese",
    "food_ricotta", "food_mozzarella", "food_cheddar", "food_swiss_cheese",
    "food_parmesan", "food_butter", "food_milk",
    # SNACKS
    "food_pretzel", "food_popcorn",
    # BEVERAGES
    "food_water", "food_smoothie",
    # VEGGIES (Batch 2)
    "food_peas", "food_green_beans", "food_zucchini", "food_tomato", "food_spinach", 
    "food_kale", "food_artichoke", "food_mushroom", "food_snap_peas", "food_edamame",
    "food_eggplant", "food_parsnip", "food_turnip"
]

print(f"Reverting {len(foods_to_delete)} assets...")

for food_id in foods_to_delete:
    asset_path = os.path.join(ASSETS_DIR, f"{food_id}.imageset")
    if os.path.exists(asset_path):
        print(f"Deleting {asset_path}...")
        shutil.rmtree(asset_path)
    else:
        print(f"Skipping {asset_path} (not found)")

print("Done. Emojis restored.")
