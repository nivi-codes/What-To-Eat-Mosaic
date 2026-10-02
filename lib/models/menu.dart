class MenuItem {
  final String name;
  final String description;
  final int price;
  final String diet; // vegan | vegetarian | eggetarian | non-vegetarian

  const MenuItem({required this.name, required this.description, required this.price, required this.diet});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        price: (j['price'] as num? ?? 0).toInt(),
        diet: j['diet'] as String? ?? 'non-vegetarian',
      );
}

class MenuSection {
  final String title;
  final List<MenuItem> items;

  const MenuSection({required this.title, required this.items});

  factory MenuSection.fromJson(Map<String, dynamic> j) => MenuSection(
        title: j['title'] as String,
        items: (j['items'] as List)
            .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
