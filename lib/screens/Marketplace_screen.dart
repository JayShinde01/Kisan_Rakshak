import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String selectedCategory = "All";
  String searchText = "";
  double maxPrice = 5000;

  // UPDATED PRODUCT LIST (More Wheat Items + Descriptions)
  final List<Map<String, dynamic>> allProducts = [
    {
      "name": "Hybrid Wheat Seeds",
      "description": "High-yield seeds suitable for all soil types. Resistant to rust and disease.",
      "category": "Seeds",
      "price": 499,
      "image":
          "https://www.bombaysuperseeds.com/images/prod/wheat/BOMBAY-47.webp",
      "link": "https://www.flipkart.com",
    },
    {
      "name": "Organic Wheat Seeds",
      "description": "100% organic, chemical-free seeds for natural farming and better taste.",
      "category": "Seeds",
      "price": 650,
      "image":
          "https://m.media-amazon.com/images/I/71mPyvqRznL._SL1500_.jpg",
      "link": "https://www.amazon.in",
    },
    {
      "name": "Premium Wheat Booster Fertilizer",
      "description":
          "Boosts plant growth and root development. Improves wheat grain size.",
      "category": "Fertilizer",
      "price": 899,
      "image":
          "https://m.media-amazon.com/images/I/71x8YgnSUOL._SL1500_.jpg",
      "link": "https://www.flipkart.com",
    },
    {
      "name": "Nitrogen Fertilizer for Wheat",
      "description":
          "Ideal nitrogen-rich fertilizer for green leaf growth and higher output.",
      "category": "Fertilizer",
      "price": 599,
      "image":
          "https://m.media-amazon.com/images/I/61xovHGaSML._SL1000_.jpg",
      "link": "https://www.amazon.in",
    },
    {
      "name": "Wheat Rust Pesticide",
      "description":
          "Controls wheat rust, pests, and fungal diseases. Quick action formula.",
      "category": "Medicine",
      "price": 1299,
      "image":
          "https://m.media-amazon.com/images/I/61z9YuqbWPL._SL1500_.jpg",
      "link": "https://www.flipkart.com",
    },
    {
      "name": "Wheat Fungicide",
      "description":
          "Protects wheat crops against fungus, root rot, and soil infections.",
      "category": "Medicine",
      "price": 999,
      "image":
          "https://m.media-amazon.com/images/I/61nGNiApm-L._SL1500_.jpg",
      "link": "https://www.amazon.in",
    },
    {
      "name": "Wheat Growth Enhancer",
      "description":
          "Improves tillering, shoot strength, and grain maturity for high yield.",
      "category": "Booster",
      "price": 799,
      "image":
          "https://m.media-amazon.com/images/I/61sX6NlaCLL._SL1100_.jpg",
      "link": "https://www.amazon.in",
    },
    {
      "name": "Soil Nutrient Mix for Wheat",
      "description":
          "Balanced micronutrients for healthier soil, stronger wheat roots.",
      "category": "Fertilizer",
      "price": 699,
      "image":
          "https://m.media-amazon.com/images/I/71tPogRyhok._SL1500_.jpg",
      "link": "https://www.flipkart.com",
    }
  ];

  // FILTER LOGIC
  List<Map<String, dynamic>> get filteredProducts {
    return allProducts.where((product) {
      final matchCategory =
          selectedCategory == "All" || product["category"] == selectedCategory;

      final matchSearch =
          product["name"].toLowerCase().contains(searchText.toLowerCase());

      final matchPrice = product["price"] <= maxPrice;

      return matchCategory && matchSearch && matchPrice;
    }).toList();
  }

  Future<void> openBuyLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search wheat seeds, fertilizer, medicine...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All")),
                      DropdownMenuItem(value: "Seeds", child: Text("Seeds")),
                      DropdownMenuItem(
                          value: "Fertilizer", child: Text("Fertilizer")),
                      DropdownMenuItem(
                          value: "Medicine", child: Text("Medicine")),
                      DropdownMenuItem(
                          value: "Booster", child: Text("Booster")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final item = filteredProducts[index];

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: Image.network(
                            item["image"],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              item["name"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Description (2-3 lines)
                            Text(
                              item["description"],
                              style: const TextStyle(fontSize: 11),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "₹${item["price"]}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 5),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  openBuyLink(item["link"]);
                                },
                                child: const Text("Buy Now"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
