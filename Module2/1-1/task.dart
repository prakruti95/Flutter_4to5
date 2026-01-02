import 'package:flutter/material.dart';

class Task extends StatefulWidget
{
  const Task({super.key});

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task>
{
    List data =
    [
        "Java",
         "Php",
         "Flutter"
    ];

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text('Custom List'),),
        body: Column
          (
            children:
            [
              Container(
                height: 200.0,
                width: double.infinity,
                child: Image.asset(
                  'assets/a.png', // Replace with your image URL
                  fit: BoxFit.cover,
                ),
              ),

              Expanded(
                child: ListView.builder
                  (
                    itemCount: data.length,
                    itemBuilder: (context,index)
                    {
                      return Card
                        (
                        child: Column
                          (
                          children:
                          [
                            GestureDetector(child: Text(data[index],style: TextStyle(fontSize: 25.00),),onTap: ()
                            {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Clicked $index")));
                
                            },)
                          ],
                        ),
                      );
                    }),
              ),
            ],
          )
    );
  }
}
