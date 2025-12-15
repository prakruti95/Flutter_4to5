import 'package:flutter/material.dart';

void main()
{
  runApp(MaterialApp(home:FirstScreen(),debugShowCheckedModeBanner: false,));
}
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
                    print("clicked");
                  }, child: Text("Submit"))


                ],
              ),
            //child:
            //child: Text("Baldev",style:TextStyle(fontSize: 20.00,color: Colors.lightBlue,fontWeight: FontWeight.bold),),

        ),
       ); 
  }

}
