import 'package:flutter/material.dart';
import 'package:test6/task5.dart';

class FoodMenuPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChange;

  const FoodMenuPage({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  List<Map<String, dynamic>> foodItems = [
    {"name": "Pizza", "price": 150, "qty": 0, "icon": Icons.local_pizza},
    {"name": "Burger", "price": 100, "qty": 0, "icon": Icons.fastfood},
    {"name": "Dosa", "price": 120, "qty": 0, "icon": Icons.restaurant},
    {"name": "Sandwich", "price": 80, "qty": 0, "icon": Icons.lunch_dining},
  ];

  int getTotal() {
    int total = 0;
    for (var item in foodItems) {
      total += item["price"] * item["qty"] as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Menu"),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeChange,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
              ),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item["icon"], size: 50, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        item["name"],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text("₹ ${item["price"]}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (item["qty"] > 0) item["qty"]--;
                              });
                            },
                          ),
                          Text(
                            "${item["qty"]}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                item["qty"]++;
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text("View Summary (₹ ${getTotal()})"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(foodItems),
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
