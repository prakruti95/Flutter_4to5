import 'dart:io';

void main()
{
    print("Enter Your Age");
    int age = int.parse(stdin.readLineSync().toString());

    if(age>=18)
    {
        print("Eligible to vote");
    }
    else
    {
      print("Not Eligible to vote");
    }
}