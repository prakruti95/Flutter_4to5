import 'package:flutter/material.dart';


class FoodOrderPage extends StatefulWidget {
  @override
  State<FoodOrderPage> createState() => _FoodOrderPageState();
}

class _FoodOrderPageState extends State<FoodOrderPage> {
  bool pizza = false;
  bool burger = false;
  bool sandwich = false;
  bool dosa = false;

  int total = 0;

  void calculateTotal()
  {
    total = 0;
    if (pizza) total += 150;
    if (burger) total += 100;
    if (sandwich) total += 80;
    if (dosa) total += 120;
  }

  Widget foodItem({
    required String name,
    required int price,
    required bool value,
    required Function(bool?) onChanged,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        secondary: Icon(icon, color: Colors.orange, size: 30),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text("₹ $price"),
        value: value,
        activeColor: Colors.orange,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Food Ordering App"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [

            const Text(
              "Select Your Items",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            foodItem(
              name: "Pizza",
              price: 150,
              value: pizza,
              icon: Icons.local_pizza,
              onChanged: (val) {
                setState(() {
                  pizza = val!;
                  calculateTotal();
                });
              },
            ),

            foodItem(
              name: "Burger",
              price: 100,
              value: burger,
              icon: Icons.fastfood,
              onChanged: (val) {
                setState(() {
                  burger = val!;
                  calculateTotal();
                });
              },
            ),

            foodItem(
              name: "Sandwich",
              price: 80,
              value: sandwich,
              icon: Icons.lunch_dining,
              onChanged: (val) {
                setState(() {
                  sandwich = val!;
                  calculateTotal();
                });
              },
            ),

            foodItem(
              name: "Dosa",
              price: 120,
              value: dosa,
              icon: Icons.restaurant,
              onChanged: (val) {
                setState(() {
                  dosa = val!;
                  calculateTotal();
                });
              },
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Bill",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹ $total",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
