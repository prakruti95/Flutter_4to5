import 'dart:io';

void main()
{
  print("Choose Any Num");
  var num = int.parse(stdin.readLineSync().toString());

  switch(num)
  {
    case 1: print("English");
    break;

    case 2: print("Hindi");
    break;

    case 3:print("Gujarati");
    break;

    default:print("Number is not valid");
    break;
  }
}