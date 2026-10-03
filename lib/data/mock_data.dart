import 'dart:math';
import '../models/recipe.dart';
import '../models/suggestion.dart';

class MockData {
  static final _rng = Random();

  // ─── Dish photos (Wikimedia Commons; each checked to show the named dish) ───
  static const _imgAlooGobi =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c8/Aloo_gobi.jpg/960px-Aloo_gobi.jpg';
  static const _imgAlooParatha =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/85/Aloo_Paratha_%2896238%29.jpg/960px-Aloo_Paratha_%2896238%29.jpg';
  static const _imgBiryani =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/Chicken_Hyderabadi_Biryani.JPG/960px-Chicken_Hyderabadi_Biryani.JPG';
  static const _imgButterChicken =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/Murgh_Makhani_%28Butter_Chicken%29_2_%288925280003%29.jpg/960px-Murgh_Makhani_%28Butter_Chicken%29_2_%288925280003%29.jpg';
  static const _imgCappuccino =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/70/Cappuccino_in_original.jpg/960px-Cappuccino_in_original.jpg';
  static const _imgChickenBiryani =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/23/A_home_made_plate_of_mutton_biryani_served_with_chicken_kassa_cooked_in_the_bengali_style.jpg/960px-A_home_made_plate_of_mutton_biryani_served_with_chicken_kassa_cooked_in_the_bengali_style.jpg';
  static const _imgCholeBhature =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7c/Chole_Bhature_6.jpg/960px-Chole_Bhature_6.jpg';
  static const _imgDalMakhani =
      'https://upload.wikimedia.org/wikipedia/commons/f/f8/Dal_Makhani.jpg';
  static const _imgDalTadka =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/73/Dal_tadka_and_naan.jpg/960px-Dal_tadka_and_naan.jpg';
  static const _imgDhokla =
      'https://upload.wikimedia.org/wikipedia/commons/6/65/Dhokla_on_Gujrart.jpg';
  static const _imgDimSum =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f6/Dim_Sum_Breakfast.jpg/960px-Dim_Sum_Breakfast.jpg';
  static const _imgEggBhurji =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/06/Spicy_egg_bhurji_%40_the_eggfactory.jpg/960px-Spicy_egg_bhurji_%40_the_eggfactory.jpg';
  static const _imgEggFriedRice =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c9/Egg_Fried_Rice.jpg/960px-Egg_Fried_Rice.jpg';
  static const _imgFishCurry =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/36/Kerala_spicy_Fish_Curry.jpg/960px-Kerala_spicy_Fish_Curry.jpg';
  static const _imgGarlicPrawns =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f4/Prawns_in_garlic_butter_-_Taupo%2C_New_Zealand.jpg/960px-Prawns_in_garlic_butter_-_Taupo%2C_New_Zealand.jpg';
  static const _imgHakkaNoodles =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a0/Tasty_hakka_noodles_image.jpg/960px-Tasty_hakka_noodles_image.jpg';
  static const _imgIdli =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/02/Idli_Sambar-Noida-UP-SP004.jpg/960px-Idli_Sambar-Noida-UP-SP004.jpg';
  static const _imgMasalaDosa =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Masala_dosa_01.jpg/960px-Masala_dosa_01.jpg';
  static const _imgMysoreDosa =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d9/Mysore_masala_dosa_in_Mysuru%2C_July_2013.jpg/960px-Mysore_masala_dosa_in_Mysuru%2C_July_2013.jpg';
  static const _imgOatsUpma =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c6/Oats_Upma...yummy.jpg/960px-Oats_Upma...yummy.jpg';
  static const _imgOvernightOats =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fd/Protein_overnight_oats.jpg/960px-Protein_overnight_oats.jpg';
  static const _imgPalakPaneer =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b5/Palak_Paneer_at_WCI_2023.jpg/960px-Palak_Paneer_at_WCI_2023.jpg';
  static const _imgPalakParatha =
      'https://upload.wikimedia.org/wikipedia/commons/3/3f/Awadhi_palak_paneer_paratha_dahi.jpg';
  static const _imgPaneerButterMasala =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/Paneer_butter_masala_2.jpg/960px-Paneer_butter_masala_2.jpg';
  static const _imgPaneerTikka =
      'https://upload.wikimedia.org/wikipedia/commons/a/a5/Malai_Paneer_Tikka%2C_PK_007.jpg';
  static const _imgPaneerWrap =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Paneer_kathi_roll_homemade.jpg/960px-Paneer_kathi_roll_homemade.jpg';
  static const _imgPaniPuri =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5c/Crispy_Pani_Puri.jpg/960px-Crispy_Pani_Puri.jpg';
  static const _imgPeriPeriChicken =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/32/2018-02-03_Chicken_Piri-Piri%2C_Albufeira_%281%29.JPG/960px-2018-02-03_Chicken_Piri-Piri%2C_Albufeira_%281%29.JPG';
  static const _imgPizza =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/de/Margherita_pizza_on_plate.jpg/960px-Margherita_pizza_on_plate.jpg';
  static const _imgPoha =
      'https://upload.wikimedia.org/wikipedia/commons/8/85/Poha_in_the_Morning_-_Indori_Food.jpg';
  static const _imgPunjabiThali =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/99/Punjabi_Thali.JPG/960px-Punjabi_Thali.JPG';
  static const _imgRajmaChawal =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1b/Rajma_Rice.JPG/960px-Rajma_Rice.JPG';
  static const _imgSabudanaKhichdi =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Sabudana_Khichdi_with_Sweet_curd.JPG/960px-Sabudana_Khichdi_with_Sweet_curd.JPG';
  static const _imgSouthThali =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/South_Indian_Thali_Cropped.jpg/960px-South_Indian_Thali_Cropped.jpg';
  static const _imgTomatoSoup =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1c/Empty_tomato_soup_dish_and_wine_glass.jpg/960px-Empty_tomato_soup_dish_and_wine_glass.jpg';
  static const _imgUpma =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/A_photo_of_Upma.jpg/960px-A_photo_of_Upma.jpg';
  static const _imgVegWrap =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Vegetable_Wrap_%28toasted%29_-_The_naan_hut_2023-12-22.jpg/960px-Vegetable_Wrap_%28toasted%29_-_The_naan_hut_2023-12-22.jpg';

