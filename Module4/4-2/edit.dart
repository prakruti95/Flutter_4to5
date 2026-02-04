import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/main.dart';

class EditData extends StatefulWidget
{
  var id,name,price,des;
  EditData({required this.id,required this.name,required this.price,required this.des});
  @override
  State<EditData> createState() => _EditDataState();
}

class _EditDataState extends State<EditData>
{
  TextEditingController pname = TextEditingController();
  TextEditingController pprice = TextEditingController();
  TextEditingController pdes = TextEditingController();
  TextEditingController id = TextEditingController();
  late String name,price,des;
  var _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState

    print("${widget.id}");
    print("${widget.name}");
    print("${widget.price}");
    print("${widget.des}");
    id.text=widget.id;
    pname.text=widget.name;
    pprice.text=widget.price;
    pdes.text=widget.des;

  }

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
                      updatedata();
                    }

                  }, child: Text("Update",style: TextStyle(fontSize: 20.00),))
                ],
              ),
            ),
          )
      ),
    );
  }

  void updatedata()async
  {
    var myid = "${widget.id}";
    var url = "https://prakrutitech.xyz/Seminar/update.php";
    var resp = await http.post(Uri.parse(url),body:
    {
      "id":myid,
      "pname":name,
      "pprice":price,
      "pdes":des
    } );
    print(resp.statusCode);
    print("Executed");
    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));

  }
}
