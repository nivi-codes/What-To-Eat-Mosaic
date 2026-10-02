// GET /api/community
// Returns community recipes for the Community tab.
// Static data for the demo — no AI needed here.

const COMMUNITY_RECIPES = [
  { id: 'c1', title: 'Masala Oats Upma', author: 'Priya S.', likes: 312, mealType: 'breakfast', tags: ['veg', 'quick', 'healthy'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c6/Oats_Upma...yummy.jpg/960px-Oats_Upma...yummy.jpg', calories: 280, cookTime: '15 min', description: 'A savory, spiced oats dish that is quick, filling and surprisingly delicious.' },
  { id: 'c2', title: 'Kerala Fish Curry', author: 'Arjun M.', likes: 289, mealType: 'lunch', tags: ['non-veg', 'spicy', 'coastal'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/36/Kerala_spicy_Fish_Curry.jpg/960px-Kerala_spicy_Fish_Curry.jpg', calories: 380, cookTime: '30 min', description: 'Tangy, spicy fish curry cooked in coconut milk and raw mango.' },
  { id: 'c3', title: 'Palak Paneer Paratha', author: 'Sneha K.', likes: 241, mealType: 'breakfast', tags: ['veg', 'healthy', 'filling'], imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3f/Awadhi_palak_paneer_paratha_dahi.jpg', calories: 340, cookTime: '25 min', description: 'Spinach-stuffed whole wheat flatbread with spiced paneer filling.' },
  { id: 'c4', title: 'Rajma Chawal', author: 'Vikram D.', likes: 198, mealType: 'lunch', tags: ['veg', 'comfort', 'filling'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1b/Rajma_Rice.JPG/960px-Rajma_Rice.JPG', calories: 460, cookTime: '45 min', description: 'Classic kidney bean curry served over steamed basmati rice.' },
  { id: 'c5', title: 'Peri Peri Chicken', author: 'Rohit B.', likes: 176, mealType: 'dinner', tags: ['non-veg', 'spicy', 'grilled'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/32/2018-02-03_Chicken_Piri-Piri%2C_Albufeira_%281%29.JPG/960px-2018-02-03_Chicken_Piri-Piri%2C_Albufeira_%281%29.JPG', calories: 420, cookTime: '35 min', description: 'Juicy grilled chicken marinated in homemade peri peri sauce.' },
  { id: 'c6', title: 'Dhokla', author: 'Meera G.', likes: 165, mealType: 'snack', tags: ['veg', 'light', 'fermented'], imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/65/Dhokla_on_Gujrart.jpg', calories: 180, cookTime: '25 min', description: 'Soft, spongy steamed gram flour cake from Gujarat.' },
  { id: 'c7', title: 'Mango Lassi Overnight Oats', author: 'Divya P.', likes: 154, mealType: 'breakfast', tags: ['veg', 'sweet', 'healthy'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fd/Protein_overnight_oats.jpg/960px-Protein_overnight_oats.jpg', calories: 320, cookTime: '5 min', description: 'No-cook creamy oats with mango, yoghurt and a hint of cardamom.' },
  { id: 'c8', title: 'Egg Bhurji Sandwich', author: 'Aditya R.', likes: 142, mealType: 'breakfast', tags: ['eggetarian', 'quick', 'filling'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/06/Spicy_egg_bhurji_%40_the_eggfactory.jpg/960px-Spicy_egg_bhurji_%40_the_eggfactory.jpg', calories: 360, cookTime: '10 min', description: 'Spiced scrambled eggs with onion and tomato between toasted bread.' },
  { id: 'c9', title: 'Aloo Gobi', author: 'Kavita S.', likes: 138, mealType: 'lunch', tags: ['veg', 'comfort', 'spiced'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c8/Aloo_gobi.jpg/960px-Aloo_gobi.jpg', calories: 280, cookTime: '30 min', description: 'Dry-spiced cauliflower and potato stir-fry with fresh ginger.' },
  { id: 'c10', title: 'Butter Garlic Prawns', author: 'Nikhil C.', likes: 127, mealType: 'dinner', tags: ['non-veg', 'quick', 'coastal'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f4/Prawns_in_garlic_butter_-_Taupo%2C_New_Zealand.jpg/960px-Prawns_in_garlic_butter_-_Taupo%2C_New_Zealand.jpg', calories: 350, cookTime: '15 min', description: 'Juicy prawns cooked in garlic butter with herbs and lemon.' },
  { id: 'c11', title: 'Sabudana Khichdi', author: 'Anjali T.', likes: 119, mealType: 'snack', tags: ['veg', 'light', 'gluten-free'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Sabudana_Khichdi_with_Sweet_curd.JPG/960px-Sabudana_Khichdi_with_Sweet_curd.JPG', calories: 290, cookTime: '20 min', description: 'Tapioca pearls with roasted peanuts, curry leaves and green chillies.' },
  { id: 'c12', title: 'Tomato Soup with Croutons', author: 'Rahul M.', likes: 108, mealType: 'snack', tags: ['veg', 'light', 'soothing'], imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1c/Empty_tomato_soup_dish_and_wine_glass.jpg/960px-Empty_tomato_soup_dish_and_wine_glass.jpg', calories: 160, cookTime: '20 min', description: 'Smooth, tangy tomato soup with garlic croutons and fresh cream.' },
];

export default function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).end();
  }

  const { filter } = req.query || {};
  let recipes = [...COMMUNITY_RECIPES];

  if (filter && filter !== 'All' && filter !== 'Trending') {
    if (filter === 'Veg' || filter === 'veg') {
      recipes = recipes.filter(r => r.tags.includes('veg'));
    } else {
      recipes = recipes.filter(r => r.mealType.toLowerCase() === filter.toLowerCase());
    }
  }

  return res.status(200).json(recipes);
}
