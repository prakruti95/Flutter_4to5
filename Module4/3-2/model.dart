import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/edit.dart';
import 'package:jsoncrud1/main.dart';
class Model extends StatelessWidget
{
  var list;
  Model({required this.list});

  var id;
  @override
  Widget build(BuildContext context)
  {
    return ListView.builder
      (
        itemCount: list.length,
        itemBuilder:(context,index)
        {
            return ListTile
              (
                title:Text(list[index]["pname"]),
                subtitle:Column(
                  children: [
                    Text(list[index]["pprice"]),
                    Text(list[index]["pdes"]),
                  ],
                ),
                trailing: Wrap
                  (
                    children:
                    [
                      IconButton(onPressed: ()
                      {
                        var id1= list[index]["id"];
                        var name1 = list[index]["pname"];
                        var price1 = list[index]["pprice"];
                        var des1 = list[index]["pdes"];
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => EditData(id:id1,name:name1,price:price1,des:des1)));

                      }, icon: Icon(Icons.edit)),
                      IconButton(onPressed: ()
                      {
                        id = list[index]["id"];
                        deletedata();
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));
                      }, icon: Icon(Icons.delete)),
                    ],
                  ),

              );
        }
        );
  }

  deletedata()async
  {
    var url = "https://prakrutitech.xyz/Seminar/delete.php";
    var resp = await http.post(Uri.parse(url),body:
    {
      "id":id
    });
    print(resp.statusCode);

  }
}
