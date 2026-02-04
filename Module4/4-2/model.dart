import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/edit.dart';
import 'package:jsoncrud1/main.dart';

class Model extends StatelessWidget {
  final List list;

  const Model({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(
              list[index]["pname"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Price: ${list[index]["pprice"]}"),
                Text("Description: ${list[index]["pdes"]}"),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [

                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditData(
                          id: list[index]["id"],
                          name: list[index]["pname"],
                          price: list[index]["pprice"],
                          des: list[index]["pdes"],
                        ),
                      ),
                    );
                  },
                ),


                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await deleteData(list[index]["id"]);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // DELETE API CALL
  Future<void> deleteData(String id) async {
    var url = "https://prakrutitech.xyz/Seminar/delete.php";
    await http.post(Uri.parse(url), body: {"id": id});
  }
}
