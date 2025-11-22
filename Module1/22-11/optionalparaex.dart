details(String name,String surname,[var email])
{
    print("Your name is $name");
    print("Your surname is $surname");
    print("Your email is $email");
}

void main()
{
    details("baldev","xyz","b@gmail.com");
    print("--------------");
    details("abhay", "xyz");
}