import 'dart:io';

void main()
{
    print("Enter Your Username");
    var uname = stdin.readLineSync().toString();

    print("Enter Your Password");
    var pass = stdin.readLineSync().toString();

    if(uname=="a@gmail.com" && pass=="1234")
    {
        print("Success");
    }
    else
    {
        print("Fail");
    }
}