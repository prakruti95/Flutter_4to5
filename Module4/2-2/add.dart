import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddData extends StatefulWidget
{
  const AddData({super.key});

  @override
  State<AddData> createState() => _AddDataState();
}

class _AddDataState extends State<AddData>
{
  TextEditingController pname = TextEditingController();
  TextEditingController pprice = TextEditingController();
  TextEditingController pdes = TextEditingController();
  late String name,price,des;
  var _formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: Form
          (
            key: _formkey,
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center
                (
                child: Column
                  (
                  children:
                  [
                    TextFormField(controller:pname,decoration: InputDecoration(hintText: "Enter Product name",border: OutlineInputBorder()),validator:(value)
                    {
                      if(pname.text.toString().isEmpty)
                      {
                        return "Please Enter Product name";
                      }
                    },),
                    SizedBox(height: 10,),
                    TextFormField(controller:pprice,decoration: InputDecoration(hintText: "Enter Product Price",border: OutlineInputBorder()),
                      validator: (value)
                      {
                        if(pprice.text.toString().isEmpty)
                        {
                          return "Please Enter Product price";
                        }
                      },
                    ),
                    SizedBox(height: 20,),
                    TextFormField(controller:pdes,decoration: InputDecoration(hintText: "Enter Product Description",border: OutlineInputBorder()),
                      validator: (value)
                      {
                        if(pprice.text.toString().isEmpty)
                        {
                          return "Please Enter Product Description";
                        }
                      },
                    ),
                    SizedBox(height: 20,),
                    TextButton(onPressed: ()
                    {
                       name = pname.text.toString();
                       price = pprice.text.toString();
                       des = pdes.text.toString();
                      if(_formkey.currentState!.validate())
                      {
                          adddata();
                      }

                    }, child: Text("Add",style: TextStyle(fontSize: 20.00),))
                  ],
                ),
              ),
            )
        ),
      );
  }

  void adddata()async
  {
      var url = "https://prakrutitech.xyz/Seminar/insert.php";
      var resp = await http.post(Uri.parse(url),body:
      {
        "pname":name,
        "pprice":price,
        "pdes":des
      } );
      print(resp.statusCode);
      print("Executed");
  }
}
