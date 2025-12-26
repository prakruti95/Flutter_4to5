import 'dart:math';

import 'package:flutter/material.dart';

class Randomnum extends StatefulWidget {
  const Randomnum({super.key});

  @override
  State<Randomnum> createState() => _RandomnumState();
}

class _RandomnumState extends State<Randomnum>
{
  TextEditingController numberController = TextEditingController();
  final Random random = Random();
  late int mynumber,randomnum;
  String message = "Guess a number between 1 and 10";
  @override
  void initState() {
    // TODO: implement initState
    resetGame();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        appBar: AppBar(title: Text("Random Number"),),
        body: Center
          (
              child: Column
                (
                  children:
                  [
                    TextFormField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Guess number (1 to 10)",
                        labelText: "Number",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 10),

                  ElevatedButton(
                      onPressed: ()
                    {

                      check2();



                  }, child: Text("Enter")),

                    Text(
                      message,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ],
              ),
          ) ,
      );
  }

  void resetGame()
  {
    randomnum = random.nextInt(10) + 1;
    print("Random num : $randomnum");
    setState(() {});
  }

  void check2()
  {
    mynumber = int.parse(numberController.text.toString());
    //print(mynumber);
    if (mynumber > randomnum) {
      message="Too High";
      //print("Too High");
    } else if (mynumber < randomnum) {
      //print("Too Low");
      message="Too Low";
    } else {
      // print("Correct");
      message="Correct";
    }
    setState(() {

    });
  }
}