  // ─── Full Recipes ──────────────────────────────────────────────────────────
  static const List<Recipe> recipes = [
    Recipe(
      id: 'r1',
      title: 'Dal Tadka',
      description: 'A comforting yellow lentil curry tempered with ghee and spices. Quick, protein-rich and deeply satisfying.',
      imageUrl: _imgDalTadka,
      mealType: 'lunch',
      path: 'cook',
      tags: ['veg', 'quick', 'protein', 'comfort', 'north-indian'],
      healthHighlights: ['High in protein', 'Good source of fibre', 'Light on oil'],
      nutrition: NutritionInfo(calories: 320, proteinG: 18, carbsG: 42, fatG: 8, fiberG: 9),
      healthyNutrition: NutritionInfo(calories: 240, proteinG: 19, carbsG: 36, fatG: 4, fiberG: 11),
      ingredients: [
        '1 cup yellow moong dal',
        '2 tomatoes, chopped',
        '1 onion, finely chopped',
        '2 tsp ghee',
        '1 tsp cumin seeds',
        '½ tsp turmeric',
        '1 tsp coriander powder',
        '½ tsp red chilli powder',
        'Salt to taste',
        'Fresh coriander for garnish',
      ],
      healthyIngredients: [
        '1 cup yellow moong dal',
        '2 tomatoes, chopped',
        '1 onion, finely chopped',
        '1 tsp olive oil (instead of ghee)',
        '1 tsp cumin seeds',
        '½ tsp turmeric',
        '1 tsp coriander powder',
        'Salt to taste',
        'Fresh coriander for garnish',
      ],
      steps: [
        'Wash and pressure cook dal with turmeric and salt until soft (3 whistles).',
        'Heat ghee in a pan. Add cumin seeds and let them splutter.',
        'Add onions and sauté until golden.',
        'Add tomatoes, coriander powder, and chilli powder. Cook until oil separates.',
        'Pour in the cooked dal and simmer for 5 minutes.',
        'Garnish with fresh coriander and serve hot with rice or roti.',
      ],
      healthySteps: [
        'Wash and pressure cook dal with turmeric and salt until soft.',
        'Heat olive oil in a non-stick pan. Add cumin seeds.',
        'Add onions and sauté until translucent (use minimal oil).',
        'Add tomatoes and coriander powder. Cook until mushy.',
        'Pour in the cooked dal and simmer for 5 minutes.',
        'Garnish with coriander. Skip the final ghee drizzle.',
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 25,
      cuisineType: 'North Indian',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r2',
      title: 'Paneer Butter Masala',
      description: 'Creamy tomato-based curry with soft paneer cubes. Rich, aromatic and perfect with naan or jeera rice.',
      imageUrl: _imgPaneerButterMasala,
      mealType: 'dinner',
      path: 'cook',
      tags: ['veg', 'rich', 'creamy', 'north-indian'],
      healthHighlights: ['High in protein', 'Calcium-rich'],
      nutrition: NutritionInfo(calories: 480, proteinG: 22, carbsG: 28, fatG: 32, fiberG: 4),
      healthyNutrition: NutritionInfo(calories: 320, proteinG: 24, carbsG: 22, fatG: 16, fiberG: 5),
      ingredients: [
        '250g paneer, cubed',
        '3 large tomatoes',
        '1 onion',
        '2 tbsp butter',
        '2 tbsp cream',
        '1 tsp ginger-garlic paste',
        '1 tsp garam masala',
        '1 tsp kashmiri red chilli powder',
        '1 tsp sugar',
        'Salt to taste',
      ],
      healthyIngredients: [
        '250g low-fat paneer, cubed',
        '3 large tomatoes',
        '1 onion',
        '1 tsp olive oil (instead of butter)',
        '2 tbsp low-fat yoghurt (instead of cream)',
        '1 tsp ginger-garlic paste',
        '1 tsp garam masala',
        '1 tsp kashmiri chilli powder',
        'Salt to taste',
      ],
      steps: [
        'Blend tomatoes and onion into a smooth puree.',
        'Heat butter in a pan. Add ginger-garlic paste and sauté for 1 minute.',
        'Add the puree and cook on medium heat until oil separates (10-12 min).',
        'Add garam masala, chilli powder, sugar and salt. Stir well.',
        'Add paneer cubes and simmer for 5 minutes.',
        'Stir in cream and serve hot.',
      ],
      healthySteps: [
        'Blend tomatoes and onion into a smooth puree.',
        'Heat olive oil. Add ginger-garlic paste and sauté.',
        'Add the puree and cook until oil separates.',
        'Add spices and salt.',
        'Add paneer cubes and simmer.',
        'Stir in low-fat yoghurt and serve.',
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 25,
      cuisineType: 'North Indian',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r3',
      title: 'Masala Idli',
      description: 'Soft steamed rice cakes served with sambar and two chutneys. Light, filling and classically South Indian.',
      imageUrl: _imgIdli,
      mealType: 'breakfast',
      path: 'cook',
      tags: ['veg', 'light', 'south-indian', 'fermented'],
      healthHighlights: ['Low in fat', 'Fermented and gut-friendly', 'Good source of carbs'],
      nutrition: NutritionInfo(calories: 210, proteinG: 8, carbsG: 44, fatG: 2, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 180, proteinG: 9, carbsG: 38, fatG: 1, fiberG: 4),
      ingredients: [
        '4 idlis (from batter or readymade)',
        'Sambar (readymade or homemade)',
        'Coconut chutney',
        'Tomato chutney',
        'Mustard seeds for tempering',
        'Curry leaves',
      ],
      steps: [
        'Steam idlis in an idli maker for 10-12 minutes.',
        'Heat sambar and season with a mustard-curry leaf tadka.',
        'Prepare coconut chutney by blending coconut, green chilli and coriander.',
        'Serve idlis hot with sambar and chutneys on the side.',
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 15,
      cuisineType: 'South Indian',
      hasHealthyVersion: false,
    ),
    Recipe(
      id: 'r4',
      title: 'Hyderabadi Chicken Biryani',
      description: 'Fragrant basmati rice slow-cooked with spiced chicken, saffron and caramelised onions. A complete feast.',
      imageUrl: _imgBiryani,
      mealType: 'dinner',
      path: 'cook',
      tags: ['non-veg', 'spicy', 'filling', 'hyderabadi'],
      healthHighlights: ['High in protein', 'Iron-rich'],
      nutrition: NutritionInfo(calories: 580, proteinG: 36, carbsG: 68, fatG: 18, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 420, proteinG: 38, carbsG: 52, fatG: 10, fiberG: 4),
      ingredients: [
        '500g chicken pieces',
        '2 cups basmati rice (soaked)',
        '2 onions, thinly sliced',
        '1 cup yoghurt',
        '2 tbsp biryani masala',
        '3 tbsp ghee',
        'Saffron soaked in warm milk',
        'Fresh mint and coriander',
        'Fried onions (birista)',
        'Whole spices: bay leaf, cardamom, cloves',
      ],
      healthyIngredients: [
        '500g skinless chicken pieces',
        '2 cups brown basmati rice (soaked)',
        '1 onion, thinly sliced',
        '1 cup low-fat yoghurt',
        '2 tbsp biryani masala',
        '1 tbsp olive oil (instead of ghee)',
        'Pinch of saffron',
        'Fresh mint and coriander',
        'Whole spices',
      ],
      steps: [
        'Marinate chicken with yoghurt, biryani masala and salt for 30 minutes.',
        'Fry onions in ghee until golden and crisp. Set aside.',
        'Par-boil rice with whole spices until 70% cooked.',
        'Layer chicken at the bottom of a heavy pot, then rice, then fried onions.',
        'Drizzle saffron milk on top. Seal with dough or foil.',
        'Dum-cook on low heat for 25 minutes.',
        'Open, toss gently and serve with raita.',
      ],
      healthySteps: [
        'Marinate chicken with low-fat yoghurt and biryani masala.',
        'Sauté onion in olive oil until golden.',
        'Par-boil brown rice with whole spices.',
        'Layer chicken, then rice, then onions in a pot.',
        'Drizzle saffron milk. Cover and cook on low for 30 minutes.',
        'Serve with cucumber raita.',
      ],
      prepTimeMinutes: 30,
      cookTimeMinutes: 45,
      cuisineType: 'Hyderabadi',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r5',
      title: 'Poha',
      description: 'Flattened rice tossed with peanuts, onions and spices. A classic quick Indian breakfast.',
      imageUrl: _imgPoha,
      mealType: 'breakfast',
      path: 'cook',
      tags: ['veg', 'quick', 'light', 'maharashtrian'],
      healthHighlights: ['Iron-enriched', 'Easy to digest', 'Low calorie'],
      nutrition: NutritionInfo(calories: 250, proteinG: 7, carbsG: 48, fatG: 5, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 210, proteinG: 9, carbsG: 42, fatG: 3, fiberG: 4),
      ingredients: [
        '1.5 cups poha (flattened rice)',
        '1 onion, chopped',
        '2 green chillies, slit',
        '¼ cup roasted peanuts',
        '1 tsp mustard seeds',
        '8-10 curry leaves',
        '½ tsp turmeric',
        '1 tsp oil',
        'Juice of ½ lemon',
        'Salt and sugar to taste',
        'Fresh coriander',
      ],
      steps: [
        'Rinse poha under water until soft but not mushy. Drain well.',
        'Heat oil. Add mustard seeds and let them pop.',
        'Add curry leaves, green chillies and onion. Sauté until soft.',
        'Add peanuts and turmeric. Stir for 1 minute.',
        'Add drained poha. Mix gently. Season with salt and a pinch of sugar.',
        'Finish with lemon juice and fresh coriander.',
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 10,
      cuisineType: 'Maharashtrian',
      hasHealthyVersion: false,
    ),
    Recipe(
      id: 'r6',
      title: 'Chole Bhature',
      description: 'Spicy chickpea curry served with fluffy deep-fried bread. A beloved Punjabi indulgence.',
      imageUrl: _imgCholeBhature,
      mealType: 'lunch',
      path: 'cook',
      tags: ['veg', 'spicy', 'filling', 'punjabi'],
      healthHighlights: ['High in fibre', 'Plant protein', 'Iron-rich'],
      nutrition: NutritionInfo(calories: 620, proteinG: 20, carbsG: 88, fatG: 22, fiberG: 14),
      healthyNutrition: NutritionInfo(calories: 380, proteinG: 21, carbsG: 58, fatG: 8, fiberG: 16),
      ingredients: [
        '1.5 cups chickpeas (soaked overnight)',
        '2 onions',
        '3 tomatoes',
        '2 tbsp chole masala',
        '1 tsp ginger-garlic paste',
        '2 cups maida for bhature',
        '¼ cup curd',
        'Oil for deep frying',
      ],
      healthyIngredients: [
        '1.5 cups chickpeas (soaked overnight)',
        '2 onions',
        '3 tomatoes',
        '2 tbsp chole masala',
        '1 tsp ginger-garlic paste',
        '2 whole wheat rotis (instead of bhature)',
        'Minimal oil',
      ],
      steps: [
        'Pressure cook chickpeas with a tea bag for colour (4 whistles).',
        'Make a masala with onions, tomatoes, ginger-garlic and chole masala.',
        'Add chickpeas to the masala and simmer for 15 minutes.',
        'For bhature: knead maida with curd, oil and salt. Rest 30 min.',
        'Roll and deep-fry bhature until puffed and golden.',
        'Serve chole with bhature, onion rings and green chutney.',
      ],
      healthySteps: [
        'Pressure cook chickpeas until tender.',
        'Make a dry masala with minimal oil, onions, tomatoes and spices.',
        'Add chickpeas and simmer until thick.',
        'Serve with whole wheat rotis instead of bhature.',
      ],
      prepTimeMinutes: 20,
      cookTimeMinutes: 35,
      cuisineType: 'Punjabi',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r7',
      title: 'Masala Dosa',
      description: 'Crispy fermented rice crepe filled with spiced potato. A South Indian classic loved nationwide.',
      imageUrl: _imgMasalaDosa,
      mealType: 'breakfast',
      path: 'cook',
      tags: ['veg', 'south-indian', 'crispy', 'fermented'],
      healthHighlights: ['Fermented and gut-friendly', 'Good carbs', 'Iron-rich'],
      nutrition: NutritionInfo(calories: 280, proteinG: 9, carbsG: 52, fatG: 6, fiberG: 3),
      ingredients: [
        '1 cup dosa batter (readymade or homemade)',
        '2 potatoes, boiled and mashed',
        '1 onion, chopped',
        '1 tsp mustard seeds',
        '8 curry leaves',
        '½ tsp turmeric',
        '2 green chillies',
        'Oil for cooking',
      ],
      steps: [
        'Heat oil. Add mustard seeds, curry leaves and green chillies.',
        'Add onion and sauté until soft.',
        'Add turmeric and mashed potatoes. Mix well. Season with salt.',
        'Spread dosa batter thin on a hot tawa. Drizzle oil around edges.',
        'Place potato filling in the center. Fold and serve with sambar and chutney.',
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      cuisineType: 'South Indian',
      hasHealthyVersion: false,
    ),
    Recipe(
      id: 'r8',
      title: 'Veg Hakka Noodles',
      description: 'Stir-fried noodles with crispy vegetables and Indo-Chinese sauces. Street-food favourite.',
      imageUrl: _imgHakkaNoodles,
      mealType: 'dinner',
      path: 'cook',
      tags: ['veg', 'chinese', 'quick', 'spicy'],
      healthHighlights: ['Quick to make', 'Veggie-loaded'],
      nutrition: NutritionInfo(calories: 380, proteinG: 10, carbsG: 62, fatG: 12, fiberG: 4),
      healthyNutrition: NutritionInfo(calories: 290, proteinG: 12, carbsG: 48, fatG: 6, fiberG: 6),
      ingredients: [
        '200g hakka noodles',
        '1 cup mixed vegetables (carrot, cabbage, capsicum, beans)',
        '2 tbsp soy sauce',
        '1 tbsp chilli sauce',
        '1 tbsp vinegar',
        '2 spring onions',
        '2 cloves garlic, minced',
        '2 tbsp oil',
      ],
      healthyIngredients: [
        '200g whole wheat noodles',
        '1.5 cups mixed vegetables',
        '1 tbsp low-sodium soy sauce',
        '1 tsp chilli sauce',
        '1 tsp vinegar',
        '2 spring onions',
        '2 cloves garlic',
        '1 tsp oil',
      ],
      steps: [
        'Boil noodles until al dente. Drain and toss with a drop of oil.',
        'Heat oil in a wok. Add garlic and stir-fry for 30 seconds.',
        'Add vegetables and toss on high heat for 2-3 minutes.',
        'Add soy sauce, chilli sauce and vinegar. Toss well.',
        'Add noodles and mix everything together on high heat.',
        'Garnish with spring onions and serve hot.',
      ],
      healthySteps: [
        'Boil whole wheat noodles. Drain and set aside.',
        'Heat minimal oil. Stir-fry garlic and extra vegetables.',
        'Add low-sodium soy sauce and light seasoning.',
        'Toss in noodles and mix on high heat.',
        'Serve garnished with spring onions.',
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      cuisineType: 'Indo-Chinese',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r9',
      title: 'Aloo Paratha',
      description: 'Stuffed whole wheat flatbread with spiced potato filling. A North Indian breakfast staple.',
      imageUrl: _imgAlooParatha,
      mealType: 'breakfast',
      path: 'cook',
      tags: ['veg', 'filling', 'north-indian', 'comfort'],
      healthHighlights: ['Whole wheat', 'Energy-rich', 'Satisfying'],
      nutrition: NutritionInfo(calories: 340, proteinG: 8, carbsG: 48, fatG: 14, fiberG: 4),
      ingredients: [
        '2 cups whole wheat flour',
        '2 potatoes, boiled and mashed',
        '1 green chilli, chopped',
        '1 tsp cumin seeds',
        '½ tsp garam masala',
        'Fresh coriander',
        'Ghee for cooking',
        'Salt to taste',
      ],
      steps: [
        'Knead dough with wheat flour, salt and water. Rest for 15 minutes.',
        'Mix mashed potato with chilli, cumin, garam masala, coriander and salt.',
        'Roll dough into balls. Flatten, fill with potato, seal and roll again.',
        'Cook on hot tawa with ghee until golden on both sides.',
        'Serve with curd, pickle and butter.',
      ],
      prepTimeMinutes: 20,
      cookTimeMinutes: 15,
      cuisineType: 'North Indian',
      hasHealthyVersion: false,
    ),
    Recipe(
      id: 'r10',
      title: 'Egg Fried Rice',
      description: 'Quick Indo-Chinese fried rice with scrambled eggs and vegetables. Satisfying one-pot meal.',
      imageUrl: _imgEggFriedRice,
      mealType: 'lunch',
      path: 'cook',
      tags: ['eggetarian', 'chinese', 'quick', 'filling'],
      healthHighlights: ['Protein from eggs', 'Quick energy', 'Veggie-loaded'],
      nutrition: NutritionInfo(calories: 420, proteinG: 16, carbsG: 58, fatG: 14, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 320, proteinG: 18, carbsG: 44, fatG: 8, fiberG: 5),
      ingredients: [
        '2 cups cooked basmati rice (day-old preferred)',
        '3 eggs',
        '1 cup mixed vegetables (carrot, peas, corn, beans)',
        '2 tbsp soy sauce',
        '1 tbsp oil',
        '3 cloves garlic, minced',
        '2 spring onions',
        'Salt and pepper to taste',
      ],
      healthyIngredients: [
        '2 cups cooked brown rice',
        '3 eggs (2 whole + 1 white)',
        '1.5 cups mixed vegetables',
        '1 tbsp low-sodium soy sauce',
        '1 tsp oil',
        '3 cloves garlic',
        '2 spring onions',
      ],
      steps: [
        'Heat oil in a wok. Scramble eggs and set aside.',
        'Add garlic, stir-fry vegetables for 2 minutes.',
        'Add rice and toss on high heat.',
        'Add soy sauce, salt and pepper. Mix well.',
        'Add scrambled eggs back. Toss everything together.',
        'Garnish with spring onions. Serve hot.',
      ],
      healthySteps: [
        'Scramble eggs in minimal oil.',
        'Stir-fry garlic and extra vegetables.',
        'Add brown rice and toss.',
        'Season lightly with low-sodium soy sauce.',
        'Mix in eggs. Serve with spring onion garnish.',
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 15,
      cuisineType: 'Indo-Chinese',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r11',
      title: 'Palak Paneer',
      description: 'Creamy spinach curry with soft paneer cubes. Nutritious, flavourful and a veg favourite.',
      imageUrl: _imgPalakPaneer,
      mealType: 'lunch',
      path: 'cook',
      tags: ['veg', 'healthy', 'north-indian', 'protein'],
      healthHighlights: ['Iron-rich spinach', 'High in protein', 'Good fats'],
      nutrition: NutritionInfo(calories: 380, proteinG: 20, carbsG: 18, fatG: 26, fiberG: 6),
      healthyNutrition: NutritionInfo(calories: 280, proteinG: 22, carbsG: 16, fatG: 14, fiberG: 7),
      ingredients: [
        '200g paneer, cubed',
        '300g spinach, blanched',
        '1 onion, chopped',
        '2 tomatoes, chopped',
        '1 tsp ginger-garlic paste',
        '1 tsp cumin seeds',
        '½ tsp garam masala',
        '2 tbsp cream',
        '1 tbsp butter',
        'Salt to taste',
      ],
      healthyIngredients: [
        '200g low-fat paneer, cubed',
        '300g spinach, blanched',
        '1 onion, chopped',
        '2 tomatoes',
        '1 tsp ginger-garlic paste',
        '1 tsp cumin seeds',
        '1 tsp olive oil',
        'Salt to taste',
      ],
      steps: [
        'Blanch spinach in boiling water for 2 minutes. Blend into a smooth paste.',
        'Heat butter. Add cumin seeds, then onion and garlic paste. Sauté.',
        'Add tomatoes and cook until soft.',
        'Add spinach paste and simmer for 5 minutes.',
        'Add paneer cubes and garam masala. Cook for 3 minutes.',
        'Finish with cream. Serve with roti or rice.',
      ],
      healthySteps: [
        'Blanch and blend spinach.',
        'Sauté onion and garlic in olive oil.',
        'Add tomatoes and cook.',
        'Add spinach paste. Simmer.',
        'Add low-fat paneer. Skip cream.',
        'Serve with whole wheat roti.',
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      cuisineType: 'North Indian',
      hasHealthyVersion: true,
    ),
    Recipe(
      id: 'r12',
      title: 'Upma',
      description: 'Savoury semolina dish tempered with mustard seeds, curry leaves and vegetables. Quick South Indian breakfast.',
      imageUrl: _imgUpma,
      mealType: 'breakfast',
      path: 'cook',
      tags: ['veg', 'south-indian', 'quick', 'light'],
      healthHighlights: ['Quick energy', 'Low fat', 'Fibre from vegetables'],
      nutrition: NutritionInfo(calories: 220, proteinG: 6, carbsG: 38, fatG: 6, fiberG: 3),
      ingredients: [
        '1 cup rava (semolina)',
        '1 onion, chopped',
        '1 green chilli',
        '1 tsp mustard seeds',
        '8 curry leaves',
        '½ cup mixed vegetables (carrot, peas, beans)',
        '2 tsp oil',
        'Salt to taste',
        'Juice of ½ lemon',
      ],
      steps: [
        'Dry roast rava until lightly golden and fragrant. Set aside.',
        'Heat oil. Add mustard seeds, curry leaves and green chilli.',
        'Add onion and vegetables. Sauté for 3-4 minutes.',
        'Add 2.5 cups water and salt. Bring to a boil.',
        'Slowly add rava, stirring continuously to avoid lumps.',
        'Cook on low heat for 2-3 minutes. Add lemon juice and serve.',
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 12,
      cuisineType: 'South Indian',
      hasHealthyVersion: false,
    ),
  ];

  // ─── Suggestions (expanded pool for diverse recommendations) ──────────────
  static const List<Suggestion> _allCookSuggestions = [
    Suggestion(
      id: 's1', title: 'Dal Tadka with Rice',
      subtitle: '30 min · Veg · North Indian', path: 'cook', imageUrl: _imgDalTadka,
      nutrition: NutritionInfo(calories: 420, proteinG: 20, carbsG: 70, fatG: 8, fiberG: 10),
      healthyNutrition: NutritionInfo(calories: 320, proteinG: 21, carbsG: 58, fatG: 4, fiberG: 12),
      hasHealthyVersion: true, healthHighlights: ['High in protein', 'Good source of fibre'],
      tags: ['veg', 'quick', 'comfort', 'lunch', 'dinner', 'light', 'north-indian'], recipeId: 'r1',
    ),
    Suggestion(
      id: 's2', title: 'Paneer Butter Masala',
      subtitle: '35 min · Veg · North Indian', path: 'cook', imageUrl: _imgPaneerButterMasala,
      nutrition: NutritionInfo(calories: 480, proteinG: 22, carbsG: 28, fatG: 32, fiberG: 4),
      healthyNutrition: NutritionInfo(calories: 320, proteinG: 24, carbsG: 22, fatG: 16, fiberG: 5),
      hasHealthyVersion: true, healthHighlights: ['High in protein', 'Calcium-rich'],
      tags: ['veg', 'creamy', 'rich', 'dinner', 'north-indian', 'comfort'], recipeId: 'r2',
    ),
    Suggestion(
      id: 's3', title: 'Chole Bhature',
      subtitle: '55 min · Veg · Punjabi', path: 'cook', imageUrl: _imgCholeBhature,
      nutrition: NutritionInfo(calories: 620, proteinG: 20, carbsG: 88, fatG: 22, fiberG: 14),
      healthyNutrition: NutritionInfo(calories: 380, proteinG: 21, carbsG: 58, fatG: 8, fiberG: 16),
      hasHealthyVersion: true, healthHighlights: ['High in fibre', 'Plant protein'],
      tags: ['veg', 'spicy', 'filling', 'lunch', 'north-indian', 'punjabi'], recipeId: 'r6',
    ),
    Suggestion(
      id: 's10', title: 'Masala Dosa',
      subtitle: '25 min · Veg · South Indian', path: 'cook', imageUrl: _imgMasalaDosa,
      nutrition: NutritionInfo(calories: 280, proteinG: 9, carbsG: 52, fatG: 6, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['Fermented', 'Light on stomach'],
      tags: ['veg', 'south-indian', 'breakfast', 'light', 'crispy'], recipeId: 'r7',
    ),
    Suggestion(
      id: 's11', title: 'Poha',
      subtitle: '15 min · Veg · Quick', path: 'cook', imageUrl: _imgPoha,
      nutrition: NutritionInfo(calories: 250, proteinG: 7, carbsG: 48, fatG: 5, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['Iron-enriched', 'Easy to digest'],
      tags: ['veg', 'quick', 'light', 'breakfast', 'maharashtrian'], recipeId: 'r5',
    ),
    Suggestion(
      id: 's12', title: 'Masala Idli',
      subtitle: '20 min · Veg · South Indian', path: 'cook', imageUrl: _imgIdli,
      nutrition: NutritionInfo(calories: 210, proteinG: 8, carbsG: 44, fatG: 2, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['Low fat', 'Gut-friendly'],
      tags: ['veg', 'south-indian', 'breakfast', 'light', 'fermented'], recipeId: 'r3',
    ),
    Suggestion(
      id: 's13', title: 'Hyderabadi Chicken Biryani',
      subtitle: '75 min · Non-veg · Spicy', path: 'cook', imageUrl: _imgBiryani,
      nutrition: NutritionInfo(calories: 580, proteinG: 36, carbsG: 68, fatG: 18, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 420, proteinG: 38, carbsG: 52, fatG: 10, fiberG: 4),
      hasHealthyVersion: true, healthHighlights: ['High in protein', 'Iron-rich'],
      tags: ['non-veg', 'spicy', 'filling', 'dinner', 'hyderabadi', 'rice'], recipeId: 'r4',
    ),
    Suggestion(
      id: 's14', title: 'Veg Hakka Noodles',
      subtitle: '25 min · Veg · Indo-Chinese', path: 'cook', imageUrl: _imgHakkaNoodles,
      nutrition: NutritionInfo(calories: 380, proteinG: 10, carbsG: 62, fatG: 12, fiberG: 4),
      healthyNutrition: NutritionInfo(calories: 290, proteinG: 12, carbsG: 48, fatG: 6, fiberG: 6),
      hasHealthyVersion: true, healthHighlights: ['Veggie-loaded', 'Quick'],
      tags: ['veg', 'chinese', 'quick', 'spicy', 'dinner', 'snack'], recipeId: 'r8',
    ),
    Suggestion(
      id: 's15', title: 'Aloo Paratha',
      subtitle: '35 min · Veg · North Indian', path: 'cook', imageUrl: _imgAlooParatha,
      nutrition: NutritionInfo(calories: 340, proteinG: 8, carbsG: 48, fatG: 14, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Whole wheat', 'Energy-rich'],
      tags: ['veg', 'north-indian', 'breakfast', 'filling', 'comfort'], recipeId: 'r9',
    ),
    Suggestion(
      id: 's16', title: 'Egg Fried Rice',
      subtitle: '20 min · Egg · Indo-Chinese', path: 'cook', imageUrl: _imgEggFriedRice,
      nutrition: NutritionInfo(calories: 420, proteinG: 16, carbsG: 58, fatG: 14, fiberG: 3),
      healthyNutrition: NutritionInfo(calories: 320, proteinG: 18, carbsG: 44, fatG: 8, fiberG: 5),
      hasHealthyVersion: true, healthHighlights: ['Protein from eggs', 'Quick'],
      tags: ['eggetarian', 'chinese', 'quick', 'lunch', 'dinner', 'rice'], recipeId: 'r10',
    ),
    Suggestion(
      id: 's17', title: 'Palak Paneer',
      subtitle: '30 min · Veg · Healthy', path: 'cook', imageUrl: _imgPalakPaneer,
      nutrition: NutritionInfo(calories: 380, proteinG: 20, carbsG: 18, fatG: 26, fiberG: 6),
      healthyNutrition: NutritionInfo(calories: 280, proteinG: 22, carbsG: 16, fatG: 14, fiberG: 7),
      hasHealthyVersion: true, healthHighlights: ['Iron-rich', 'Protein-packed'],
      tags: ['veg', 'north-indian', 'healthy', 'lunch', 'dinner', 'protein'], recipeId: 'r11',
    ),
    Suggestion(
      id: 's18', title: 'Upma',
      subtitle: '17 min · Veg · South Indian', path: 'cook', imageUrl: _imgUpma,
      nutrition: NutritionInfo(calories: 220, proteinG: 6, carbsG: 38, fatG: 6, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['Quick energy', 'Low fat'],
      tags: ['veg', 'south-indian', 'quick', 'breakfast', 'light'], recipeId: 'r12',
    ),
  ];

  static const List<Suggestion> _allOrderSuggestions = [
    Suggestion(
      id: 's4', title: 'Chicken Biryani',
      subtitle: 'Behrouz Biryani · 30 min · ₹320', path: 'order', imageUrl: _imgChickenBiryani,
      nutrition: NutritionInfo(calories: 580, proteinG: 36, carbsG: 68, fatG: 18, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['High in protein', 'Iron-rich'],
      tags: ['non-veg', 'spicy', 'filling', 'dinner', 'lunch'], recipeId: 'r4',
    ),
    Suggestion(
      id: 's5', title: 'Margherita Pizza',
      subtitle: 'Domino\'s · 25 min · ₹249', path: 'order', imageUrl: _imgPizza,
      nutrition: NutritionInfo(calories: 520, proteinG: 18, carbsG: 72, fatG: 18, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Calcium-rich'],
      tags: ['veg', 'cheesy', 'filling', 'dinner', 'snack'], recipeId: 's5',
    ),
    Suggestion(
      id: 's6', title: 'Grilled Veggie Wrap',
      subtitle: 'Subway · 20 min · ₹199', path: 'order', imageUrl: _imgVegWrap,
      nutrition: NutritionInfo(calories: 320, proteinG: 14, carbsG: 48, fatG: 8, fiberG: 6),
      healthyNutrition: NutritionInfo(calories: 260, proteinG: 15, carbsG: 38, fatG: 5, fiberG: 8),
      hasHealthyVersion: true, healthHighlights: ['High in fibre', 'Low in fat'],
      tags: ['veg', 'light', 'fresh', 'lunch', 'healthy'], recipeId: 's6',
    ),
    Suggestion(
      id: 's19', title: 'Butter Chicken with Naan',
      subtitle: 'Amritsari Dhaba · 35 min · ₹380', path: 'order', imageUrl: _imgButterChicken,
      nutrition: NutritionInfo(calories: 650, proteinG: 32, carbsG: 58, fatG: 28, fiberG: 3),
      hasHealthyVersion: false, healthHighlights: ['High protein', 'Iron-rich'],
      tags: ['non-veg', 'rich', 'comfort', 'dinner', 'north-indian'], recipeId: 's19',
    ),
    Suggestion(
      id: 's20', title: 'Paneer Tikka Wrap',
      subtitle: 'FreshMenu · 25 min · ₹229', path: 'order', imageUrl: _imgPaneerWrap,
      nutrition: NutritionInfo(calories: 390, proteinG: 18, carbsG: 42, fatG: 16, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Protein-rich', 'Balanced'],
      tags: ['veg', 'north-indian', 'lunch', 'snack'], recipeId: 's20',
    ),
    Suggestion(
      id: 's21', title: 'Veg Thali',
      subtitle: 'Saravana Bhavan · 30 min · ₹280', path: 'order', imageUrl: _imgSouthThali,
      nutrition: NutritionInfo(calories: 480, proteinG: 16, carbsG: 72, fatG: 14, fiberG: 8),
      hasHealthyVersion: false, healthHighlights: ['Balanced meal', 'Fibre-rich'],
      tags: ['veg', 'south-indian', 'lunch', 'comfort', 'filling'], recipeId: 's21',
    ),
  ];

  static const List<Suggestion> _allDineSuggestions = [
    Suggestion(
      id: 's7', title: 'Saravana Bhavan',
      subtitle: 'South Indian · 0.8 km · ₹₹', path: 'dine', imageUrl: _imgMysoreDosa,
      nutrition: NutritionInfo(calories: 380, proteinG: 12, carbsG: 62, fatG: 10, fiberG: 5),
      hasHealthyVersion: false, healthHighlights: ['Fermented foods', 'Light on stomach'],
      tags: ['veg', 'south-indian', 'comfort', 'lunch', 'casual'], recipeId: 's7',
    ),
    Suggestion(
      id: 's8', title: 'Punjabi by Nature',
      subtitle: 'North Indian · 1.2 km · ₹₹₹', path: 'dine', imageUrl: _imgPunjabiThali,
      nutrition: NutritionInfo(calories: 650, proteinG: 28, carbsG: 80, fatG: 24, fiberG: 8),
      hasHealthyVersion: false, healthHighlights: ['Complete thali', 'Iron-rich'],
      tags: ['veg', 'non-veg', 'north-indian', 'hearty', 'dinner', 'special'], recipeId: 's8',
    ),
    Suggestion(
      id: 's9', title: 'The Brew Room',
      subtitle: 'Café / Continental · 0.5 km · ₹₹', path: 'dine', imageUrl: _imgCappuccino,
      nutrition: NutritionInfo(calories: 420, proteinG: 20, carbsG: 48, fatG: 16, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Good for sharing'],
      tags: ['veg', 'café', 'casual', 'snack', 'lunch', 'light'], recipeId: 's9',
    ),
    Suggestion(
      id: 's22', title: 'Mainland China',
      subtitle: 'Chinese · 2.0 km · ₹₹₹', path: 'dine', imageUrl: _imgDimSum,
      nutrition: NutritionInfo(calories: 520, proteinG: 22, carbsG: 60, fatG: 20, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Variety of options'],
      tags: ['veg', 'non-veg', 'chinese', 'dinner', 'special'], recipeId: 's22',
    ),
    Suggestion(
      id: 's23', title: 'Street Food Corner',
      subtitle: 'Chaat & Snacks · 0.3 km · ₹', path: 'dine', imageUrl: _imgPaniPuri,
      nutrition: NutritionInfo(calories: 300, proteinG: 8, carbsG: 48, fatG: 10, fiberG: 4),
      hasHealthyVersion: false, healthHighlights: ['Quick bite', 'Budget-friendly'],
      tags: ['veg', 'street-food', 'snack', 'quick', 'casual', 'spicy'], recipeId: 's23',
    ),
  ];

  /// Get diverse suggestions filtered by criteria.
  /// Returns 3 suggestions, randomized and filtered by method/meal/flavour.
  static List<Suggestion> getSuggestions({
    required String method,
    String? mealType,
    String? flavour,
  }) {
    List<Suggestion> pool;
    switch (method) {
      case 'order':
        pool = List.from(_allOrderSuggestions);
      case 'dine':
        pool = List.from(_allDineSuggestions);
      default:
        pool = List.from(_allCookSuggestions);
    }

    // Score and sort by relevance
    if (mealType != null || flavour != null) {
      pool.sort((a, b) {
        int scoreA = 0, scoreB = 0;
        if (mealType != null) {
          if (a.tags.contains(mealType.toLowerCase())) scoreA += 2;
          if (b.tags.contains(mealType.toLowerCase())) scoreB += 2;
        }
        if (flavour != null) {
          final fLower = flavour.toLowerCase();
          if (a.tags.contains(fLower)) scoreA += 1;
          if (b.tags.contains(fLower)) scoreB += 1;
        }
        return scoreB - scoreA; // Higher score first
      });
    } else {
      // No criteria — shuffle for variety
      pool.shuffle(_rng);
    }

    // Take top 3 but ensure variety (no duplicate recipeIds)
    final result = <Suggestion>[];
    final usedRecipes = <String>{};
    for (final s in pool) {
      if (!usedRecipes.contains(s.recipeId)) {
        result.add(s);
        usedRecipes.add(s.recipeId);
        if (result.length == 3) break;
      }
    }

    // If we still don't have 3, fill from remaining
    if (result.length < 3) {
      for (final s in pool) {
        if (!result.any((r) => r.id == s.id)) {
          result.add(s);
          if (result.length == 3) break;
        }
      }
    }

    return result;
  }

  /// Get all suggestions for a method (used by replaceSuggestion)
  static List<Suggestion> getAllSuggestions({required String method}) {
    switch (method) {
      case 'order': return _allOrderSuggestions;
      case 'dine': return _allDineSuggestions;
      default: return _allCookSuggestions;
    }
  }

  static Recipe? getRecipe(String id) {
    try {
      return recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Community Recipes ────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> communityRecipes = [
    {
      'id': 'c1', 'title': 'Masala Oats Upma', 'author': 'Priya S.', 'likes': 312,
      'mealType': 'breakfast', 'tags': ['veg', 'quick', 'healthy'],
      'imageUrl': _imgOatsUpma, 'calories': 280, 'cookTime': '15 min',
      'description': 'A savory, spiced oats dish that is quick, filling and surprisingly delicious.',
    },
    {
      'id': 'c2', 'title': 'Kerala Fish Curry', 'author': 'Arjun M.', 'likes': 289,
      'mealType': 'lunch', 'tags': ['non-veg', 'spicy', 'coastal'],
      'imageUrl': _imgFishCurry, 'calories': 380, 'cookTime': '30 min',
      'description': 'Tangy, spicy fish curry cooked in coconut milk and raw mango.',
    },
    {
      'id': 'c3', 'title': 'Palak Paneer Paratha', 'author': 'Sneha K.', 'likes': 241,
      'mealType': 'breakfast', 'tags': ['veg', 'healthy', 'filling'],
      'imageUrl': _imgPalakParatha, 'calories': 340, 'cookTime': '25 min',
      'description': 'Spinach-stuffed whole wheat flatbread with spiced paneer filling.',
    },
    {
      'id': 'c4', 'title': 'Rajma Chawal', 'author': 'Vikram D.', 'likes': 198,
      'mealType': 'lunch', 'tags': ['veg', 'vegan', 'comfort', 'filling'],
      'imageUrl': _imgRajmaChawal, 'calories': 460, 'cookTime': '45 min',
      'description': 'Classic kidney bean curry served over steamed basmati rice.',
    },
    {
      'id': 'c5', 'title': 'Peri Peri Chicken', 'author': 'Rohit B.', 'likes': 176,
      'mealType': 'dinner', 'tags': ['non-veg', 'spicy', 'grilled'],
      'imageUrl': _imgPeriPeriChicken, 'calories': 420, 'cookTime': '35 min',
      'description': 'Juicy grilled chicken marinated in homemade peri peri sauce.',
    },
    {
      'id': 'c6', 'title': 'Dhokla', 'author': 'Meera G.', 'likes': 165,
      'mealType': 'snack', 'tags': ['veg', 'light', 'fermented'],
      'imageUrl': _imgDhokla, 'calories': 180, 'cookTime': '25 min',
      'description': 'Soft, spongy steamed gram flour cake from Gujarat.',
    },
    {
      'id': 'c7', 'title': 'Mango Lassi Overnight Oats', 'author': 'Divya P.', 'likes': 154,
      'mealType': 'breakfast', 'tags': ['veg', 'sweet', 'healthy'],
      'imageUrl': _imgOvernightOats, 'calories': 320, 'cookTime': '5 min',
      'description': 'No-cook creamy oats with mango, yoghurt and a hint of cardamom.',
    },
    {
      'id': 'c8', 'title': 'Egg Bhurji Sandwich', 'author': 'Aditya R.', 'likes': 142,
      'mealType': 'breakfast', 'tags': ['eggetarian', 'quick', 'filling'],
      'imageUrl': _imgEggBhurji, 'calories': 360, 'cookTime': '10 min',
      'description': 'Spiced scrambled eggs with onion and tomato between toasted bread.',
    },
    {
      'id': 'c9', 'title': 'Aloo Gobi', 'author': 'Kavita S.', 'likes': 138,
      'mealType': 'lunch', 'tags': ['veg', 'vegan', 'comfort', 'spiced'],
      'imageUrl': _imgAlooGobi, 'calories': 280, 'cookTime': '30 min',
      'description': 'Dry-spiced cauliflower and potato stir-fry with fresh ginger.',
    },
    {
      'id': 'c10', 'title': 'Butter Garlic Prawns', 'author': 'Nikhil C.', 'likes': 127,
      'mealType': 'dinner', 'tags': ['non-veg', 'quick', 'coastal'],
      'imageUrl': _imgGarlicPrawns, 'calories': 350, 'cookTime': '15 min',
      'description': 'Juicy prawns cooked in garlic butter with herbs and lemon.',
    },
    {
      'id': 'c11', 'title': 'Sabudana Khichdi', 'author': 'Anjali T.', 'likes': 119,
      'mealType': 'snack', 'tags': ['veg', 'light', 'gluten-free'],
      'imageUrl': _imgSabudanaKhichdi, 'calories': 290, 'cookTime': '20 min',
      'description': 'Tapioca pearls with roasted peanuts, curry leaves and green chillies.',
    },
    {
      'id': 'c12', 'title': 'Tomato Soup with Croutons', 'author': 'Rahul M.', 'likes': 108,
      'mealType': 'snack', 'tags': ['veg', 'light', 'soothing'],
      'imageUrl': _imgTomatoSoup, 'calories': 160, 'cookTime': '20 min',
      'description': 'Smooth, tangy tomato soup with garlic croutons and fresh cream.',
    },
  ];

  // ─── Demo: a heavy breakfast and lunch (`?demo=heavy-day`) ─────────────────
  static const List<Map<String, dynamic>> heavyDayMeals = [
    {'title': 'Aloo Paratha', 'mealType': 'breakfast', 'hour': 9, 'minute': 10,
     'calories': 560, 'protein': 12, 'carbs': 70, 'fat': 26, 'imageUrl': _imgAlooParatha},
    {'title': 'Chole Bhature', 'mealType': 'lunch', 'hour': 13, 'minute': 35,
     'calories': 620, 'protein': 18, 'carbs': 78, 'fat': 28, 'imageUrl': _imgCholeBhature},
  ];

  // ─── Nudge messages ────────────────────────────────────────────────────────
  static const List<String> nudges = [
    "You've had a few rich meals this week. Something lighter tonight?",
    "Great week for balanced eating! Keep it up.",
    "Looks like dinner has been heavy lately. Want a lighter option?",
    "You're doing well with protein this week.",
    "Big lunch today — how about something light for dinner?",
  ];

  // ─── Home Page Categories (Zomato-style) ──────────────────────────────────

  static const List<Map<String, dynamic>> quickCategories = [
    {'icon': '🍳', 'label': 'Breakfast', 'doodle': 'idli', 'tag': 'breakfast'},
    {'icon': '🍛', 'label': 'Lunch', 'doodle': 'dal', 'tag': 'lunch'},
    {'icon': '🍿', 'label': 'Snacks', 'doodle': 'samosa', 'tag': 'snack'},
    {'icon': '🌙', 'label': 'Dinner', 'doodle': 'biryani', 'tag': 'dinner'},
    {'icon': '🥗', 'label': 'Healthy', 'doodle': 'avocado', 'tag': 'healthy'},
    {'icon': '⚡', 'label': 'Quick', 'doodle': 'momo', 'tag': 'quick'},
    {'icon': '🌶️', 'label': 'Spicy', 'doodle': 'chilli', 'tag': 'spicy'},
    {'icon': '🧁', 'label': 'Sweet', 'doodle': 'jalebi', 'tag': 'sweet'},
  ];

  static const List<Map<String, dynamic>> featuredRestaurants = [
    {
      'name': 'Saravana Bhavan', 'cuisine': 'South Indian',
      'rating': 4.5, 'deliveryTime': '25 min', 'priceRange': '₹₹',
      'imageUrl': _imgMysoreDosa, 'tags': ['veg', 'dosa', 'idli'],
    },
    {
      'name': 'Punjabi by Nature', 'cuisine': 'North Indian',
      'rating': 4.3, 'deliveryTime': '35 min', 'priceRange': '₹₹₹',
      'imageUrl': _imgPunjabiThali, 'tags': ['veg', 'non-veg', 'thali'],
    },
    {
      'name': 'Behrouz Biryani', 'cuisine': 'Mughlai · Biryani',
      'rating': 4.4, 'deliveryTime': '30 min', 'priceRange': '₹₹₹',
      'imageUrl': _imgBiryani, 'tags': ['non-veg', 'biryani', 'mughlai'],
    },
    {
      'name': 'The Brew Room', 'cuisine': 'Café · Continental',
      'rating': 4.2, 'deliveryTime': '20 min', 'priceRange': '₹₹',
      'imageUrl': _imgCappuccino, 'tags': ['coffee', 'sandwiches', 'pasta'],
    },
    {
      'name': 'Domino\'s Pizza', 'cuisine': 'Pizza · Italian',
      'rating': 4.0, 'deliveryTime': '25 min', 'priceRange': '₹₹',
      'imageUrl': _imgPizza, 'tags': ['pizza', 'pasta', 'fast-food'],
    },
  ];

  static const List<Map<String, dynamic>> celebrityChefRecipes = [
    {
      'title': 'Sanjeev Kapoor\'s Dal Makhani', 'chef': 'Sanjeev Kapoor',
      'imageUrl': _imgDalMakhani, 'cookTime': '45 min', 'rating': 4.8,
      'tags': ['veg', 'rich', 'punjabi'], 'recipeId': 'r1',
    },
    {
      'title': 'Ranveer Brar\'s Chicken Biryani', 'chef': 'Ranveer Brar',
      'imageUrl': _imgChickenBiryani, 'cookTime': '60 min', 'rating': 4.9,
      'tags': ['non-veg', 'spicy', 'festive'], 'recipeId': 'r4',
    },
    {
      'title': 'Vikas Khanna\'s Paneer Tikka', 'chef': 'Vikas Khanna',
      'imageUrl': _imgPaneerTikka, 'cookTime': '30 min', 'rating': 4.7,
      'tags': ['veg', 'smoky', 'tandoori'], 'recipeId': 'r2',
    },
    {
      'title': 'Tarla Dalal\'s Masala Idli', 'chef': 'Tarla Dalal',
      'imageUrl': _imgIdli, 'cookTime': '20 min', 'rating': 4.6,
      'tags': ['veg', 'south-indian', 'light'], 'recipeId': 'r3',
    },
  ];

  static const List<Map<String, dynamic>> trendingRecipes = [
    {
      'title': 'Poha', 'subtitle': '10 min · Light & easy',
      'imageUrl': _imgPoha, 'calories': 250,
      'tags': ['veg', 'quick', 'breakfast'], 'recipeId': 'r5',
    },
    {
      'title': 'Chole Bhature', 'subtitle': '55 min · Punjabi classic',
      'imageUrl': _imgCholeBhature, 'calories': 620,
      'tags': ['veg', 'spicy', 'filling'], 'recipeId': 'r6',
    },
    {
      'title': 'Dal Tadka', 'subtitle': '30 min · Comfort food',
      'imageUrl': _imgDalTadka, 'calories': 320,
      'tags': ['veg', 'protein', 'quick'], 'recipeId': 'r1',
    },
    {
      'title': 'Paneer Butter Masala', 'subtitle': '35 min · Rich & creamy',
      'imageUrl': _imgPaneerButterMasala, 'calories': 480,
      'tags': ['veg', 'creamy', 'north-indian'], 'recipeId': 'r2',
    },
  ];

  static const List<Map<String, dynamic>> starRecipes = [
    {
      'title': 'Hyderabadi Biryani', 'rating': 4.9, 'reviews': 2340,
      'imageUrl': _imgBiryani, 'recipeId': 'r4', 'badge': 'Most Loved',
    },
    {
      'title': 'Dal Tadka', 'rating': 4.7, 'reviews': 1890,
      'imageUrl': _imgDalTadka, 'recipeId': 'r1', 'badge': 'Editor\'s Pick',
    },
    {
      'title': 'Masala Idli', 'rating': 4.6, 'reviews': 1450,
      'imageUrl': _imgIdli, 'recipeId': 'r3', 'badge': 'Healthy Choice',
    },
  ];
}
