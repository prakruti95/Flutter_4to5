import 'dart:io';

void main()
{
  print("Enter Your Age");
  int age = int.parse(stdin.readLineSync().toString());

  if(age>=18)
  {
    print("Eligible to vote");
      if(age>=60)
      {
        print("Senior Citizen");
      }
      else
      {
        print("Young Age");
      }

  }
  else
  {
    print("Not Eligible to vote");
  }
}