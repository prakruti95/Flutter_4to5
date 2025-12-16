import 'package:firstapp/second.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FirstScreen extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(title: Text("Welcome to Tops Technologies"),backgroundColor:Colors.blueGrey,),
      body: Center
        (
        child: Column
          (
          children:
          [
            SizedBox(height: 20,),
            Text("Abhay",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Text("Baldev",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Text("Diya",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Text("Sweni",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Image.network("https://m.media-amazon.com/images/I/61csokWq+kL._AC_UF1000,1000_QL80_.jpg",width: 200,height: 150,),
            ElevatedButton(onPressed: ()
            {
                Fluttertoast.showToast
                  (
                    msg: "Hello From Tops",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 3,
                    gravity: ToastGravity.CENTER,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                );

                //Navigator.push(context,MaterialPageRoute(builder: (context) => SecondScreen()));
                //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => SecondScreen()));
              //print("clicked");
            }, child: Text("Submit"))


          ],
        ),
        //child:
        //child: Text("Baldev",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),

      ),
    );
  }

}
