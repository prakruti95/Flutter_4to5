import 'dart:io';

void main()
{
  print("Enter value for A: ");
  var a = int.parse(stdin.readLineSync().toString());

  print("Enter value for B: ");
  var b = int.parse(stdin.readLineSync().toString());


  var add = a+b;


  print("Your Addition is $add");


}