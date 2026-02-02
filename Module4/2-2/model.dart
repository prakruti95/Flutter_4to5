import 'package:flutter/material.dart';

class Model extends StatelessWidget
{
  var list;
  Model({required this.list});


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
                subtitle:Column
                  (
                    children:
                    [
                      Text(list[index]["pprice"]) ,
                      Text(list[index]["pdes"]) ,
                    ],
                  )

              );
        }
        );
  }
}
